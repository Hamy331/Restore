import { Response } from 'express';
import { noContent, ok, paginated } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import { searchListings, type SearchQuery } from '../listings/index.js';
import type { AccountSearchQuery, SuggestionsQuery } from './search.dto.js';
import * as searchService from './search.service.js';

/** Tìm tin; trang đầu có từ khoá thì lưu vào lịch sử của người đã đăng nhập */
export async function listings(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<SearchQuery>>(res);
  const userId = req.user?.userId;
  const [{ items, page }] = await Promise.all([
    searchListings(userId, query),
    // Lưu lịch sử hỏng (VD chưa chạy migration) không được làm hỏng kết quả tìm kiếm
    userId && query.pagination.page === 1 && query.filters.q
      ? searchService.recordSearch(userId, query.filters.q).catch((error) => console.error('[search] record history failed', error))
      : null,
  ]);
  paginated(res, items, page);
}

export async function trending(_req: AuthRequest, res: Response) {
  ok(res, await searchService.listTrending());
}

export async function suggestions(_req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<SuggestionsQuery>>(res);
  ok(res, await searchService.listSuggestions(query));
}

export async function history(req: AuthRequest, res: Response) {
  ok(res, await searchService.listHistory(req.user!.userId));
}

export async function deleteHistory(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, { id: string }>>(res);
  await searchService.deleteHistory(req.user!.userId, params.id);
  noContent(res);
}

export async function clearHistory(req: AuthRequest, res: Response) {
  await searchService.clearHistory(req.user!.userId);
  noContent(res);
}

export async function shops(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<AccountSearchQuery>>(res);
  const { items, page } = await searchService.searchShops(req.user?.userId, query);
  paginated(res, items, page);
}

export async function users(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<AccountSearchQuery>>(res);
  const { items, page } = await searchService.searchUsers(req.user?.userId, query);
  paginated(res, items, page);
}
