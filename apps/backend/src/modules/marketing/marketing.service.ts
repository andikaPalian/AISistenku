import * as marketingRepo from './marketing.repository.js';
import { NotFoundError } from '@/errors/http.error.js';
import {
  CreateMarketingContentDTO,
  ListMarketingContentQuery,
  UpdateMarketingContentDTO,
} from './marketing.validator.js';
import { MarketingContentStatus } from '@prisma/client';

export const listMarketingContents = async (
  businessId: string,
  query: ListMarketingContentQuery
) => {
  // Default filter status SAVED jika tidak ditentukan
  const status = query.status ?? MarketingContentStatus.SAVED;
  return await marketingRepo.findMarketingContentsByBusinessId(businessId, {
    status,
    productId: query.productId,
  });
};

export const getMarketingContentById = async (id: string, businessId: string) => {
  const content = await marketingRepo.findMarketingContentById(id, businessId);
  if (!content) {
    throw new NotFoundError('Konten promosi', 'MARKETING_CONTENT_NOT_FOUND');
  }
  return content;
};

export const createMarketingContent = async (
  businessId: string,
  input: CreateMarketingContentDTO
) => {
  return await marketingRepo.createMarketingContent(businessId, input);
};

export const updateMarketingContent = async (
  id: string,
  businessId: string,
  input: UpdateMarketingContentDTO
) => {
  await getMarketingContentById(id, businessId);
  return await marketingRepo.updateMarketingContent(id, businessId, input);
};

export const deleteMarketingContent = async (id: string, businessId: string) => {
  await getMarketingContentById(id, businessId);
  return await marketingRepo.deleteMarketingContent(id, businessId);
};
