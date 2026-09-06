import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { env } from './config/env.config.js';
import morgan from 'morgan';
import { logger } from './utils/logger.js';
import { globalLimiter } from './middleware/ratelimit.middleware.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { globalErrorHandler } from './middleware/error.middleware.js';

export const createApp = (): Express => {
  const app = express();

  app.set('trust proxy', env.NODE_ENV === 'production' ? 1 : 'loopback');

  app.use(
    helmet({
      contentSecurityPolicy: env.NODE_ENV === 'production' ? undefined : false,
      crossOriginEmbedderPolicy: env.NODE_ENV === 'production',
    })
  );

  app.use(cors());
  app.use(cookieParser());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true, limit: '50mb' }));

  if (env.NODE_ENV !== 'production') {
    app.use(morgan('dev'));
  } else {
    app.use(
      morgan('combined', {
        stream: {
          write: (message) => logger.info(message.trim()),
        },
      })
    );
  }

  app.use(globalLimiter);

  const API_PREFIX = '/api/v1';

  app.use(`${API_PREFIX}/auth`, authRouter);

  app.use((_req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      message: 'The requested resource was not found.',
    });
  });

  app.use(globalErrorHandler);

  return app;
};
