import * as stockRepo from './stock.repository.js';
import { NotFoundError } from '@/errors/http.error.js';
import {
  AdjustStockDTO,
  CreateStockDTO,
  ListStockQuery,
  RestockDTO,
  UpdateStockDTO,
} from './stock.validator.js';
import { FinanceSource, FinanceType, StockLogSource, StockLogType } from '@prisma/client';
import { prisma } from '@/config/database.config.js';
import { eventBus } from '@/events/event-bus.js';

export const listStocks = async (businessId: string, query: ListStockQuery) => {
  return await stockRepo.findStockItemsByBusinessId(businessId, {
    belowMin: query.belowMin,
    category: query.category,
    search: query.search,
  });
};

export const getStockById = async (id: string, businessId: string) => {
  const stock = await stockRepo.findStockItemById(id, businessId);
  if (!stock) {
    throw new NotFoundError('Item stok', 'STOCK_NOT_FOUND');
  }
  return stock;
};

export const createStock = async (businessId: string, input: CreateStockDTO) => {
  return await stockRepo.createStockItem(businessId, input);
};

export const updateStock = async (
  id: string,
  businessId: string,
  input: UpdateStockDTO
) => {
  await getStockById(id, businessId);
  return await stockRepo.updateStockItem(id, businessId, input);
};

export const deleteStock = async (id: string, businessId: string) => {
  await getStockById(id, businessId);
  return await stockRepo.deleteStockItem(id, businessId);
};

export const adjustStock = async (
  id: string,
  businessId: string,
  input: AdjustStockDTO,
  user?: { id: string; name: string }
) => {
  await getStockById(id, businessId);
  const note = input.note || input.reason || null;

  const result = await stockRepo.adjustStock(id, businessId, {
    type: input.type,
    quantity: input.quantity,
    source: input.source ?? StockLogSource.MANUAL,
    note,
    userId: user?.id,
    operatorName: user?.name,
  });

  const current = Number(result.stock.currentStock);
  const min = Number(result.stock.minStock);

  eventBus.emitStockMutated({
    businessId,
    stockId: result.stock.id,
    stockName: result.stock.name,
    currentStock: current,
    minStock: min,
    unit: result.stock.unit,
    source: input.source ?? 'MANUAL_ADJUST',
    type: input.type,
    quantity: input.quantity,
    timestamp: new Date().toISOString(),
  });

  if (current <= min) {
    eventBus.emitStockLowAlert({
      businessId,
      alerts: [
        {
          stockId: result.stock.id,
          name: result.stock.name,
          category: result.stock.category,
          currentStock: current,
          minStock: min,
          unit: result.stock.unit,
          severity: current <= min * 0.6 ? 'critical' : 'warning',
        },
      ],
      timestamp: new Date().toISOString(),
    });
  }

  return result;
};

export const restock = async (
  id: string,
  businessId: string,
  input: RestockDTO,
  user?: { id: string; name: string }
) => {
  const stock = await getStockById(id, businessId);

  const costPerUnit = input.costPerUnit ?? input.cost_per_unit ?? Number(stock.costPerUnit);

  const result = await stockRepo.adjustStock(id, businessId, {
    type: StockLogType.IN,
    quantity: input.quantity,
    source: StockLogSource.RESTOCK,
    note: input.note,
    userId: user?.id,
    operatorName: user?.name,
  });

  if (input.supplier || costPerUnit !== Number(stock.costPerUnit)) {
    await stockRepo.updateStockItem(id, businessId, {
      supplier: input.supplier ?? stock.supplier,
      costPerUnit,
    });
  }

  if (input.recordExpense && costPerUnit > 0) {
    const totalAmount = Number(input.quantity) * Number(costPerUnit);
    await prisma.financeTransaction.create({
      data: {
        businessId,
        userId: user?.id ?? null,
        title: `Restock ${stock.name}`,
        type: FinanceType.EXPENSE,
        category: 'operational',
        amount: totalAmount,
        source: FinanceSource.MANUAL,
        notes: input.note ?? `Pembelian stok ${stock.name} (${input.quantity} ${stock.unit})`,
      },
    });
  }

  const current = Number(result.stock.currentStock);
  const min = Number(result.stock.minStock);

  eventBus.emitStockMutated({
    businessId,
    stockId: result.stock.id,
    stockName: result.stock.name,
    currentStock: current,
    minStock: min,
    unit: result.stock.unit,
    source: 'RESTOCK',
    type: 'IN',
    quantity: input.quantity,
    timestamp: new Date().toISOString(),
  });

  return result.stock;
};

export const getStockLogs = async (id: string, businessId: string) => {
  await getStockById(id, businessId);
  return await stockRepo.findStockLogsByStockId(id, businessId);
};
