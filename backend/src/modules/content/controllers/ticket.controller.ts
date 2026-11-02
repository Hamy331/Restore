import { Response } from 'express';
import { ok } from '../../../common/http/response.js';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { getInput, ValidatedInput } from '../../../middlewares/validate.middleware.js';
import type { PageQuery, TicketInput, TicketReplyInput } from '../content.dto.js';
import * as ticketService from '../services/ticket.service.js';

export async function listMine(req: AuthRequest, res: Response) {
  ok(res, await ticketService.listMine(req.user!.userId, getInput<ValidatedInput<PageQuery>>(res).query));
}

/** Trả 200 (không phải 201) như API cũ */
export async function create(req: AuthRequest, res: Response) {
  ok(res, await ticketService.create(req.user!.userId, getInput<ValidatedInput<undefined, undefined, TicketInput>>(res).body));
}

export async function reply(req: AuthRequest, res: Response) {
  const { params, body } = getInput<ValidatedInput<undefined, { id: string }, TicketReplyInput>>(res);
  ok(res, await ticketService.reply(req.user!.userId, params.id, body.content));
}
