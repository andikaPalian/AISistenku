import { prisma } from '@/config/database.config.js';
import { withPrismaErrorHandling } from '@/utils/prisma-error.util.js';
import { BusinessRole, Prisma } from '@prisma/client';

const userWithMembershipsSelect = Prisma.validator<Prisma.UserSelect>()({
  id: true,
  name: true,
  email: true,
  password: true,
  avatarUrl: true,
  memberships: {
    select: {
      id: true,
      role: true,
      business: {
        select: {
          id: true,
          name: true,
          address: true,
          phone: true,
        },
      },
    },
  },
});

export type UserWithMemberships = Prisma.UserGetPayload<{ select: typeof userWithMembershipsSelect }>;

export interface CreateUserAndBusinessInput {
  name: string;
  email: string;
  password: string;
  businessName?: string;
  businessAddress?: string;
  businessPhone?: string;
}

export const createUser = withPrismaErrorHandling(
  async (input: CreateUserAndBusinessInput): Promise<UserWithMemberships> => {
    const businessName = input.businessName || `${input.name}'s Coffee`;
    return await prisma.user.create({
      data: {
        name: input.name,
        email: input.email,
        password: input.password,
        memberships: {
          create: {
            role: BusinessRole.OWNER,
            business: {
              create: {
                name: businessName,
                address: input.businessAddress || null,
                phone: input.businessPhone || null,
              },
            },
          },
        },
      },
      select: userWithMembershipsSelect,
    });
  },
  'User'
);

export const findUserByEmail = withPrismaErrorHandling(
  async (email: string): Promise<UserWithMemberships | null> => {
    return await prisma.user.findUnique({
      where: { email },
      select: userWithMembershipsSelect,
    });
  },
  'User'
);

export const findUserById = withPrismaErrorHandling(
  async (userId: string): Promise<UserWithMemberships | null> => {
    return await prisma.user.findUnique({
      where: {
        id: userId,
      },
      select: userWithMembershipsSelect,
    });
  }
);

export const updateUser = withPrismaErrorHandling(
  async (userId: string, data: { name?: string; avatarUrl?: string | null }): Promise<UserWithMemberships> => {
    return await prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.name ? { name: data.name } : {}),
        ...(data.avatarUrl !== undefined ? { avatarUrl: data.avatarUrl } : {}),
      },
      select: userWithMembershipsSelect,
    });
  },
  'User'
);

