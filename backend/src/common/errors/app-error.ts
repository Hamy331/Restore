export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly field?: string,
    /** Dữ liệu thêm cho app xử lý lỗi, VD giá xu khi vượt hạn mức */
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const isAppError = (error: unknown): error is AppError =>
  error instanceof AppError;
