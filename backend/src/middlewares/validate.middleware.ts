import { NextFunction, Request, Response } from 'express';
import type { z } from 'zod';
import { parse } from '../common/validation/schemas.js';

/**
 * Kiểm tra đầu vào bằng schema zod trước khi vào controller.
 *
 * Kiểm tra lần lượt query → params → body; sai ở đâu thì trả 400 ngay
 * { success:false, error, code, field }. Dữ liệu đã làm sạch lưu ở res.locals.input,
 * controller đọc lại bằng getInput(res).
 *
 *   router.get('/', validate({ query: feedQuery }), controller.list)
 *   // controller: const { query } = getInput<ValidatedInput<FeedQuery>>(res);
 */
export type RequestSchema = { query?: z.ZodType; params?: z.ZodType; body?: z.ZodType };

type Out<S> = S extends z.ZodType ? z.output<S> : undefined;
export type ValidatedInput<Q = undefined, P = undefined, B = undefined> = { query: Q; params: P; body: B };
export type InputOf<S extends RequestSchema> = ValidatedInput<Out<S['query']>, Out<S['params']>, Out<S['body']>>;

export const validate = (schema: RequestSchema) =>
  (req: Request, res: Response, next: NextFunction) => {
    res.locals.input = {
      query: schema.query && parse(schema.query, req.query ?? {}),
      params: schema.params && parse(schema.params, req.params ?? {}),
      body: schema.body && parse(schema.body, req.body),
    };
    next();
  };

export const getInput = <I extends InputOf<RequestSchema>>(res: Response): I => res.locals.input as I;
