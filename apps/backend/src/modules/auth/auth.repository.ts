import { prisma } from '@/config/database.config.js';
import { Prisma, RefreshToken } from '@prisma/client';

interface SaveTokenArgs {
  jti: string;
  userId: string;
  expiresAt: Date;
}

export const saveRefreshToken = async (input: SaveTokenArgs): Promise<RefreshToken> => {
  return await prisma.refreshToken.create({
    data: {
      id: input.jti,
      userId: input.userId,
      expiresAt: input.expiresAt,
    },
  });
};

export const findRefreshToken = async (jti: string): Promise<RefreshToken | null> => {
  return await prisma.refreshToken.findUnique({
    where: {
      id: jti,
    },
  });
};

export const revokeAllSessionsForUser = async (userId: string): Promise<Prisma.BatchPayload> => {
  return await prisma.refreshToken.deleteMany({
    where: { userId },
  });
};
