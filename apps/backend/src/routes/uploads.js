import { Router } from 'express';
import { signCloudinaryUpload } from '../controllers/uploadController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

// Signed-upload is auth-gated to prevent anonymous abuse of Cloudinary quota.
router.post('/sign', authMiddleware, signCloudinaryUpload);

export default router;