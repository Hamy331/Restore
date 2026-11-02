import { NextFunction, Request, Response } from 'express';

/**
 * Kiểm tra đầu vào trước khi vào controller.
 *
 * Mỗi parser nhận req.query / req.params / req.body thô và trả về dữ liệu
 * đã làm sạch hoặc ném AppError 400. Kết quả lưu ở res.locals.input,
 * controller đọc lại bằng getInput(res).
 *
 *   router.get('/', validate({ query: parseFeedQuery }), controller.list)
 */
type Parser<T> = (value: any) => T;
type Schema<Q, P, B> = { query?: Parser<Q>; params?: Parser<P>; body?: Parser<B> };
export type ValidatedInput<Q = undefined, P = undefined, B = undefined> = { query: Q; params: P; body: B };

export const validate = <Q = undefined, P = undefined, B = undefined>(schema: Schema<Q, P, B>) =>
  (req: Request, res: Response, next: NextFunction) => {
    res.locals.input = {
      query: schema.query?.(req.query ?? {}),
      params: schema.params?.(req.params ?? {}),
      body: schema.body?.(req.body),
    };
    next();
  };

export const getInput = <I extends ValidatedInput<any, any, any>>(res: Response): I => res.locals.input as I;
