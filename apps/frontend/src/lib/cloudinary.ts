import { apiPost } from './api';

export interface UploadResult {
  url: string;
  publicId: string;
}

/**
 * Upload a File to Cloudinary via the backend's signed-upload flow.
 * Returns the secure_url + public_id once Cloudinary accepts the upload.
 *
 * Throws { error, status } on failure so callers can surface the message.
 */
export async function uploadImage(file: File, folder?: string): Promise<UploadResult> {
  const targetFolder =
    folder ||
    (import.meta.env.VITE_CLOUDINARY_FOLDER as string) ||
    'tiga-angkatan/products';

  const sig = await apiPost<{
    signature: string;
    timestamp: number;
    apiKey: string;
    cloudName: string;
    folder: string;
    uploadUrl: string;
  }>('/uploads/sign', { folder: targetFolder });

  const fd = new FormData();
  fd.append('file', file);
  fd.append('api_key', sig.apiKey);
  fd.append('timestamp', String(sig.timestamp));
  fd.append('signature', sig.signature);
  fd.append('folder', sig.folder);

  const res = await fetch(sig.uploadUrl, { method: 'POST', body: fd });
  const json = await res.json().catch(() => ({} as any));
  if (!res.ok) {
    const message =
      (json && (json.error?.message || json.error)) ||
      `Upload gagal (HTTP ${res.status})`;
    throw { error: message, status: res.status } as { error: string; status: number };
  }

  return {
    url: json.secure_url as string,
    publicId: json.public_id as string,
  };
}

/**
 * Quick helper: returns true if the string already looks like a Cloudinary URL.
 * Lets StockScreen skip re-uploading when the user is editing an item whose
 * image was previously uploaded.
 */
export function isCloudinaryUrl(value: string | undefined | null): boolean {
  return !!value && /res\.cloudinary\.com\//.test(value);
}