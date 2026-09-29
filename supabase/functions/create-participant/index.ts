import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function randomBlock(length: number): string {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(bytes, (value) => alphabet[value % alphabet.length]).join('');
}

function displayCode(code: string): string {
  return `${code.slice(0, 2)}-${code.slice(2, 6)}-${code.slice(6)}`;
}

function displayKey(key: string): string {
  return key.match(/.{1,4}/g)?.join('-') ?? key;
}

function participantRedirect(publicAppUrl: string, code: string): string {
  const redirect = new URL(publicAppUrl);
  redirect.searchParams.set('participant', displayCode(code));
  redirect.searchParams.set('access', 'qr');
  return redirect.toString();
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const publicAppUrl = Deno.env.get('PUBLIC_APP_URL') ??
    'https://embrace-ai-prototype-2026.web.app';
  const authorization = request.headers.get('Authorization');
  if (!supabaseUrl || !serviceRoleKey || !authorization) {
    return json(401, { error: 'Staff sign-in is required' });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const token = authorization.replace(/^Bearer\s+/i, '');
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  if (authError || !authData.user) {
    return json(401, { error: 'Staff sign-in is required' });
  }

  const { data: staff } = await admin
    .from('staff_profiles')
    .select('role, active')
    .eq('user_id', authData.user.id)
    .maybeSingle();
  if (!staff?.active || !['admin', 'coordinator'].includes(staff.role)) {
    return json(403, { error: 'This staff account cannot create participants' });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const studyId = String(body.studyId ?? '').trim();
  const group = String(body.group ?? 'Unassigned').trim() || 'Unassigned';
  const validForDays = Number(body.validForDays ?? 90);
  if (
    !studyId || studyId.length > 80 || group.length > 80 ||
    !Number.isInteger(validForDays) || validForDays < 1 || validForDays > 365
  ) {
    return json(400, { error: 'The participant setup is invalid' });
  }

  let code: string | null = null;
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const candidate = `EA${randomBlock(8)}`;
    const { data } = await admin
      .from('participants')
      .select('id')
      .eq('participant_code', candidate)
      .maybeSingle();
    if (!data) {
      code = candidate;
      break;
    }
  }
  if (!code) return json(503, { error: 'Could not allocate a Participant ID' });

  const accessKey = randomBlock(16);
  const email = `${code.toLowerCase()}@participant.embrace.invalid`;
  const expiresAt = new Date(
    Date.now() + validForDays * 24 * 60 * 60 * 1000,
  ).toISOString();
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password: accessKey,
    email_confirm: true,
    user_metadata: { account_type: 'participant' },
  });
  if (createError || !created.user) {
    return json(500, { error: 'Could not create participant access' });
  }

  const { error: insertError } = await admin.from('participants').insert({
    participant_code: code,
    auth_user_id: created.user.id,
    study_id: studyId,
    group_name: group,
    expires_at: expiresAt,
  });
  if (insertError) {
    await admin.auth.admin.deleteUser(created.user.id);
    return json(500, { error: 'Could not save participant access' });
  }

  const { data: linkData, error: linkError } =
    await admin.auth.admin.generateLink({
      type: 'magiclink',
      email,
      options: { redirectTo: participantRedirect(publicAppUrl, code) },
    });
  const loginUrl = linkData?.properties?.action_link;
  if (linkError || !loginUrl) {
    await admin.auth.admin.deleteUser(created.user.id);
    return json(500, { error: 'Could not create QR access' });
  }

  await admin.from('audit_logs').insert({
    actor_user_id: authData.user.id,
    action: 'participant.created',
    participant_code: code,
  });

  return json(200, {
    participantCode: displayCode(code),
    accessKey: displayKey(accessKey),
    loginUrl,
    expiresAt,
  });
});
