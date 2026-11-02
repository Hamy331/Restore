/**
 * Chặn mọi request tới Resend: không gửi email thật, lưu lại nội dung
 * để test đọc được mã OTP.
 */
export const outbox: { to: string[]; subject: string; html: string }[] = [];

const realFetch = globalThis.fetch;
globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
  const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
  if (url.includes('api.resend.com')) {
    outbox.push(JSON.parse(String(init?.body ?? '{}')));
    return new Response(JSON.stringify({ id: 'email-test' }), { status: 200, headers: { 'content-type': 'application/json' } });
  }
  return realFetch(input, init);
}) as typeof fetch;

/** Mã OTP 6 số trong email gần nhất gửi tới [to] */
export function lastOtp(to: string) {
  const mail = [...outbox].reverse().find((item) => item.to.includes(to));
  const match = mail?.html.match(/>(\d{6})</);
  if (!match) throw new Error(`Không có email OTP cho ${to}`);
  return match[1]!;
}
