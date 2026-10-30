import { Prisma } from '@prisma/client';
import { AppError } from '../../errors/app-error.js';

export function text(value: unknown, name: string, min = 1, max = 300) {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) {
    throw new AppError(400, 'INVALID_ADMIN_INPUT', `${name}: cần ${min}–${max} ký tự.`, name);
  }
  return value.trim();
}
export function object(value: unknown, keys: string[]) {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some(key => !keys.includes(key))) {
    throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Dữ liệu chứa trường không hợp lệ.');
  }
  return value as Record<string, unknown>;
}
export function choice<T extends string>(value: unknown, values: readonly T[]): T {
  if (typeof value !== 'string' || !values.includes(value as T)) throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Lựa chọn không hợp lệ.');
  return value as T;
}
export function integer(value: unknown, min: number, max: number) {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) throw new AppError(400, 'INVALID_ADMIN_INPUT', `Số phải từ ${min} đến ${max}.`);
  return value;
}
export function boolean(value: unknown) {
  if (typeof value !== 'boolean') throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Trạng thái không hợp lệ.');
  return value;
}
export function version(value: unknown) {
  const date = new Date(text(value, 'updatedAt', 1, 40));
  if (Number.isNaN(+date)) throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Phiên bản không hợp lệ.');
  return date;
}
export function changed(count: number) {
  if (!count) throw new AppError(409, 'ADMIN_STALE', 'Dữ liệu đã đổi. Tải lại trước khi thao tác.');
}
export function page(value: unknown) {
  if (value == null) return 1;
  if (typeof value !== 'string' || !/^[1-9]\d{0,5}$/.test(value)) throw new AppError(400, 'INVALID_QUERY', 'Trang không hợp lệ.');
  return Number(value);
}
export function audit(tx: Prisma.TransactionClient, actorId: string, action: string, targetType: string, targetId: string,
  reason: string, before?: unknown, after?: unknown) {
  // Explicit public snapshots only: callers must never pass passwords, OTPs or tokens.
  const json = (value: unknown) => value == null ? Prisma.DbNull : JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
  return tx.adminAudit.create({data:{actorId,action,targetType,targetId,reason,before:json(before),after:json(after)}});
}
export const userFields = {id:true,email:true,fullName:true,username:true,role:true,status:true,suspendedUntil:true,updatedAt:true,createdAt:true} as const;

export async function sanction(tx: Prisma.TransactionClient, actorId: string, id: string, action: string, reason: string, days: number, expected: Date) {
  const user = await tx.user.findFirst({where:{id,role:'USER'},select:userFields});
  if (!user || user.status === 'UNVERIFIED') throw new AppError(409,'INVALID_USER_ACTION','Chỉ xử lý tài khoản thành viên đã xác minh.');
  if (action === 'WARN') {
    if (+user.updatedAt !== +expected) changed(0);
  } else {
    const status = action === 'SUSPEND' ? 'SUSPENDED' : action === 'BAN' ? 'BANNED' : 'ACTIVE';
    if ((action === 'RESTORE' && !['SUSPENDED','BANNED'].includes(user.status)) || (action !== 'RESTORE' && user.status === 'BANNED')) throw new AppError(409,'INVALID_USER_ACTION','Trạng thái tài khoản không phù hợp.');
    const result = await tx.user.updateMany({where:{id,role:'USER',updatedAt:expected},data:{status,suspendedUntil:action==='SUSPEND'?new Date(Date.now()+days*86400000):null,authVersion:{increment:1}}});
    changed(result.count);
    await tx.authSession.updateMany({where:{userId:id,revokedAt:null},data:{revokedAt:new Date()}});
  }
  await audit(tx,actorId,action,'USER',id,reason,user,{days,status:action==='WARN'?user.status:action==='SUSPEND'?'SUSPENDED':action==='BAN'?'BANNED':'ACTIVE'});
}

export async function moderate(tx: Prisma.TransactionClient, actorId: string, id: string, action: string, reason: string, expected: Date) {
  const item = await tx.listing.findUnique({where:{id},select:{id:true,status:true,images:true,updatedAt:true,categoryId:true,condition:true,attributes:true}});
  if (!item) throw new AppError(404,'LISTING_NOT_FOUND','Không tìm thấy tin.');
  const allowed = item.status === 'PENDING' ? ['APPROVE','REJECT','REQUEST_CHANGES'] : item.status === 'AVAILABLE' ? ['REMOVE'] : [];
  if (!allowed.includes(action)) throw new AppError(409,'INVALID_DECISION','Tin không ở trạng thái cho phép.');
  if (action === 'APPROVE') {
    if (!item.images.length) throw new AppError(400,'INVALID_LISTING','Tin cần ít nhất một ảnh.');
    const [category, condition] = await Promise.all([
      tx.category.findFirst({where:{id:item.categoryId??'',active:true}}),
      item.condition ? tx.conditionPolicy.findUnique({where:{condition:item.condition}}) : null,
    ]);
    if (!category || !item.condition || condition?.active === false) throw new AppError(409,'INVALID_LISTING','Danh mục hoặc tình trạng không còn được sử dụng.');
  }
  const status = action === 'APPROVE' ? 'AVAILABLE' : 'REJECTED';
  const result = await tx.listing.updateMany({where:{id,status:item.status,updatedAt:expected},data:{status,reviewReason:action==='APPROVE'?null:reason}});
  changed(result.count);
  await audit(tx,actorId,action,'LISTING',id,reason,{status:item.status},{status});
}

export const normalizeKnowledge = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/g,'d').replace(/Đ/g,'D').toLowerCase();
