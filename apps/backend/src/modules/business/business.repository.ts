import { prisma } from '@/config/database.config.js';
import { Business, BusinessMember, BusinessRole } from '@prisma/client';

export interface CreateBusinessData {
  name: string;
  address?: string | null;
  phone?: string | null;
}

export interface UpdateBusinessData {
  name?: string;
  address?: string | null;
  phone?: string | null;
}

export const findBusinessesByUserId = async (userId: string) => {
  return await prisma.businessMember.findMany({
    where: { userId },
    select: {
      id: true,
      role: true,
      createdAt: true,
      business: {
        select: {
          id: true,
          name: true,
          address: true,
          phone: true,
          createdAt: true,
          updatedAt: true,
        },
      },
    },
    orderBy: { createdAt: 'asc' },
  });
};

export const createBusinessWithOwner = async (
  data: CreateBusinessData,
  userId: string
): Promise<Business> => {
  return await prisma.$transaction(async (tx) => {
    const business = await tx.business.create({
      data: {
        name: data.name,
        address: data.address ?? null,
        phone: data.phone ?? null,
      },
    });

    await tx.businessMember.create({
      data: {
        businessId: business.id,
        userId,
        role: BusinessRole.OWNER,
      },
    });

    return business;
  });
};

export const findBusinessById = async (id: string): Promise<Business | null> => {
  return await prisma.business.findUnique({
    where: { id },
  });
};

export const updateBusiness = async (
  id: string,
  data: UpdateBusinessData
): Promise<Business> => {
  return await prisma.business.update({
    where: { id },
    data,
  });
};

export const findBusinessMembership = async (
  businessId: string,
  userId: string
): Promise<BusinessMember | null> => {
  return await prisma.businessMember.findUnique({
    where: {
      businessId_userId: {
        businessId,
        userId,
      },
    },
  });
};

export const findBusinessMembers = async (businessId: string) => {
  return await prisma.businessMember.findMany({
    where: { businessId },
    select: {
      id: true,
      businessId: true,
      userId: true,
      role: true,
      createdAt: true,
      user: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
    orderBy: { createdAt: 'asc' },
  });
};

export const findMemberById = async (memberId: string): Promise<BusinessMember | null> => {
  return await prisma.businessMember.findUnique({
    where: { id: memberId },
  });
};

export const addBusinessMember = async (
  businessId: string,
  userId: string,
  role: BusinessRole
): Promise<BusinessMember> => {
  return await prisma.businessMember.create({
    data: {
      businessId,
      userId,
      role,
    },
  });
};

export const updateBusinessMemberRole = async (
  memberId: string,
  role: BusinessRole
): Promise<BusinessMember> => {
  return await prisma.businessMember.update({
    where: { id: memberId },
    data: { role },
  });
};

export const deleteBusinessMember = async (memberId: string): Promise<BusinessMember> => {
  return await prisma.businessMember.delete({
    where: { id: memberId },
  });
};
