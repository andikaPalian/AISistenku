import { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '@/errors/http.error.js';
import { verifyAccessToken } from '@/utils/jwt.util.js';

export const requireAuth = (req: Request, _res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('Autentikasi diperlukan. Sediakan Bearer token.', 'UNAUTHORIZED');
  }

  const token = authHeader.split(' ')[1];
  try {
    const verified = verifyAccessToken(token);
    req.user = {
      id: verified.userId,
      name: verified.name,
    };
    next();
  } catch (_err) {
    throw new UnauthorizedError('Token tidak valid atau telah kedaluwarsa.', 'TOKEN_EXPIRED_OR_INVALID');
  }
};
