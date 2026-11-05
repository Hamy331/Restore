import { AppError } from '../../common/errors/app-error.js';

export const parseId = (value: unknown, field: string): string => {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(value)) {
    throw new AppError(422, 'INVALID_ID', `${field} không hợp lệ.`, field);
  }
  return value;
};

export const parseConversationId = (value: unknown) => parseId(value, 'conversationId');
