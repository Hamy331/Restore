export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly field?: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const isAppError = (error: unknown): error is AppError =>
  error instanceof AppError;
