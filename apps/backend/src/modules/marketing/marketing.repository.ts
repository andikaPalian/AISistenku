import { prisma } from '@/config/database.config.js';
import {
  MarketingContent,
  MarketingContentStatus,
  MarketingContentType,
  Prisma,
} from '@prisma/client';

export interface CreateMarketingContentInput {
  type: MarketingContentType;
  content: string;
  platform?: string | null;
  prompt?: string | null;
  productId?: string | null;
  sourceMessageId?: string | null;
  status?: MarketingContentStatus;
}

export interface UpdateMarketingContentInput {
  content?: string;
  status?: MarketingContentStatus;
  platform?: string | null;
}

export const findMarketingContentsByBusinessId = async (
  businessId: string,
  options?: { status?: MarketingContentStatus; productId?: string }
): Promise<MarketingContent[]> => {
  const where: Prisma.MarketingContentWhereInput = {
    businessId,
  };

  if (options?.status) {
    where.status = options.status;
  }

  if (options?.productId) {
    where.productId = options.productId;
  }

  return await prisma.marketingContent.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    include: {
      product: {
        select: {
          id: true,
          name: true,
          price: true,
        },
      },
    },
  });
};

export const findMarketingContentById = async (
  id: string,
  businessId: string
): Promise<MarketingContent | null> => {
  return await prisma.marketingContent.findFirst({
    where: { id, businessId },
    include: {
      product: true,
      sourceMessage: true,
    },
  });
};

export const createMarketingContent = async (
  businessId: string,
  data: CreateMarketingContentInput
): Promise<MarketingContent> => {
  return await prisma.marketingContent.create({
    data: {
      businessId,
      type: data.type,
      content: data.content,
      platform: data.platform ?? null,
      prompt: data.prompt ?? null,
      productId: data.productId ?? null,
      sourceMessageId: data.sourceMessageId ?? null,
      status: data.status ?? MarketingContentStatus.SAVED,
    },
  });
};

export const updateMarketingContent = async (
  id: string,
  businessId: string,
  data: UpdateMarketingContentInput
): Promise<MarketingContent> => {
  return await prisma.marketingContent.update({
    where: { id, businessId },
    data,
  });
};

export const deleteMarketingContent = async (
  id: string,
  businessId: string
): Promise<MarketingContent> => {
  return await prisma.marketingContent.delete({
    where: { id, businessId },
  });
};
