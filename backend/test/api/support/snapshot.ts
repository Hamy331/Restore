import assert from 'node:assert/strict';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

const UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g;
const ISO_DATE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/;
const VOLATILE_KEYS = new Set(['accessToken', 'refreshToken', 'resetToken', 'token']);
const FIXED_DATE = /^20(26-10-01|99-01-01)/;

/**
 * Bỏ các giá trị thay đổi mỗi lần chạy (uuid, thời gian hiện tại, token)
 * để so sánh được cấu trúc và dữ liệu ổn định.
 */
export function normalize(value: unknown, key = ''): unknown {
  if (Array.isArray(value)) return value.map((item) => normalize(item));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, normalize(v, k)]));
  }
  if (typeof value === 'string') {
    if (VOLATILE_KEYS.has(key)) return '<token>';
    if (ISO_DATE.test(value)) return FIXED_DATE.test(value) ? value : '<date>';
    return value.replace(UUID, '<uuid>');
  }
  return value;
}

/** So sánh các bước của một file test với file snapshot; UPDATE_SNAPSHOTS=1 để ghi lại. */
export class SnapshotBook {
  private readonly file: string;
  private readonly expected: Record<string, unknown>;
  private readonly actual: Record<string, unknown> = {};

  constructor(name: string) {
    const dir = path.join(import.meta.dirname, '..', '__snapshots__');
    mkdirSync(dir, { recursive: true });
    this.file = path.join(dir, `${name}.json`);
    this.expected = existsSync(this.file) ? JSON.parse(readFileSync(this.file, 'utf8')) : {};
  }

  check(step: string, value: unknown) {
    if (step in this.actual) throw new Error(`Trùng tên bước snapshot: ${step}`);
    const normalized = normalize(value);
    this.actual[step] = normalized;
    if (process.env.UPDATE_SNAPSHOTS === '1' || !(step in this.expected)) return;
    assert.deepEqual(normalized, this.expected[step], `Phản hồi của bước "${step}" khác snapshot`);
  }

  /** Ghi file khi chạy lần đầu hoặc UPDATE_SNAPSHOTS=1; báo lỗi nếu snapshot có bước không còn chạy. */
  save() {
    const update = process.env.UPDATE_SNAPSHOTS === '1' || Object.keys(this.expected).length === 0;
    if (update) {
      writeFileSync(this.file, JSON.stringify(this.actual, null, 2) + '\n');
      return;
    }
    const missing = Object.keys(this.expected).filter((step) => !(step in this.actual));
    assert.deepEqual(missing, [], 'Có bước trong snapshot không được chạy');
    const added = Object.keys(this.actual).filter((step) => !(step in this.expected));
    if (added.length) {
      writeFileSync(this.file, JSON.stringify({ ...this.expected, ...Object.fromEntries(added.map((s) => [s, this.actual[s]])) }, null, 2) + '\n');
    }
  }
}
