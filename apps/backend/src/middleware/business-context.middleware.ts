import { Request, Response, NextFunction } from 'express';
import { ForbiddenError, UnauthorizedError } from '@/errors/http.error.js';
import { prisma } from '@/config/database.config.js';

export const requireBusinessContext = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  if (!req.user) {
    throw new UnauthorizedError('Autentikasi diperlukan sebelum mengakses konteks bisnis.', 'UNAUTHORIZED');
  }

  const rawBusinessId = req.headers['x-business-id'];
  const businessId = Array.isArray(rawBusinessId) ? rawBusinessId[0] : rawBusinessId;

  let cleanBusinessId: string | null = null;
  if (businessId && typeof businessId === 'string' && businessId.trim() !== '') {
    cleanBusinessId = businessId.trim();
  }

  let membership = null;
  if (cleanBusinessId) {
    membership = await prisma.businessMember.findUnique({
      where: {
        businessId_userId: {
          businessId: cleanBusinessId,
          userId: req.user.id,
        },
      },
      include: {
        business: true,
      },
    });
  }

  // Graceful fallback: attach user's primary/first active business membership
  // if header was missing, invalid, or belongs to a different/stale local state
  if (!membership) {
    membership = await prisma.businessMember.findFirst({
      where: {
        userId: req.user.id,
      },
      include: {
        business: true,
      },
      orderBy: {
        createdAt: 'asc',
      },
    });
    if (membership) {
      cleanBusinessId = membership.businessId;
    }
  }

  if (!membership || !cleanBusinessId) {
    throw new ForbiddenError(
      'Akses ditolak: Anda belum terdaftar dalam bisnis apapun.',
      'FORBIDDEN_BUSINESS_ACCESS'
    );
  }

  req.businessId = cleanBusinessId;
  req.role = membership.role;

  next();
};
