/** Best-effort redaction before persistence, provider calls and application logs. */
export function redact(text: string): string {
  let safe = text;
  for (const name of ['GEMINI_API_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'JWT_SECRET', 'JWT_REFRESH_SECRET', 'DATABASE_URL', 'DIRECT_URL']) {
    const secret = process.env[name];
    if (secret && secret.length >= 8) safe = safe.split(secret).join('[REDACTED]');
  }
  // Cloudinary: cả CLOUDINARY_URL lẫn riêng phần api_secret trong đó
  const cloudinaryUrl = process.env.CLOUDINARY_URL;
  for (const secret of [cloudinaryUrl, cloudinaryUrl?.match(/^cloudinary:\/\/[^:]+:([^@]+)@/)?.[1]]) {
    if (secret && secret.length >= 8) safe = safe.split(secret).join('[REDACTED]');
  }
  return safe
    .replace(/\bBearer\s+[A-Za-z0-9._~+/=-]+/gi, 'Bearer [REDACTED]')
    .replace(/\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g, '[REDACTED]')
    .replace(/\b(?:AIza[\w-]{20,}|sb_(?:secret|publishable)_[\w-]+|sk-[\w-]{16,})\b/g, '[REDACTED]')
    .replace(/((?:password|mat khau|mật khẩu|otp|api[_ -]?key|api[_ -]?secret|khóa api|khoa api|access[_ -]?token|refresh[_ -]?token|token|cccd|cmnd|so tai khoan|số tài khoản)["']?\s*(?::|=|\bis\b|\blà\b|\bla\b)\s*["']?)[^\s"',;]+/gi, '$1[REDACTED]')
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, '[EMAIL]')
    .replace(/(?<![\p{L}\p{N}_-])(?:\+84|0)[ .-]?[35789](?:[ .-]?\d){8}(?![\p{L}\p{N}_-])/gu, '[PHONE]');
}

export function redactValue<T>(value: T): T {
  if (typeof value === 'string') return redact(value) as T;
  if (Array.isArray(value)) return value.map(redactValue) as T;
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k,
    /^(password|secret|token|api[_-]?key|api[_-]?secret|access[_-]?token|refresh[_-]?token|authorization|otp|cccd|cmnd)$/i.test(k) ? '[REDACTED]' : redactValue(v)])) as T;
  return value;
}
