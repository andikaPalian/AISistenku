import { prisma } from '@/config/database.config.js';
import { Prisma, StockItem, StockLog, StockLogSource, StockLogType } from '@prisma/client';

export interface CreateStockItemInput {
  name: string;
  category?: string;
  currentStock?: number | Prisma.Decimal;
  minStock?: number | Prisma.Decimal;
  unit?: string;
  costPerUnit?: number | Prisma.Decimal;
  supplier?: string | null;
  note?: string | null;
}

export interface UpdateStockItemInput {
  name?: string;
  category?: string;
  currentStock?: number | Prisma.Decimal;
  minStock?: number | Prisma.Decimal;
  unit?: string;
  costPerUnit?: number | Prisma.Decimal;
  supplier?: string | null;
  note?: string | null;
}

export interface AdjustStockInput {
  type: StockLogType;
  quantity: number;
  source?: StockLogSource;
  note?: string | null;
  userId?: string | null;
  operatorName?: string | null;
  referenceCode?: string | null;
}

export const findStockItemsByBusinessId = async (
  businessId: string,
  options?: { belowMin?: boolean; category?: string; search?: string }
): Promise<StockItem[]> => {
  const where: Prisma.StockItemWhereInput = {
    businessId,
  };

  if (options?.category) {
    where.category = options.category;
  }

  if (options?.search) {
    where.name = {
      contains: options.search,
      mode: 'insensitive',
    };
  }

  const items = await prisma.stockItem.findMany({
    where,
    orderBy: { name: 'asc' },
  });

  if (options?.belowMin) {
    return items.filter((item) => Number(item.currentStock) <= Number(item.minStock));
  }

  return items;
};

export const findStockItemById = async (
  id: string,
  businessId: string
): Promise<StockItem | null> => {
  return await prisma.stockItem.findFirst({
    where: { id, businessId },
  });
};

export const createStockItem = async (
  businessId: string,
  data: CreateStockItemInput
): Promise<StockItem> => {
  return await prisma.stockItem.create({
    data: {
      businessId,
      name: data.name,
      category: data.category ?? 'Topping & Lainnya',
      currentStock: data.currentStock ?? 0,
      minStock: data.minStock ?? 0,
      unit: data.unit ?? 'kg',
      costPerUnit: data.costPerUnit ?? 0,
      supplier: data.supplier ?? null,
      note: data.note ?? null,
    },
  });
};

export const updateStockItem = async (
  id: string,
  businessId: string,
  data: UpdateStockItemInput
): Promise<StockItem> => {
  return await prisma.stockItem.update({
    where: { id, businessId },
    data,
  });
};

export const deleteStockItem = async (
  id: string,
  businessId: string
): Promise<StockItem> => {
  return await prisma.stockItem.delete({
    where: { id, businessId },
  });
};

export const adjustStock = async (
  stockId: string,
  businessId: string,
  input: AdjustStockInput
): Promise<{ stock: StockItem; log: StockLog }> => {
  return await prisma.$transaction(async (tx) => {
    const stock = await tx.stockItem.findFirst({
      where: { id: stockId, businessId },
    });

    if (!stock) {
      throw new Error('StockItem not found in this business');
    }

    const currentQty = Number(stock.currentStock);
    const changeQty = Number(input.quantity);
    const newQty = input.type === StockLogType.IN ? currentQty + changeQty : Math.max(0, currentQty - changeQty);

    const updatedStock = await tx.stockItem.update({
      where: { id: stockId },
      data: {
        currentStock: newQty,
      },
    });

    const log = await tx.stockLog.create({
      data: {
        stockId,
        stockName: stock.name,
        type: input.type,
        quantity: changeQty,
        unit: stock.unit,
        source: input.source ?? StockLogSource.MANUAL,
        referenceCode: input.referenceCode ?? null,
        userId: input.userId ?? null,
        operatorName: input.operatorName ?? 'Admin',
        note: input.note ?? null,
      },
    });

    return { stock: updatedStock, log };
  });
};

export const findStockLogsByStockId = async (
  stockId: string,
  businessId: string
): Promise<StockLog[]> => {
  // Verifikasi stockId milik businessId
  const stock = await prisma.stockItem.findFirst({
    where: { id: stockId, businessId },
  });

  if (!stock) return [];

  return await prisma.stockLog.findMany({
    where: { stockId },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
};
