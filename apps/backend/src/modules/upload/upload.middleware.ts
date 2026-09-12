import multer from 'multer';
import { Request, Response, NextFunction } from 'express';
import { BadRequestError } from '@/errors/http.error.js';

// Gunakan memoryStorage agar buffer file langsung distreaming ke Cloudinary
// tanpa pernah menulis file sementara ke hard disk server (Stateless & Scalable).
const storage = multer.memoryStorage();

// Whitelist tipe gambar yang diperbolehkan
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/avif',
];

// Batas ukuran file maksimal: 5 Megabytes
const MAX_FILE_SIZE = 5 * 1024 * 1024;

const fileFilter = (
  _req: Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    cb(
      new BadRequestError(
        `Format file "${file.mimetype}" tidak didukung. Harap upload gambar berformat JPG, PNG, atau WebP.`,
        'INVALID_FILE_TYPE'
      )
    );
  }
};

export const upload = multer({
  storage,
  limits: {
    fileSize: MAX_FILE_SIZE,
    files: 1,
  },
  fileFilter,
});

/**
 * Middleware wrapper untuk menangani error multer (misal: file size limit)
 */
export const handleMulterError = (
  err: any,
  _req: Request,
  _res: Response,
  next: NextFunction
) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return next(
        new BadRequestError(
          'Ukuran file gambar terlalu besar. Maksimal ukuran adalah 5 MB.',
          'FILE_TOO_LARGE'
        )
      );
    }
    return next(new BadRequestError(`Gagal memproses upload: ${err.message}`, 'UPLOAD_ERROR'));
  }
  next(err);
};
