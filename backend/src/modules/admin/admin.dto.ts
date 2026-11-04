import type { z } from 'zod';
import type { pageOnlyQuery, userActionBody, userListQuery } from './admin.validator.js';

/* Vào (suy ra từ schema). Kết quả trả ra là bản ghi Prisma, giữ nguyên như API cũ. */

export type PageQuery = z.output<typeof pageOnlyQuery>;
export type UserListQuery = z.output<typeof userListQuery>;
export type UserActionInput = z.output<typeof userActionBody>;
export type UserIdParams = { id: string };
