import { z } from 'zod';
import { MarketingContentStatus, MarketingContentType } from '@prisma/client';

const contentTypeEnum = z.preprocess((val) => {
  if (typeof val === 'string') return val.toUpperCase();
  return val;
}, z.nativeEnum(MarketingContentType));

const contentStatusEnum = z.preprocess((val) => {
  if (typeof val === 'string') return val.toUpperCase();
  return val;
}, z.nativeEnum(MarketingContentStatus));

export const createMarketingContentSchema = z.object({
  body: z.object({
    type: contentTypeEnum.default(MarketingContentType.CAPTION),
    content: z.string().trim().min(1, 'Konten promosi tidak boleh kosong'),
    platform: z.string().trim().max(50).optional().nullable(),
    prompt: z.string().trim().max(500).optional().nullable(),
    productId: z.string().uuid('ID produk tidak valid').optional().nullable(),
    sourceMessageId: z.string().uuid('ID pesan sumber tidak valid').optional().nullable(),
    status: contentStatusEnum.default(MarketingContentStatus.SAVED).optional(),
  }),
});

export const updateMarketingContentSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID konten tidak valid'),
  }),
  body: z.object({
    content: z.string().trim().min(1).optional(),
    status: contentStatusEnum.optional(),
    platform: z.string().trim().max(50).optional().nullable(),
  }),
});

export const marketingContentIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID konten tidak valid'),
  }),
});

export const listMarketingContentQuerySchema = z.object({
  query: z.object({
    status: contentStatusEnum.optional(),
    productId: z.string().uuid().optional(),
  }),
});

export type CreateMarketingContentDTO = z.infer<typeof createMarketingContentSchema>['body'];
export type UpdateMarketingContentDTO = z.infer<typeof updateMarketingContentSchema>['body'];
export type ListMarketingContentQuery = z.infer<typeof listMarketingContentQuerySchema>['query'];
