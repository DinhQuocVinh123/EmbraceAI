// Chạy: npx deno test supabase/functions/_shared/sign_in_link_test.ts
import { linkUrl, newSecret, parseLink, sameSecret } from './sign_in_link.ts';

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test('a new secret is 43 url-safe characters and never repeats', () => {
  const secrets = new Set(Array.from({ length: 100 }, newSecret));
  assert(secrets.size === 100, 'secrets repeat');
  for (const secret of secrets) {
    assert(/^[A-Za-z0-9_-]{43}$/.test(secret), `bad secret ${secret}`);
  }
});

Deno.test('the link the staff copy is the link the app accepts', () => {
  const secret = newSecret();
  const url = new URL(linkUrl('https://embrace-ai-prototype-2026.web.app', 'EA23AB89XY', secret));
  const parsed = parseLink(url.searchParams.get('link'));
  assert(parsed?.code === 'EA23AB89XY' && parsed.secret === secret, 'round trip failed');
  assert(sameSecret(parsed!.secret, secret), 'same secret should match');
  assert(!sameSecret(newSecret(), secret), 'other secret should not match');
  assert(!sameSecret(secret.slice(1), secret), 'shorter secret should not match');
});

Deno.test('malformed links are refused before any lookup', () => {
  const secret = newSecret();
  for (const value of ['', 'EA23AB89XY', `ea23ab89xy.${secret}`, `EA23AB89XY.${secret}.x`, `EA23AB89XY.short`, null]) {
    assert(parseLink(value) === null, `accepted ${value}`);
  }
});
