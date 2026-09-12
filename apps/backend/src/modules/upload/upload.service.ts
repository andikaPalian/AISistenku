import { Readable } from 'stream';
import { UploadApiResponse, UploadApiOptions } from 'cloudinary';
import { cloudinary } from '@/config/cloudinary.config.js';
import { env } from '@/config/env.config.js';
import { BadRequestError } from '@/errors/http.error.js';
import { logger } from '@/utils/logger.js';

export interface UploadResult {
  url: string;
  secureUrl: string;
  publicId: string;
  format: string;
  width: number;
  height: number;
  bytes: number;
}

/**
 * Validasi apakah kredensial Cloudinary sudah disetel di environment
 */
const isCloudinaryConfigured = (): boolean => {
  const cloudName = env.CLOUDINARY_CLOUD_NAMES || process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = env.CLOUDINARY_API_KEYS || process.env.CLOUDINARY_API_KEY;
  const apiSecret = env.CLOUDINARY_API_SECRET || process.env.CLOUDINARY_API_SECRET;
  return Boolean(cloudName && apiKey && apiSecret);
};

/**
 * Upload buffer gambar ke Cloudinary via streaming (Best practice untuk arsitektur cloud stateless)
 */
export const uploadBufferToCloudinary = async (
  buffer: Buffer,
  options: UploadApiOptions
): Promise<UploadResult> => {
  if (!isCloudinaryConfigured()) {
    throw new BadRequestError(
      'Layanan upload gambar Cloudinary belum dikonfigurasi di server. Harap isi CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, dan CLOUDINARY_API_SECRET di file .env.',
      'CLOUDINARY_NOT_CONFIGURED'
    );
  }

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      options,
      (error, result?: UploadApiResponse) => {
        if (error || !result) {
          logger.error(`[CLOUDINARY UPLOAD ERROR]: ${error?.message || 'Unknown error'}`);
          return reject(
            new BadRequestError(
              `Gagal mengupload gambar ke Cloudinary: ${error?.message || 'Upload gagal'}`,
              'UPLOAD_FAILED'
            )
          );
        }

        resolve({
          url: result.url,
          secureUrl: result.secure_url,
          publicId: result.public_id,
          format: result.format,
          width: result.width,
          height: result.height,
          bytes: result.bytes,
        });
      }
    );

    // Pipe buffer ke upload stream
    const readableStream = new Readable();
    readableStream.push(buffer);
    readableStream.push(null);
    readableStream.pipe(uploadStream);
  });
};

/**
 * Upload foto produk toko dengan optimasi otomatis, WebP auto-format, dan batas resolusi 1000px
 */
export const uploadProductImage = async (
  buffer: Buffer,
  businessId: string,
  productName?: string
): Promise<UploadResult> => {
  const sanitizedName = (productName || 'product')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '-')
    .slice(0, 30);
  const publicId = `${sanitizedName}-${Date.now()}`;

  return await uploadBufferToCloudinary(buffer, {
    folder: `tiga-angkatan/products/${businessId}`,
    public_id: publicId,
    transformation: [
      { width: 1000, height: 1000, crop: 'limit' }, // Resize proporsional maksimal 1000x1000
      { quality: 'auto:good' },                     // Kompresi cerdas tanpa degradasi visual
      { fetch_format: 'auto' },                     // Otomatis convert ke WebP / AVIF
    ],
    resource_type: 'image',
  });
};

/**
 * Upload foto profil pengguna dengan smart crop terpusat pada wajah (face gravity)
 */
export const uploadAvatarImage = async (
  buffer: Buffer,
  userId: string
): Promise<UploadResult> => {
  const publicId = `avatar-${userId}-${Date.now()}`;

  return await uploadBufferToCloudinary(buffer, {
    folder: `tiga-angkatan/avatars/${userId}`,
    public_id: publicId,
    transformation: [
      { width: 500, height: 500, crop: 'fill', gravity: 'face' }, // Smart face-focus avatar
      { quality: 'auto:good' },
      { fetch_format: 'auto' },
    ],
    resource_type: 'image',
  });
};

/**
 * Hapus gambar dari Cloudinary berdasarkan publicId (untuk cleanup aset yang diganti)
 */
export const deleteImage = async (publicId: string): Promise<boolean> => {
  if (!isCloudinaryConfigured() || !publicId) return false;
  try {
    const res = await cloudinary.uploader.destroy(publicId);
    return res.result === 'ok';
  } catch (err: any) {
    logger.warn(`[CLOUDINARY DELETE ERROR]: ${err.message}`);
    return false;
  }
};
