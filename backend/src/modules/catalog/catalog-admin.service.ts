import { Prisma } from '@prisma/client';
import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { withQuotaTransaction } from '../commerce/index.js';
import * as catalogRepository from './catalog.repository.js';
import type { ConditionInput, ConditionParams, CreateCategoryInput, UpdateCategoryInput } from './catalog.validator.js';

const duplicate = () => new AppError(409, 'DUPLICATE_CATEGORY', 'Tên danh mục đã tồn tại.');

/** Mọi danh mục và tình trạng, kể cả đã tắt */
export async function getCatalog() {
  const [categories, conditions] = await catalogRepository.findAll();
  return { categories, conditions };
}

/** Tạo danh mục (tên không trùng), metadata khởi tạo chưa có thuộc tính. Ghi AdminAudit. */
export function createCategory(actorId: string, { id, name, description, active }: CreateCategoryInput) {
  return withQuotaTransaction(async (tx) => {
    if (await catalogRepository.findByName(tx, name)) throw duplicate();
    const item = await catalogRepository.createCategory(tx, { id, name, active, metadata: { name, description, attributes: [] } });
    await audit(tx, actorId, 'CREATE', 'CATEGORY', id, name);
    return item;
  });
}

/** Đổi tên, mô tả, bật/tắt danh mục; giữ nguyên thuộc tính trong metadata. Ghi AdminAudit kèm trước/sau. */
export function updateCategory(actorId: string, id: string, { name, description, active }: UpdateCategoryInput) {
  return withQuotaTransaction(async (tx) => {
    const old = await catalogRepository.findCategoryOrThrow(tx, id);
    if (await catalogRepository.findByName(tx, name, id)) throw duplicate();
    const item = await catalogRepository.updateCategory(tx, id,
      { name, active, metadata: { ...(old.metadata as Prisma.JsonObject), name, description } });
    await audit(tx, actorId, 'UPDATE', 'CATEGORY', id, name, old, item);
    return item;
  });
}

/** Đặt tên hiển thị và bật/tắt một tình trạng. Ghi AdminAudit. */
export function updateCondition(actorId: string, { condition }: ConditionParams, data: ConditionInput) {
  return withQuotaTransaction(async (tx) => {
    const item = await catalogRepository.upsertCondition(tx, condition, data);
    await audit(tx, actorId, 'UPDATE', 'CONDITION', condition, item.name);
    return item;
  });
}
