// Mục đang xem nằm trên URL (#muc/boloc): Back/Forward, F5 và gửi link đều mở đúng mục
export function readRoute(hash = window.location.hash) {
  const [key = '', filter = ''] = hash.replace(/^#/, '').split('/');
  try {
    return { key, filter: decodeURIComponent(filter) };
  } catch {
    return { key, filter: '' };
  }
}

export function routeHash(key: string, filter = '') {
  return key + (filter ? '/' + encodeURIComponent(filter) : '');
}

/** Bộ lọc trên URL có thể bị gõ tay: chỉ dùng khi nằm trong danh sách, không thì về mặc định */
export const pickFilter = (filter: string, allowed: readonly string[], fallback = '') =>
  allowed.includes(filter) ? filter : fallback;
