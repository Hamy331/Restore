const base = (import.meta.env.VITE_API_BASE_URL || '/api/v1').replace(/\/$/, '');
export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly code?: string,
  ) {
    super(message);
  }
}

async function request<T>(
  path: string,
  token?: string,
  body?: unknown,
  method = body === undefined ? 'GET' : 'POST',
  mediaType?: string,
): Promise<T> {
  const headers = new Headers({ Accept: 'application/json' });
  if (token) headers.set('Authorization', 'Bearer ' + token);
  if (body !== undefined) headers.set('Content-Type', mediaType ?? 'application/json');
  // Refresh token nằm trong cookie httpOnly do backend đặt; header này bật chế độ cookie
  headers.set('X-Session-Cookie', '1');
  const response = await fetch(base + path, {
    method,
    headers,
    body: mediaType ? (body as Blob) : body === undefined ? undefined : JSON.stringify(body),
    cache: 'no-store',
    credentials: 'include',
  });
  if (response.status === 204) return undefined as T;
  const result = await response.json().catch(() => null);
  if (!response.ok || !result?.success) {
    throw new ApiError(response.status, result?.error || 'Không thể lấy dữ liệu từ máy chủ.', result?.code);
  }
  return result.data as T;
}

type Tokens = { accessToken: string };
export type Admin = { fullName: string; email: string; permissions: string[] };
export const errorText = (err: unknown) =>
  err instanceof Error ? err.message : 'Không thể kết nối.';

// Access token (sống 15 phút) giữ trong sessionStorage để tải lại trang khỏi phải refresh
// (refresh ghi DB, mất 1-2 giây). Không lộ thêm gì: mã độc chạy được trên trang vốn đã gọi
// được /auth/refresh kèm cookie. Refresh token (60 ngày) vẫn chỉ nằm trong cookie httpOnly.
const accessKey = 'restore-admin-access';
function remember(accessToken?: string) {
  try {
    if (accessToken) sessionStorage.setItem(accessKey, accessToken);
    else sessionStorage.removeItem(accessKey);
  } catch {
    // Trình duyệt chặn storage: tải lại trang sẽ refresh bằng cookie
  }
}
function remembered() {
  try {
    return sessionStorage.getItem(accessKey) ?? undefined;
  } catch {
    return undefined;
  }
}

// Hai tab cùng refresh bằng một cookie: tab chậm hơn bị coi là dùng lại token cũ.
// Lúc đó cookie đã được tab kia đổi sang token mới nên thử lại một lần.
async function refreshTokens() {
  try {
    return await request<Tokens>('/auth/refresh', undefined, {});
  } catch (err) {
    if (!(err instanceof ApiError) || err.code !== 'REFRESH_TOKEN_REUSED') throw err;
    return request<Tokens>('/auth/refresh', undefined, {});
  }
}

export class Session {
  private refresh?: Promise<void>;
  private closed = false;
  private constructor(
    private tokens: Tokens,
    private expired: () => void,
  ) {}
  static async login(email: string, password: string, expired: () => void) {
    const tokens = await request<Tokens>('/auth/login', undefined, { email, password });
    const session = new Session(tokens, expired);
    try {
      const admin = await session.admin();
      remember(tokens.accessToken);
      return { session, admin };
    } catch (err) {
      await session.logout().catch(() => undefined);
      throw err;
    }
  }
  /**
   * Mở lại phiên khi tải lại trang hoặc mở tab mới: dùng access token còn lưu, không có hoặc
   * hết hạn thì refresh bằng cookie. Hết phiên thì trả undefined (về form đăng nhập, không báo lỗi);
   * lỗi mạng giữ cookie để thử lại; không còn quyền admin thì đăng xuất.
   */
  static async restore(expired: () => void) {
    let restoring = true;
    let tokens: Tokens;
    const saved = remembered();
    if (saved) tokens = { accessToken: saved };
    else {
      try {
        tokens = await refreshTokens();
      } catch (err) {
        if (err instanceof ApiError && [401, 403].includes(err.status)) return undefined;
        throw err;
      }
    }
    // Đang mở lại phiên thì hết hạn chỉ là chưa đăng nhập, chưa cần báo "phiên đã hết hạn"
    const session = new Session(tokens, () => restoring || expired());
    try {
      const admin = await session.admin();
      remember(session.tokens.accessToken);
      return { session, admin };
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        remember();
        return undefined;
      }
      const offline = err instanceof TypeError || (err instanceof ApiError && err.status >= 500);
      if (!offline) await session.logout().catch(() => undefined);
      throw err;
    } finally {
      restoring = false;
    }
  }
  private async admin() {
    const admin = await this.call<Admin>('/admin/me');
    if (!admin.permissions?.includes('admin:access'))
      throw new Error('Tài khoản chưa được cấp quyền quản trị web.');
    return admin;
  }
  async call<T>(path: string, body?: unknown): Promise<T> {
    return this.authorized((token) => request<T>(path, token, body));
  }
  async put<T>(path: string, body: unknown): Promise<T> {
    return this.authorized((token) => request<T>(path, token, body, 'PUT'));
  }
  async listingImage(filename: string): Promise<Blob> {
    return this.mediaImage('/listings/media/', filename);
  }
  async coverImage(filename: string): Promise<Blob> {
    return this.mediaImage('/content/media/', filename);
  }
  async feedImage(filename: string): Promise<Blob> {
    return this.mediaImage('/media/feeds/', filename);
  }
  async posterImage(filename: string): Promise<Blob> {
    return this.mediaImage('/media/posters/', filename);
  }
  async shopImage(filename: string): Promise<Blob> {
    return this.mediaImage('/media/shops/', filename);
  }
  async upload<T>(path: string, file: Blob, mediaType: string): Promise<T> {
    return this.authorized((token) => request<T>(path, token, file, 'POST', mediaType));
  }
  async remove(path: string, updatedAt: string) {
    return this.authorized((token) => request(path, token, { updatedAt }, 'DELETE'));
  }
  async delete(path: string) {
    return this.authorized((token) => request<void>(path, token, undefined, 'DELETE'));
  }
  private async mediaImage(prefix: string, filename: string): Promise<Blob> {
    return this.authorized(async (token) => {
      const response = await fetch(base + prefix + encodeURIComponent(filename), {
        headers: { Authorization: 'Bearer ' + token },
        cache: 'no-store',
        redirect: 'error',
      });
      if (!response.ok) throw new ApiError(response.status, 'Không tải được ảnh tin đăng.');
      return response.blob();
    });
  }
  private async authorized<T>(run: (token: string) => Promise<T>): Promise<T> {
    if (this.closed) throw new Error('Phiên đăng nhập đã kết thúc.');
    const access = this.tokens.accessToken;
    try {
      return await run(access);
    } catch (err) {
      if (!(err instanceof ApiError) || err.status !== 401 || this.closed) throw err;
      if (access === this.tokens.accessToken) {
        this.refresh ??= refreshTokens()
          .then((tokens) => {
            this.tokens = tokens;
            if (!this.closed) remember(tokens.accessToken);
          })
          .catch((e) => {
            if (e instanceof ApiError && [401, 403].includes(e.status)) {
              this.closed = true;
              remember();
              this.expired();
            }
            throw e;
          })
          .finally(() => {
            this.refresh = undefined;
          });
        await this.refresh;
      }
      if (this.closed) throw new Error('Phiên đăng nhập đã kết thúc.');
      return run(this.tokens.accessToken);
    }
  }
  async logout() {
    this.closed = true;
    remember();
    await this.refresh?.catch(() => undefined);
    await request('/auth/logout', undefined, {}); // Backend thu hồi phiên và xoá cookie
  }
}
