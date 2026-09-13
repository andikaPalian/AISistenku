import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { env } from './config/env.config.js';
import morgan from 'morgan';
import { logger } from './utils/logger.js';
import { globalLimiter } from './middleware/ratelimit.middleware.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { businessRouter } from './modules/business/business.routes.js';
import { productRouter } from './modules/product/product.routes.js';
import { stockRouter } from './modules/stock/stock.routes.js';
import { orderRouter } from './modules/order/order.routes.js';
import { financeRouter } from './modules/finance/finance.routes.js';
import { dashboardRouter } from './modules/dashboard/dashboard.routes.js';
import { aiRouter } from './modules/ai/ai.routes.js';
import { marketingRouter } from './modules/marketing/marketing.routes.js';
import { uploadRouter } from './modules/upload/upload.routes.js';
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

  const allowedOrigins = [
    env.FRONTEND_ORIGIN,
    'http://localhost:3001',
    'http://localhost:5173',
    'http://localhost:3000',
    'http://127.0.0.1:3001',
    'http://127.0.0.1:5173',
  ].filter(Boolean) as string[];

  app.use(cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin) || env.NODE_ENV !== 'production') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
  }));
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

  // Health check endpoint
  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({ status: 'ok', service: 'AIsistenku Backend API', timestamp: new Date() });
  });

  // Domain Routers
  app.use(`${API_PREFIX}/auth`, authRouter);
  app.use(`${API_PREFIX}/businesses`, businessRouter);
  app.use(`${API_PREFIX}/products`, productRouter);
  app.use(`${API_PREFIX}/stock`, stockRouter);
  app.use(`${API_PREFIX}/stocks`, stockRouter); // Alias
  app.use(`${API_PREFIX}/orders`, orderRouter);
  app.use(`${API_PREFIX}/finance`, financeRouter);
  app.use(`${API_PREFIX}/dashboard`, dashboardRouter);
  app.use(`${API_PREFIX}/ai`, aiRouter);
  app.use(`${API_PREFIX}/marketing-content`, marketingRouter);
  app.use(`${API_PREFIX}/upload`, uploadRouter);
  app.use(`${API_PREFIX}/uploads`, uploadRouter);

  // Backward compatibility alias for /api without /v1
  app.use('/api/auth', authRouter);
  app.use('/api/businesses', businessRouter);
  app.use('/api/products', productRouter);
  app.use('/api/stock', stockRouter);
  app.use('/api/stocks', stockRouter);
  app.use('/api/orders', orderRouter);
  app.use('/api/finance', financeRouter);
  app.use('/api/dashboard', dashboardRouter);
  app.use('/api/ai', aiRouter);
  app.use('/api/marketing-content', marketingRouter);
  app.use('/api/upload', uploadRouter);
  app.use('/api/uploads', uploadRouter);

  app.use((_req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'Endpoint yang diminta tidak ditemukan.',
      },
      message: 'Endpoint yang diminta tidak ditemukan.',
    });
  });

  app.use(globalErrorHandler);

  return app;
};
