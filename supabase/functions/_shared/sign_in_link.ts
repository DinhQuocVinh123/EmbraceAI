// Link đăng nhập cố định: `<app>/?link=<mã người tham gia>.<mã bí mật>`.
// Mã bí mật là 32 byte ngẫu nhiên (base64url, 43 ký tự), tạo một lần cho mỗi
// người tham gia và giữ nguyên tới khi nhân viên đặt lại. Dùng chung cho hàm
// lấy link và hàm đăng nhập bằng link.

const codePattern = /^EA[A-Z0-9]{8}$/;
const secretPattern = /^[A-Za-z0-9_-]{43}$/;

export function newSecret(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/** So hai mã mà không dừng sớm ở ký tự khác đầu tiên. */
export function sameSecret(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

/** Tách `EA1234ABCD.<mã>`; trả null nếu sai khuôn. */
export function parseLink(value: unknown): { code: string; secret: string } | null {
  const [code, secret, ...rest] = String(value ?? '').trim().split('.');
  if (rest.length || !codePattern.test(code ?? '') || !secretPattern.test(secret ?? '')) {
    return null;
  }
  return { code, secret };
}

export function linkUrl(publicAppUrl: string, code: string, secret: string): string {
  const url = new URL(publicAppUrl);
  url.searchParams.set('link', `${code}.${secret}`);
  return url.toString();
}
