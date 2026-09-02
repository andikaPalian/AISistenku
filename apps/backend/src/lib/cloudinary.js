import { v2 as cloudinary } from 'cloudinary';
import 'dotenv/config';

const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME;
const CLOUDINARY_API_KEY    = process.env.CLOUDINARY_API_KEY;
const CLOUDINARY_API_SECRET = process.env.CLOUDINARY_API_SECRET;
const CLOUDINARY_FOLDER     = process.env.CLOUDINARY_FOLDER || 'tiga-angkatan/products';

export function isCloudinaryConfigured() {
  return Boolean(CLOUDINARY_CLOUD_NAME && CLOUDINARY_API_KEY && CLOUDINARY_API_SECRET);
}

if (isCloudinaryConfigured()) {
  cloudinary.config({
    cloud_name: CLOUDINARY_CLOUD_NAME,
    api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET,
    secure: true,
  });
}

/**
 * Build a signed-upload payload the browser uses to POST directly to Cloudinary.
 * The API secret never leaves the server.
 */
export function signUpload(folder = CLOUDINARY_FOLDER) {
  if (!isCloudinaryConfigured()) {
    throw new Error('Cloudinary is not configured on the server (missing env vars).');
  }
  const timestamp = Math.round(Date.now() / 1000);
  const signature = cloudinary.utils.api_sign_request(
    { timestamp, folder },
    CLOUDINARY_API_SECRET
  );
  return {
    signature,
    timestamp,
    apiKey: CLOUDINARY_API_KEY,
    cloudName: CLOUDINARY_CLOUD_NAME,
    folder,
    uploadUrl: `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`,
  };
}

/**
 * Delete a Cloudinary asset by public_id. Best-effort: errors are swallowed
 * because we never want a delete-DB-row to be blocked by an external failure.
 */
export async function deleteAsset(publicId) {
  if (!isCloudinaryConfigured() || !publicId) return { ok: false, skipped: true };
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    return { ok: result.result === 'ok', result };
  } catch (err) {
    console.warn('[cloudinary] delete failed:', err.message);
    return { ok: false, error: err.message };
  }
}

/**
 * Extract the public_id from a Cloudinary secure_url. e.g.
 * https://res.cloudinary.com/s4wfinw3/image/upload/v123/tiga-angkatan/products/abc.jpg
 *  -> tiga-angkatan/products/abc
 */
export function publicIdFromUrl(url) {
  if (!url || typeof url !== 'string') return null;
  try {
    const m = url.match(/\/image\/upload\/(?:v\d+\/)?(.+?)\.[a-zA-Z0-9]+$/);
    return m ? m[1] : null;
  } catch {
    return null;
  }
}

export const config = {
  cloudName: CLOUDINARY_CLOUD_NAME,
  folder: CLOUDINARY_FOLDER,
};