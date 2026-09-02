import { signUpload, isCloudinaryConfigured } from '../lib/cloudinary.js';

export const signCloudinaryUpload = async (req, res, next) => {
  try {
    if (!isCloudinaryConfigured()) {
      return res.status(503).json({
        error: 'Cloudinary belum dikonfigurasi di server (CLOUDINARY_* env belum di-set).',
      });
    }
    const { folder } = req.body || {};
    const payload = signUpload(folder);
    return res.json(payload);
  } catch (err) {
    next(err);
  }
};