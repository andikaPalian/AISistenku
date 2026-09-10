import { Request, Response, NextFunction } from 'express';
import { ForbiddenError } from '@/errors/http.error.js';
import { BusinessRole } from '@prisma/client';

export const requireRole = (...allowedRoles: BusinessRole[]) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.role || !allowedRoles.includes(req.role)) {
      throw new ForbiddenError(
        `Akses ditolak: Operasi ini hanya diizinkan untuk peran ${allowedRoles.join(', ')}.`,
        'INSUFFICIENT_PERMISSIONS'
      );
    }
    next();
  };
};

export const requireOwner = requireRole(BusinessRole.OWNER);
