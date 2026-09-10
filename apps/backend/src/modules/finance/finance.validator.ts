import { z } from 'zod';
import { FinanceSource, FinanceType } from '@prisma/client';

const financeTypeEnum = z.preprocess((val) => {
  if (typeof val === 'string') return val.toUpperCase();
  return val;
}, z.nativeEnum(FinanceType));

export const createFinanceSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1, 'Judul transaksi wajib diisi').max(100),
    type: financeTypeEnum,
    category: z.string().trim().min(1, 'Kategori transaksi wajib diisi').max(50),
    amount: z.coerce.number().positive('Nominal transaksi harus lebih dari 0'),
    notes: z.string().trim().max(255).optional().nullable(),
    source: z.nativeEnum(FinanceSource).default(FinanceSource.MANUAL).optional(),
  }),
});

export const financeIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID transaksi tidak valid'),
  }),
});

export const listFinanceQuerySchema = z.object({
  query: z.object({
    type: financeTypeEnum.optional(),
    category: z.string().trim().optional(),
    query: z.string().trim().optional(),
    q: z.string().trim().optional(), // Interop with frontend query param
    from: z.string().datetime({ offset: true }).optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
    to: z.string().datetime({ offset: true }).optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
    page: z.coerce.number().int().positive().default(1).optional(),
    limit: z.coerce.number().int().positive().max(100).default(50).optional(),
  }),
});

export type CreateFinanceDTO = z.infer<typeof createFinanceSchema>['body'];
export type ListFinanceQuery = z.infer<typeof listFinanceQuerySchema>['query'];
