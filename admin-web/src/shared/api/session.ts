const base = (import.meta.env.VITE_API_BASE_URL || '/api/v1').replace(/\/$/, '');
export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
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
  const response = await fetch(base + path, {
    method,
    headers,
    body: mediaType ? (body as Blob) : body === undefined ? undefined : JSON.stringify(body),
    cache: 'no-store',
  });
  if (response.status === 204) return undefined as T;
  const result = await response.json().catch(() => null);
  if (!response.ok || !result?.success) {
    throw new ApiError(response.status, result?.error || 'Không thể lấy dữ liệu từ máy chủ.');
  }
  return result.data as T;
}

type Tokens = { accessToken: string; refreshToken: string };
export type Admin = { fullName: string; email: string; permissions: string[] };
export const errorText = (err: unknown) =>
  err instanceof Error ? err.message : 'Không thể kết nối.';

// sessionStorage: tải lại trang vẫn giữ phiên, đóng tab là mất
const storageKey = 'restore-admin-session';
function store(tokens?: Tokens) {
  try {
    if (tokens) sessionStorage.setItem(storageKey, JSON.stringify(tokens));
    else sessionStorage.removeItem(storageKey);
  } catch {
    // Trình duyệt chặn storage: phiên chỉ sống trong bộ nhớ như trước
  }
}
function stored(): Tokens | undefined {
  try {
    const tokens = JSON.parse(sessionStorage.getItem(storageKey) ?? 'null');
    return tokens?.accessToken && tokens?.refreshToken ? tokens : undefined;
  } catch {
    return undefined;
  }
}

export class Session {
  private refresh?: Promise<void>;
  private closed = false;
  private constructor(
    private tokens: Tokens,
    private expired: () => void,
  ) {}
  static hasStored() {
    return !!stored();
  }
  static async login(email: string, password: string, expired: () => void) {
    const tokens = await request<Tokens>('/auth/login', undefined, { email, password });
    const session = new Session(tokens, expired);
    try {
      const admin = await session.admin();
      store(session.tokens);
      return { session, admin };
    } catch (err) {
      await session.logout().catch(() => undefined);
      throw err;
    }
  }
  /** Mở lại phiên đã lưu trong tab. Lỗi mạng giữ token để thử lại, token hết hạn thì xoá. */
  static async restore(expired: () => void) {
    const tokens = stored();
    if (!tokens) return undefined;
    const session = new Session(tokens, expired);
    try {
      return { session, admin: await session.admin() };
    } catch (err) {
      const offline = err instanceof TypeError || (err instanceof ApiError && err.status >= 500);
      if (!offline) await session.logout().catch(() => undefined);
      throw err;
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
        this.refresh ??= request<Tokens>('/auth/refresh', undefined, {
          refreshToken: this.tokens.refreshToken,
        })
          .then((tokens) => {
            this.tokens = tokens;
            if (!this.closed) store(tokens);
          })
          .catch((e) => {
            if (e instanceof ApiError && [401, 403].includes(e.status)) {
              this.closed = true;
              store();
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
    store();
    await this.refresh?.catch(() => undefined);
    await request('/auth/logout', undefined, { refreshToken: this.tokens.refreshToken });
  }
}
