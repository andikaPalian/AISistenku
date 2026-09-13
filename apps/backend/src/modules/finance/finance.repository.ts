import { prisma } from '@/config/database.config.js';
import { FinanceSource, FinanceTransaction, FinanceType, Prisma } from '@prisma/client';

export interface CreateFinanceTransactionInput {
  title: string;
  type: FinanceType;
  category: string;
  amount: number | Prisma.Decimal;
  notes?: string | null;
  source?: FinanceSource;
  orderId?: string | null;
  userId?: string | null;
}

export interface ListFinanceTransactionsOptions {
  type?: FinanceType;
  category?: string;
  query?: string;
  from?: Date;
  to?: Date;
  limit?: number;
  offset?: number;
}

export const createFinanceTransaction = async (
  businessId: string,
  data: CreateFinanceTransactionInput
): Promise<FinanceTransaction> => {
  return await prisma.financeTransaction.create({
    data: {
      businessId,
      userId: data.userId ?? null,
      orderId: data.orderId ?? null,
      title: data.title,
      type: data.type,
      category: data.category,
      amount: data.amount,
      source: data.source ?? FinanceSource.MANUAL,
      notes: data.notes ?? null,
    },
  });
};

export const findFinanceTransactionsByBusinessId = async (
  businessId: string,
  options?: ListFinanceTransactionsOptions
): Promise<{ transactions: FinanceTransaction[]; total: number }> => {
  const where: Prisma.FinanceTransactionWhereInput = {
    businessId,
  };

  if (options?.type) {
    where.type = options.type;
  }

  if (options?.category) {
    where.category = {
      contains: options.category,
      mode: 'insensitive',
    };
  }

  if (options?.query) {
    where.OR = [
      { title: { contains: options.query, mode: 'insensitive' } },
      { notes: { contains: options.query, mode: 'insensitive' } },
    ];
  }

  if (options?.from || options?.to) {
    where.timestamp = {};
    if (options.from) where.timestamp.gte = options.from;
    if (options.to) where.timestamp.lte = options.to;
  }

  const [transactions, total] = await Promise.all([
    prisma.financeTransaction.findMany({
      where,
      orderBy: { timestamp: 'desc' },
      skip: options?.offset ?? 0,
      take: options?.limit ?? 50,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        order: {
          select: {
            id: true,
            status: true,
            orderCode: true,
          },
        },
      },
    }),
    prisma.financeTransaction.count({ where }),
  ]);

  return { transactions: transactions as any, total };
};

export const findFinanceTransactionById = async (
  id: string,
  businessId: string
): Promise<any | null> => {
  return await prisma.financeTransaction.findFirst({
    where: { id, businessId },
    include: {
      user: {
        select: {
          id: true,
          name: true,
        },
      },
      order: {
        select: {
          id: true,
          status: true,
          orderCode: true,
        },
      },
    },
  });
};

export const deleteFinanceTransaction = async (
  id: string,
  businessId: string
): Promise<FinanceTransaction> => {
  return await prisma.financeTransaction.delete({
    where: { id, businessId },
  });
};
