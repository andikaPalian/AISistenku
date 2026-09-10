import { v2 as cloudinary } from 'cloudinary';
import { env } from './env.config.js';
import { logger } from '@/utils/logger.js';

cloudinary.config({
  cloud_name: env.CLOUDINARY_CLOUD_NAMES,
  api_key: env.CLOUDINARY_API_KEYS,
  api_secret: env.CLOUDINARY_API_SECRET,
  secure: true,
});

export const connectCloudinary = async (): Promise<void> => {
  if (!env.CLOUDINARY_API_KEYS || !env.CLOUDINARY_CLOUD_NAMES) {
    logger.warn('[CLOUDINARY] Cloudinary credentials not fully provided. Image uploads will be disabled.');
    return;
  }
  try {
    await cloudinary.api.ping();
    logger.info('[CLOUDINARY] Connected to cloudinary successfully.');
  } catch (error) {
    const err = error as Error;
    logger.warn(`[CLOUDINARY] Failed to connect to cloudinary (${err.message}). Continuing without Cloudinary.`);
  }
};

export { cloudinary };
