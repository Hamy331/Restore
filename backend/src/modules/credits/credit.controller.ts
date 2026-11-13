import { Request, Response } from 'express';
import { created, ok, paginated } from '../../common/http/response.js';
import { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as creditService from './credit.service.js';
import type { HistoryQuery, TopupInput } from './credit.validator.js';

type Id = { id: string };

export async function listPackages(_req: AuthRequest, res: Response) {
  ok(res, await creditService.listPackages());
}

export async function getWallet(req: AuthRequest, res: Response) {
  ok(res, await creditService.getWallet(req.user!.userId));
}

export async function listTransactions(req: AuthRequest, res: Response) {
  const { query } = getInput<ValidatedInput<HistoryQuery>>(res);
  const { items, ...page } = await creditService.listTransactions(req.user!.userId, query);
  paginated(res, items, page);
}

export async function createTopup(req: AuthRequest, res: Response) {
  const { body } = getInput<ValidatedInput<undefined, undefined, TopupInput>>(res);
  created(res, await creditService.createTopup(req.user!.userId, body));
}

export async function getTopup(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, Id>>(res);
  ok(res, await creditService.getTopup(req.user!.userId, params.id));
}

export async function cancelTopup(req: AuthRequest, res: Response) {
  const { params } = getInput<ValidatedInput<undefined, Id>>(res);
  ok(res, await creditService.cancelTopup(req.user!.userId, params.id));
}

export async function simulateSandbox(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, Id, { result: 'success' | 'fail' }>>(res);
  ok(res, await creditService.simulateSandbox(req.user!.userId, params.id, body.result));
}

/** ZaloPay gọi khi khách trả xong; luôn trả 200 kèm return_code theo quy ước của ZaloPay */
export async function zaloPayCallback(req: Request, res: Response) {
  res.json(await creditService.zaloPayCallback((req.body ?? {}) as { data?: unknown; mac?: unknown }));
}

/** Trang ZaloPay chuyển khách về sau khi trả. Không cộng xu ở đây: app hỏi lại trạng thái đơn. */
export function zaloPayReturn(_req: Request, res: Response) {
  res.type('html').send(`<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ReStore</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding:48px 16px;color:#333">
<h2>Đã nhận kết quả thanh toán</h2><p>Bạn có thể đóng trang này và quay lại ứng dụng ReStore. Xu sẽ được cộng khi cổng xác nhận.</p>
</body></html>`);
}
