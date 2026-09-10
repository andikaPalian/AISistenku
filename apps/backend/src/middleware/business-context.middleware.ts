import { Request, Response, NextFunction } from 'express';
import { BadRequestError, ForbiddenError, UnauthorizedError } from '@/errors/http.error.js';
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

  if (!businessId || typeof businessId !== 'string' || businessId.trim() === '') {
    throw new BadRequestError(
      'Header X-Business-Id wajib disertakan untuk mengakses sumber daya bisnis ini.',
      'MISSING_BUSINESS_ID'
    );
  }

  const cleanBusinessId = businessId.trim();

  const membership = await prisma.businessMember.findUnique({
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

  if (!membership) {
    throw new ForbiddenError(
      'Akses ditolak: Anda bukan anggota dari bisnis yang diminta.',
      'FORBIDDEN_BUSINESS_ACCESS'
    );
  }

  req.businessId = cleanBusinessId;
  req.role = membership.role;

  next();
};
