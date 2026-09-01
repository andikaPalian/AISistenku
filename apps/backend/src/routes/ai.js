import { Router } from 'express';
import {
  getAiMessages,
  sendChatMessage,
  confirmAiAction,
  clearAiMessages,
} from '../controllers/aiController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.get('/messages', authMiddleware, getAiMessages);
router.post('/chat', authMiddleware, sendChatMessage);
router.post('/actions/:actionId/confirm', authMiddleware, confirmAiAction);
router.delete('/messages', authMiddleware, clearAiMessages);

export default router;
