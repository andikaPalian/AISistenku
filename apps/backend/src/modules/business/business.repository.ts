import { prisma } from '@/config/database.config.js';
import { Business, BusinessMember } from '@prisma/client';

interface CreateBusinessInput {
  name: string;
  address: string;
  phone: string;
}

export const createBusiness = async (input: CreateBusinessInput): Promise<Business> => {
  return await prisma.business.create({
    data: input,
  });
};

export const createBusinessMember = async (
  businessId: string,
  userId: string
): Promise<BusinessMember> => {
  return await prisma.businessMember.create({
    data: {
      businessId,
      userId,
    },
  });
};
