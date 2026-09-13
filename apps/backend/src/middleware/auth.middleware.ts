import { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '@/errors/http.error.js';
import { verifyAccessToken } from '@/utils/jwt.util.js';

export const requireAuth = (req: Request, _res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  let token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  if (!token && req.cookies?.accessToken) {
    token = req.cookies.accessToken;
  }

  if (!token) {
    throw new UnauthorizedError('Autentikasi diperlukan. Sediakan Bearer token.', 'UNAUTHORIZED');
  }
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
