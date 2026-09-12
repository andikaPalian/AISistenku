import { Router } from 'express';
import * as uploadController from './upload.controller.js';
import { upload, handleMulterError } from './upload.middleware.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';

export const uploadRouter = Router();

// Semua rute upload dilindungi otentikasi JWT
uploadRouter.use(requireAuth);

/**
 * @route POST /api/upload/product
 * @desc Upload foto produk ke folder Cloudinary bisnis tenant
 */
uploadRouter.post(
  '/product',
  requireBusinessContext,
  upload.single('image'),
  handleMulterError,
  uploadController.uploadProductImage
);

/**
 * @route POST /api/upload/avatar
 * @desc Upload foto profil pengguna dengan smart face centering
 */
uploadRouter.post(
  '/avatar',
  upload.single('avatar'),
  handleMulterError,
  uploadController.uploadAvatar
);

/**
 * @route POST /api/upload
 * @desc Upload gambar umum dengan kompresi auto WebP
 */
uploadRouter.post(
  '/',
  upload.single('image'),
  handleMulterError,
  uploadController.uploadGeneral
);

/**
 * @route POST /api/upload/sign
 * @desc Dapatkan signed signature untuk client-side direct upload (Frontend Web)
 */
uploadRouter.post('/sign', uploadController.signUpload);
