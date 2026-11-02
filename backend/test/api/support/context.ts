import './env.js';
import './email-outbox.js';
import { after, before } from 'node:test';
import { ApiClient, ApiResponse } from './api-client.js';
import { PASSWORD, resetDatabase, seedFixtures } from './database.js';
import { SnapshotBook } from './snapshot.js';

export type Tokens = { buyer: string; seller: string; admin: string };

/**
 * Chuẩn bị cho một file contract test:
 * xóa database thử, nạp dữ liệu cố định, chạy app, đăng nhập sẵn 3 tài khoản.
 * Mỗi lần gọi `expect` ghi status + body vào snapshot của file đó.
 */
export function useApi(name: string) {
  const ctx = { api: undefined as unknown as ApiClient, tokens: {} as Tokens, book: new SnapshotBook(name) };

  before(async () => {
    resetDatabase();
    await seedFixtures();
    ctx.api = await ApiClient.start();
    const login = async (id: string) => {
      const res = await ctx.api.post('/auth/login', { body: { email: `${id}@restore.test`, password: PASSWORD } });
      if (res.status !== 200) throw new Error(`Đăng nhập ${id} thất bại: ${JSON.stringify(res.body)}`);
      return res.body.data.accessToken as string;
    };
    ctx.tokens = { buyer: await login('user-buyer'), seller: await login('user-seller'), admin: await login('user-admin') };
  });

  after(async () => {
    ctx.book.save();
    await ctx.api?.stop();
  });

  /** Ghi phản hồi vào snapshot và trả lại để bước sau dùng tiếp */
  const expect = (step: string, res: ApiResponse) => {
    ctx.book.check(step, { status: res.status, body: res.body });
    return res;
  };

  return { ctx, expect };
}
