import { Request, Response } from 'express';
import * as uploadService from './upload.service.js';
import * as userRepository from '../user/user.repository.js';
import { BadRequestError } from '@/errors/http.error.js';
import { sendCreated } from '@/http/response.js';
import { cloudinary } from '@/config/cloudinary.config.js';
import { env } from '@/config/env.config.js';

export const uploadProductImage = async (req: Request, res: Response): Promise<void> => {
  if (!req.file) {
    throw new BadRequestError('File gambar produk wajib diunggah (field name: "image")', 'FILE_REQUIRED');
  }

  const businessId = req.businessId;
  if (!businessId) {
    throw new BadRequestError('Konteks tenant bisnis aktif tidak ditemukan', 'BUSINESS_CONTEXT_REQUIRED');
  }

  const productName = req.body.productName || req.body.name;
  const result = await uploadService.uploadProductImage(
    req.file.buffer,
    businessId,
    productName
  );

  sendCreated(
    res,
    {
      url: result.secureUrl,
      publicId: result.publicId,
      format: result.format,
      width: result.width,
      height: result.height,
      bytes: result.bytes,
    },
    'Foto produk berhasil diupload ke Cloudinary'
  );
};

export const uploadAvatar = async (req: Request, res: Response): Promise<void> => {
  if (!req.file) {
    throw new BadRequestError('File foto profil wajib diunggah (field name: "avatar" atau "image")', 'FILE_REQUIRED');
  }

  const userId = req.user?.id;
  if (!userId) {
    throw new BadRequestError('Pengguna tidak terautentikasi', 'UNAUTHORIZED');
  }

  const result = await uploadService.uploadAvatarImage(req.file.buffer, userId);

  // Persist avatar URL to user record in database
  await userRepository.updateUser(userId, { avatarUrl: result.secureUrl });

  sendCreated(
    res,
    {
      url: result.secureUrl,
      publicId: result.publicId,
      format: result.format,
      width: result.width,
      height: result.height,
    },
    'Foto profil berhasil diupload ke Cloudinary'
  );
};

export const uploadGeneral = async (req: Request, res: Response): Promise<void> => {
  if (!req.file) {
    throw new BadRequestError('File gambar wajib diunggah (field name: "image")', 'FILE_REQUIRED');
  }

  const folder = req.body.folder || 'tiga-angkatan/general';
  const result = await uploadService.uploadBufferToCloudinary(req.file.buffer, {
    folder,
    transformation: [
      { quality: 'auto:good' },
      { fetch_format: 'auto' },
    ],
    resource_type: 'image',
  });

  sendCreated(
    res,
    {
      url: result.secureUrl,
      publicId: result.publicId,
      format: result.format,
      width: result.width,
      height: result.height,
      bytes: result.bytes,
    },
    'Gambar berhasil diupload ke Cloudinary'
  );
};

export const signUpload = async (req: Request, res: Response): Promise<void> => {
  const folder = req.body.folder || 'tiga-angkatan/products';
  const timestamp = Math.round(new Date().getTime() / 1000);
  const cloudName = env.CLOUDINARY_CLOUD_NAMES || process.env.CLOUDINARY_CLOUD_NAME || '';
  const apiSecret = env.CLOUDINARY_API_SECRET || process.env.CLOUDINARY_API_SECRET || '';
  const apiKey = env.CLOUDINARY_API_KEYS || process.env.CLOUDINARY_API_KEY || '';

  if (!cloudName || !apiSecret || !apiKey) {
    throw new BadRequestError('Cloudinary belum dikonfigurasi di server', 'CLOUDINARY_NOT_CONFIGURED');
  }

  const signature = cloudinary.utils.api_sign_request(
    { timestamp, folder },
    apiSecret
  );

  res.status(200).json({
    signature,
    timestamp,
    apiKey,
    cloudName,
    folder,
    uploadUrl: `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
  });
};
