import { createApp } from './app.js';
import { connectCloudinary } from './config/cloudinary.config.js';
import { prisma } from './config/database.config.js';
import { env } from './config/env.config.js';
import { logger } from './utils/logger.js';

const app = createApp();

const startServer = async () => {
  try {
    await connectCloudinary();

    const server = app.listen(env.PORT, () => {
      logger.info(`=======================================================`);
      logger.info(`🚀 AIsistenku Backend Server active on http://localhost:${env.PORT}`);
      logger.info(`☕ System: POS & AI Business Assistant for Coffee Shop UMKM`);
      logger.info(`🏛️ Architecture: Multi-Tenant REST API + Gemini AI Agent`);
      logger.info(`=======================================================`);
    });

    // 4. Graceful Shutdown
    const gracefulShutdown = async (signal: string) => {
      logger.warn(`🛑 Received ${signal}. Starting graceful shutdown...`);
      server.close(async () => {
        logger.info('HTTP Server closed.');
        await prisma.$disconnect();
        logger.info('Database connection disconnected.');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  } catch (error) {
    logger.error('💥 Server bootstrap failed:', error);
    process.exit(1);
  }
};

startServer();
