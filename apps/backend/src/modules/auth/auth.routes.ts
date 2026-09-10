import { Router } from 'express';
import * as authController from './auth.controller.js';
import * as authValidator from './auth.validator.js';
import { authLimiter } from '@/middleware/ratelimit.middleware.js';
import { validate } from '@/middleware/validate.middleware.js';
import { requireAuth } from '@/middleware/auth.middleware.js';

export const authRouter = Router();

authRouter.post(
  '/register',
  authLimiter,
  validate(authValidator.registerSchema),
  authController.register
);
authRouter.post('/login', authLimiter, validate(authValidator.loginSchema), authController.login);
authRouter.post('/refresh', validate(authValidator.refreshTokenSchema), authController.refreshToken);
authRouter.post('/refresh-token', validate(authValidator.refreshTokenSchema), authController.refreshToken);
authRouter.post('/logout', validate(authValidator.logoutSchema), authController.logout);
authRouter.get('/me', requireAuth, authController.getMe);
authRouter.patch(
  '/me',
  requireAuth,
  validate(authValidator.updateMeSchema),
  authController.updateMe
);


