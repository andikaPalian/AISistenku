import { prisma } from '@/config/database.config.js';
import { withPrismaErrorHandling } from '@/utils/prisma-error.util.js';
import { BusinessRole, Prisma, User } from '@prisma/client';

const userWithMembershipsSelect = Prisma.validator<Prisma.UserSelect>()({
  id: true,
  name: true,
  email: true,
  password: true,
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

type UserWithMemberships = Prisma.UserGetPayload<{ select: typeof userWithMembershipsSelect }>;

interface CreateUserAndBusinessInput {
  name: string;
  email: string;
  password: string;
  businessName: string;
  businessAddress: string;
  businessPhone: string;
}

export const createUser = withPrismaErrorHandling(
  async (input: CreateUserAndBusinessInput): Promise<UserWithMemberships> => {
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
                name: input.businessName,
                address: input.businessAddress,
                phone: input.businessPhone,
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
