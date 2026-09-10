import { z } from 'zod';
import { StockLogSource, StockLogType } from '@prisma/client';

export const listStockQuerySchema = z.object({
  query: z.object({
    belowMin: z
      .enum(['true', 'false'])
      .optional()
      .transform((val) => val === 'true'),
    category: z.string().trim().optional(),
    search: z.string().trim().optional(),
  }),
});

export const stockIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID stok tidak valid'),
  }),
});

export const createStockSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1, 'Nama stok wajib diisi').max(100),
    category: z.string().trim().max(50).default('Topping & Lainnya').optional(),
    currentStock: z.coerce.number().min(0, 'Stok tidak boleh negatif').default(0).optional(),
    minStock: z.coerce.number().min(0, 'Batas minimum tidak boleh negatif').default(0).optional(),
    unit: z.string().trim().max(20).default('kg').optional(),
    costPerUnit: z.coerce.number().min(0).default(0).optional(),
    supplier: z.string().trim().max(100).optional().nullable(),
    note: z.string().trim().max(255).optional().nullable(),
  }),
});

export const updateStockSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID stok tidak valid'),
  }),
  body: z.object({
    name: z.string().trim().min(1, 'Nama stok tidak boleh kosong').max(100).optional(),
    category: z.string().trim().max(50).optional(),
    currentStock: z.coerce.number().min(0).optional(),
    minStock: z.coerce.number().min(0).optional(),
    unit: z.string().trim().max(20).optional(),
    costPerUnit: z.coerce.number().min(0).optional(),
    supplier: z.string().trim().max(100).optional().nullable(),
    note: z.string().trim().max(255).optional().nullable(),
  }),
});

export const adjustStockSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID stok tidak valid'),
  }),
  body: z.object({
    type: z.nativeEnum(StockLogType, {
      message: 'Tipe mutasi harus IN atau OUT',
    }),
    quantity: z.coerce.number().positive('Jumlah mutasi harus lebih dari 0'),
    source: z.nativeEnum(StockLogSource).default(StockLogSource.MANUAL).optional(),
    note: z.string().trim().max(255).optional().nullable(),
    reason: z.string().trim().max(255).optional().nullable(),
  }),
});

export const restockSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID stok tidak valid'),
  }),
  body: z.object({
    quantity: z.coerce.number().positive('Jumlah restock harus lebih dari 0'),
    cost_per_unit: z.coerce.number().min(0).optional(),
    costPerUnit: z.coerce.number().min(0).optional(),
    supplier: z.string().trim().max(100).optional().nullable(),
    note: z.string().trim().max(255).optional().nullable(),
    recordExpense: z.boolean().default(false).optional(),
  }),
});

export type ListStockQuery = z.infer<typeof listStockQuerySchema>['query'];
export type CreateStockDTO = z.infer<typeof createStockSchema>['body'];
export type UpdateStockDTO = z.infer<typeof updateStockSchema>['body'];
export type AdjustStockDTO = z.infer<typeof adjustStockSchema>['body'];
export type RestockDTO = z.infer<typeof restockSchema>['body'];
