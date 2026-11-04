import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';

export type ApiResponse = { status: number; body: any; headers: Headers };
type RequestOptions = { token?: string; body?: unknown; raw?: Buffer | string; contentType?: string; headers?: Record<string, string> };

/** Chạy app thật trên cổng ngẫu nhiên và gọi API qua HTTP. */
export class ApiClient {
  private constructor(private readonly server: Server, private readonly baseUrl: string) {}

  static async start() {
    const { createApp } = await import('../../../src/app.js');
    const server = createApp().listen(0);
    await new Promise((resolve) => server.once('listening', resolve));
    const { port } = server.address() as AddressInfo;
    return new ApiClient(server, `http://127.0.0.1:${port}/api/v1`);
  }

  async request(method: string, path: string, options: RequestOptions = {}): Promise<ApiResponse> {
    const headers: Record<string, string> = { Accept: 'application/json', ...options.headers };
    if (options.token) headers.Authorization = `Bearer ${options.token}`;
    let body: BodyInit | undefined;
    if (options.raw !== undefined) {
      body = options.raw as BodyInit;
      headers['Content-Type'] = options.contentType ?? 'application/octet-stream';
    } else if (options.body !== undefined) {
      body = JSON.stringify(options.body);
      headers['Content-Type'] = options.contentType ?? 'application/json';
    }
    const response = await fetch(this.baseUrl + path, { method, headers, body });
    const text = await response.text();
    let parsed: unknown = text;
    try { parsed = text ? JSON.parse(text) : null; } catch { /* ảnh hoặc text */ }
    return { status: response.status, body: parsed, headers: response.headers };
  }

  get = (path: string, options?: RequestOptions) => this.request('GET', path, options);
  post = (path: string, options?: RequestOptions) => this.request('POST', path, options);
  put = (path: string, options?: RequestOptions) => this.request('PUT', path, options);
  patch = (path: string, options?: RequestOptions) => this.request('PATCH', path, options);
  delete = (path: string, options?: RequestOptions) => this.request('DELETE', path, options);

  async stop() {
    await new Promise((resolve) => this.server.close(resolve));
    const { prisma } = await import('../../../src/lib/prisma.js');
    await prisma.$disconnect();
  }
}
