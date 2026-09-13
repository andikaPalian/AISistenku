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
 * Mendukung field name 'avatar' maupun 'image'
 */
uploadRouter.post(
  '/avatar',
  (req, res, next) => {
    upload.fields([
      { name: 'avatar', maxCount: 1 },
      { name: 'image', maxCount: 1 },
    ])(req, res, (err) => {
      if (err) return handleMulterError(err, req, res, next);
      const files = req.files as { [fieldname: string]: Express.Multer.File[] } | undefined;
      if (files) {
        req.file = files['avatar']?.[0] || files['image']?.[0];
      }
      next();
    });
  },
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
