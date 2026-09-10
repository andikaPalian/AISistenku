import { z } from 'zod';
import { ProductCategory } from '@prisma/client';

const productCategoryEnum = z.nativeEnum(ProductCategory);

export const createProductSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1, 'Nama produk wajib diisi').max(100),
    price: z.coerce.number().positive('Harga produk harus lebih dari 0'),
    category: z.preprocess(
      (val) => (typeof val === 'string' ? val.toUpperCase().replace(/\s+/g, '_') : val),
      productCategoryEnum
    ),
    imageUrl: z.string().trim().url().optional().nullable(),
    defaultVariant: z.string().trim().max(50).default('Regular').optional(),
    isActive: z.boolean().default(true).optional(),
  }),
});

export const updateProductSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID produk tidak valid'),
  }),
  body: z.object({
    name: z.string().trim().min(1, 'Nama produk tidak boleh kosong').max(100).optional(),
    price: z.coerce.number().positive('Harga produk harus lebih dari 0').optional(),
    category: z.preprocess(
      (val) => (typeof val === 'string' ? val.toUpperCase().replace(/\s+/g, '_') : val),
      productCategoryEnum.optional()
    ),
    imageUrl: z.string().trim().url().optional().nullable(),
    defaultVariant: z.string().trim().max(50).optional().nullable(),
    isActive: z.boolean().optional(),
  }),
});

export const productIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID produk tidak valid'),
  }),
});

export const listProductQuerySchema = z.object({
  query: z.object({
    isActive: z
      .enum(['true', 'false', 'all'])
      .optional()
      .transform((val) => (val === undefined ? true : val === 'all' ? undefined : val === 'true')),
    category: z
      .preprocess(
        (val) => (typeof val === 'string' ? val.toUpperCase().replace(/\s+/g, '_') : val),
        productCategoryEnum.optional()
      )
      .optional(),
    search: z.string().trim().optional(),
  }),
});

export const replaceRecipeSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID produk tidak valid'),
  }),
  body: z.object({
    items: z
      .array(
        z.object({
          stockId: z.string().uuid('ID stok tidak valid'),
          quantityRequired: z.coerce.number().positive('Jumlah bahan resep harus lebih dari 0'),
        })
      )
      .default([]),
  }),
});

export type CreateProductDTO = z.infer<typeof createProductSchema>['body'];
export type UpdateProductDTO = z.infer<typeof updateProductSchema>['body'];
export type ListProductQuery = z.infer<typeof listProductQuerySchema>['query'];
export type ReplaceRecipeDTO = z.infer<typeof replaceRecipeSchema>['body'];
