import { env } from '@/config/env.config.js';
import { AppError } from '@/errors/base.error.js';
import { ValidationError } from '@/errors/validation.error.js';
import { logger } from '@/utils/logger.js';
import { Request, Response, NextFunction } from 'express';

export const globalErrorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof ValidationError) {
    res.status(err.statusCode).json({
      success: false,
      statusCode: err.statusCode,
      error: {
        code: err.code || 'VALIDATION_ERROR',
        message: err.message,
      },
      message: err.message,
      errors: err.errors,
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      statusCode: err.statusCode,
      error: {
        code: err.code || 'APP_ERROR',
        message: err.message,
      },
      message: err.message,
    });
    return;
  }

  logger.error(`[UNHANDLED ERROR] ${err.stack || err.message}`);

  res.status(500).json({
    success: false,
    statusCode: 500,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
    },
    message: env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
  });
};
