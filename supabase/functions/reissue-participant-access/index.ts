import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

function randomBlock(length: number): string {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(bytes, (value) => alphabet[value % alphabet.length]).join('');
}

function displayKey(key: string): string {
  return key.match(/.{1,4}/g)?.join('-') ?? key;
}

function displayCode(code: string): string {
  return `${code.slice(0, 2)}-${code.slice(2, 6)}-${code.slice(6)}`;
}

function participantRedirect(publicAppUrl: string, code: string): string {
  const redirect = new URL(publicAppUrl);
  redirect.searchParams.set('participant', displayCode(code));
  redirect.searchParams.set('access', 'qr');
  return redirect.toString();
}

// Link gửi cho người tham gia nằm trên chính tên miền của app, không phải
// link xác thực thô của Supabase (tên miền lạ, chuỗi chuyển hướng mã hoá).
// App đọc `signin` và tự xác thực mã với Supabase khi được mở.
function appSignInUrl(publicAppUrl: string, tokenHash: string): string {
  const url = new URL(publicAppUrl);
  url.searchParams.set('signin', tokenHash);
  return url.toString();
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
    return json(403, { error: 'This staff account cannot issue access links' });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const code = String(body.participantCode ?? '')
    .replace(/[^a-z0-9]/gi, '')
    .toUpperCase();
  if (!/^EA[A-Z0-9]{8}$/.test(code)) {
    return json(400, { error: 'Invalid Participant ID' });
  }

  const { data: participant, error: participantError } = await admin
    .from('participants')
    .select('auth_user_id, status, expires_at')
    .eq('participant_code', code)
    .maybeSingle();
  if (participantError || !participant) {
    return json(404, { error: 'Participant not found' });
  }
  if (!['invited', 'active'].includes(participant.status)) {
    return json(409, { error: 'Participant account is not active' });
  }
  if (new Date(participant.expires_at).getTime() <= Date.now()) {
    return json(409, { error: 'Participant account has expired' });
  }

  const { data: userData, error: userError } =
    await admin.auth.admin.getUserById(participant.auth_user_id);
  const email = userData.user?.email;
  if (userError || !email) {
    return json(500, { error: 'Participant access could not be loaded' });
  }

  // Access key chỉ được lưu dạng băm nên không lấy lại được key cũ. Cấp lại
  // quyền truy cập vì thế luôn kèm một key mới; key cũ hết hiệu lực ngay, còn
  // các thiết bị đang đăng nhập vẫn giữ phiên.
  const accessKey = randomBlock(16);
  const { error: keyError } = await admin.auth.admin.updateUserById(
    participant.auth_user_id,
    { password: accessKey },
  );
  if (keyError) {
    return json(500, { error: 'Could not issue a new access key' });
  }

  const { data: linkData, error: linkError } =
    await admin.auth.admin.generateLink({
      type: 'magiclink',
      email,
      options: { redirectTo: participantRedirect(publicAppUrl, code) },
    });
  const tokenHash = linkData?.properties?.hashed_token;
  const loginUrl = tokenHash ? appSignInUrl(publicAppUrl, tokenHash) : null;
  if (linkError || !loginUrl) {
    return json(500, { error: 'Could not create QR access' });
  }

  await admin.from('audit_logs').insert({
    actor_user_id: authData.user.id,
    action: 'participant.access_link_issued',
    participant_code: code,
    detail: { access_key_reset: true },
  });

  return json(200, {
    participantCode: displayCode(code),
    accessKey: displayKey(accessKey),
    loginUrl,
    expiresAt: participant.expires_at,
  });
});
