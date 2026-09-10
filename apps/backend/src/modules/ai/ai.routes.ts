import { Router } from 'express';
import * as aiController from './ai.controller.js';
import * as aiValidator from './ai.validator.js';
import { requireAuth } from '@/middleware/auth.middleware.js';
import { requireBusinessContext } from '@/middleware/business-context.middleware.js';
import { aiLimiter } from '@/middleware/ratelimit.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';

export const aiRouter = Router();

// Semua rute AI wajib auth dan konteks tenant bisnis aktif
aiRouter.use(requireAuth);
aiRouter.use(requireBusinessContext);

// Lindungi pemanggilan endpoint AI dengan rate-limiting
aiRouter.post(
  '/chat',
  aiLimiter,
  validate(aiValidator.chatSchema),
  aiController.chat
);

aiRouter.get('/messages', aiController.getMessages);
aiRouter.delete('/messages', aiController.clearMessages);

aiRouter.post(
  '/actions/:id/confirm',
  validate(aiValidator.actionIdParamSchema),
  aiController.confirmAction
);

aiRouter.post(
  '/actions/:id/cancel',
  validate(aiValidator.actionIdParamSchema),
  aiController.cancelAction
);

aiRouter.post(
  '/content-ideas',
  aiLimiter,
  validate(aiValidator.contentIdeasSchema),
  aiController.getContentIdeas
);
