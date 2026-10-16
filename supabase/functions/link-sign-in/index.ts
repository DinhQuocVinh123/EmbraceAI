import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';
import { parseLink, sameSecret } from '../_shared/sign_in_link.ts';

// Đổi một link đăng nhập cố định thành một mã đăng nhập một lần của
// Supabase. App xác thực mã đó y như link một lần cũ (verifyOTP), nên phần
// đăng nhập phía sau không đổi. Gọi được khi chưa đăng nhập (verify_jwt =
// false): mã bí mật 256 bit chính là thứ xác thực.

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Mọi lý do từ chối trả về cùng một câu, để không ai dò được mã người tham
// gia nào có link.
const refused = () => json(403, { error: 'This sign-in link no longer works' });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) return json(500, { error: 'Not configured' });
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const link = parseLink(body.link);
  if (!link) return refused();

  const { data: row } = await admin
    .from('participant_sign_in_links')
    .select('secret')
    .eq('participant_code', link.code)
    .maybeSingle();
  if (!row || !sameSecret(link.secret, row.secret)) {
    return refused();
  }

  const { data: participant } = await admin
    .from('participants')
    .select('auth_user_id, status, expires_at')
    .eq('participant_code', link.code)
    .maybeSingle();
  if (
    !participant || !['invited', 'active'].includes(participant.status) ||
    new Date(participant.expires_at).getTime() <= Date.now()
  ) {
    return refused();
  }

  const { data: userData } = await admin.auth.admin.getUserById(participant.auth_user_id);
  const email = userData.user?.email;
  if (!email) return refused();

  const { data: linkData, error: linkError } = await admin.auth.admin.generateLink({
    type: 'magiclink',
    email,
  });
  const tokenHash = linkData?.properties?.hashed_token;
  if (linkError || !tokenHash) {
    return json(500, { error: 'Could not sign in right now' });
  }

  await admin
    .from('participant_sign_in_links')
    .update({ last_used_at: new Date().toISOString() })
    .eq('participant_code', link.code);

  return json(200, { tokenHash });
});
