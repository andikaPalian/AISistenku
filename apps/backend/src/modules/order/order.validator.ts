import { z } from 'zod';
import { OrderStatus, OrderType, PaymentMethod } from '@prisma/client';

const orderTypeEnum = z.preprocess((val) => {
  if (typeof val === 'string') {
    const clean = val.toLowerCase().replace(/\s+/g, '');
    if (clean.includes('take') || clean.includes('away')) return OrderType.TakeAway;
    return OrderType.DineIn;
  }
  return val;
}, z.nativeEnum(OrderType));

const paymentMethodEnum = z.preprocess((val) => {
  if (typeof val === 'string') {
    const clean = val.toLowerCase();
    if (clean.includes('qris') || clean.includes('wallet')) return PaymentMethod.QRIS_EWallet;
    if (clean.includes('card') || clean.includes('debit') || clean.includes('credit') || clean.includes('transfer')) {
      return PaymentMethod.DebitCreditCard;
    }
    return PaymentMethod.Cash;
  }
  return val;
}, z.nativeEnum(PaymentMethod));

export const createOrderSchema = z.object({
  body: z.object({
    orderType: orderTypeEnum.default(OrderType.DineIn).optional(),
    tableNumber: z.string().trim().max(30).optional().nullable(),
    customerName: z.string().trim().max(100).optional().nullable(),
    paymentMethod: paymentMethodEnum.default(PaymentMethod.Cash).optional(),
    cashGiven: z.coerce.number().min(0).optional().nullable(),
    items: z
      .array(
        z.object({
          productId: z.string().uuid().optional(),
          product_id: z.string().uuid().optional(),
          productName: z.string().optional(),
          product_name: z.string().optional(),
          variant: z.string().trim().max(50).default('Regular').optional(),
          quantity: z.coerce.number().int().positive('Jumlah pesanan minimal 1'),
          price: z.coerce.number().optional(),
          note: z.string().trim().max(255).optional().nullable(),
        })
      )
      .min(1, 'Pesanan harus memiliki minimal 1 item'),
  }),
});

export const orderIdParamSchema = z.object({
  params: z.object({
    id: z.string().uuid('ID pesanan tidak valid'),
  }),
});

export const listOrdersQuerySchema = z.object({
  query: z.object({
    from: z.string().datetime({ offset: true }).optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
    to: z.string().datetime({ offset: true }).optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
    status: z.nativeEnum(OrderStatus).optional(),
    orderType: orderTypeEnum.optional(),
    page: z.coerce.number().int().positive().default(1).optional(),
    limit: z.coerce.number().int().positive().max(100).default(50).optional(),
  }),
});

export type CreateOrderDTO = z.infer<typeof createOrderSchema>['body'];
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>['query'];
