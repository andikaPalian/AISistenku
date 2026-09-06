import { RateLimiterPrisma, RateLimiterMemory, RateLimiterRes } from 'rate-limiter-flexible';
import { Request, Response, NextFunction, RequestHandler } from 'express';
import { prisma } from './database.config.js';
import { logger } from '@/utils/logger.js';


export const RATE_LIMIT = {
  KEY_PREFIX: 'rl_',
  AUTH_LIMIT_WINDOW_MINS: 15,
  AUTH_LIMIT_MAX_ATTEMPTS: 10,
  EMAIL_LIMIT_WINDOW_MINS: 5,
  EMAIL_LIMIT_MAX_ATTEMPTS: 3,
  GLOBAL_LIMIT_WINDOW_MINS: 1,
  GLOBAL_LIMIT_MAX_ATTEMPTS: 100,
} as const;

interface CreateLimiterOptions {
  windowMins: number;
  maxAttempts: number;
  message: string;
  limiterName: string;
}

export const createLimiter = ({
  windowMins,
  maxAttempts,
  message,
  limiterName,
}: CreateLimiterOptions): RequestHandler => {
  const duration = windowMins * 60;

  const limiter = new RateLimiterPrisma({
    storeClient: prisma,
    keyPrefix: `${RATE_LIMIT.KEY_PREFIX}${limiterName}`,
    points: maxAttempts,
    duration,
    insuranceLimiter: new RateLimiterMemory({
      keyPrefix: `${RATE_LIMIT.KEY_PREFIX}${limiterName}:insurance`,
      points: maxAttempts,
      duration,
    }),
  });

  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const key = req.ip ?? 'unknown';
    try {
      await limiter.consume(key);
      next();
    } catch (error) {
      if (error instanceof RateLimiterRes) {
        const retryAfterSecs = Math.ceil(error.msBeforeNext / 1000);
        logger.warn(
          `[RATE LIMITER] ${limiterName} | IP: ${key} | Path: ${req.originalUrl} | Retry after: ${retryAfterSecs}s`
        );
        res.set({
          'Retry-After': String(retryAfterSecs),
          'X-RateLimit-Limit': String(maxAttempts),
          'X-RateLimit-Remaining': String(error.remainingPoints ?? 0),
          'X-RateLimit-Reset': String(Math.ceil((Date.now() + error.msBeforeNext) / 1000)),
        });
        res.status(429).json({
          success: false,
          statusCode: 429,
          error: 'TOO_MANY_REQUESTS',
          message,
          retryAfter: retryAfterSecs,
        });
        return;
      }
      logger.warn(`[RATE LIMITER] Unexpected error in ${limiterName}: ${(error as Error).message}`);
      next(error);
    }
  };
};
