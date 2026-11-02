import { ListingCondition } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { boolean, choice, object, text } from '../../common/validation/admin-input.js';

/* Quản trị danh mục và tình trạng; lỗi INVALID_ADMIN_INPUT như API cũ */

/** Body POST /admin/categories */
export const createCategoryBody = z.unknown().transform((value) => {
  const body = object(value, ['id', 'name', 'description', 'active']);
  const name = text(body.name, 'name', 2, 100), id = text(body.id, 'id', 2, 80);
  const description = text(body.description, 'description', 0, 500), active = boolean(body.active);
  if (!/^[a-z0-9-]+$/.test(id)) throw new AppError(400, 'INVALID_ID', 'Mã danh mục chỉ gồm chữ thường, số và dấu gạch ngang.');
  return { id, name, description, active };
});

/** Body PUT /admin/categories/:id */
export const updateCategoryBody = z.unknown().transform((value) => {
  const body = object(value, ['name', 'description', 'active']);
  return { name: text(body.name, 'name', 2, 100), description: text(body.description, 'description', 0, 500), active: boolean(body.active) };
});

/** Params PUT /admin/conditions/:condition */
export const conditionParams = z.record(z.string(), z.unknown())
  .transform((params) => ({ condition: choice(params.condition, Object.values(ListingCondition)) }));

/** Body PUT /admin/conditions/:condition */
export const conditionBody = z.unknown().transform((value) => {
  const body = object(value, ['name', 'active']);
  return { name: text(body.name, 'name', 2, 100), active: boolean(body.active) };
});

export const categoryIdParams = z.object({ id: z.string() });

export type CreateCategoryInput = z.output<typeof createCategoryBody>;
export type UpdateCategoryInput = z.output<typeof updateCategoryBody>;
export type ConditionParams = z.output<typeof conditionParams>;
export type ConditionInput = z.output<typeof conditionBody>;
