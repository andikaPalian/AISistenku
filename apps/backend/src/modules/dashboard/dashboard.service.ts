import { prisma } from '@/config/database.config.js';
import { FinanceType, OrderStatus } from '@prisma/client';

export const getDashboardSummary = async (businessId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const [
    todayOrders,
    todayExpenses,
    todayRefunds,
    todayRecordedIncomes,
    monthIncomes,
    monthExpenses,
    allStocks,
  ] = await Promise.all([
    // 1. Transaksi penjualan hari ini
    prisma.order.findMany({
      where: {
        businessId,
        createdAt: { gte: startOfToday },
        status: OrderStatus.PAID,
      },
      select: {
        totalAmount: true,
      },
    }),

    // 2. Pengeluaran operasional hari ini (excluding refund)
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startOfToday },
        type: FinanceType.EXPENSE,
        category: { not: 'refund' },
      },
      _sum: {
        amount: true,
      },
    }),

    // 2b. Total refund hari ini
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startOfToday },
        category: 'refund',
      },
      _sum: {
        amount: true,
      },
      _count: {
        id: true,
      },
    }),

    // 2c. Total penjualan kotor tercatat hari ini
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startOfToday },
        type: FinanceType.INCOME,
      },
      _sum: {
        amount: true,
      },
    }),

    // 3. Pemasukan bulan ini
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startOfMonth },
        type: FinanceType.INCOME,
      },
      _sum: {
        amount: true,
      },
    }),

    // 4. Pengeluaran bulan ini
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startOfMonth },
        type: FinanceType.EXPENSE,
      },
      _sum: {
        amount: true,
      },
    }),

    // 5. Stok barang
    prisma.stockItem.findMany({
      where: { businessId },
      select: {
        id: true,
        name: true,
        category: true,
        currentStock: true,
        minStock: true,
        unit: true,
        costPerUnit: true,
      },
    }),
  ]);

  const todayRevenue = todayOrders.reduce(
    (sum, order) => sum + Number(order.totalAmount),
    0
  );
  const todayOrdersCount = todayOrders.length;
  const todayExpense = Number(todayExpenses._sum.amount ?? 0);
  const todayRefundAmount = Number(todayRefunds._sum.amount ?? 0);
  const todayRefundCount = todayRefunds._count.id;
  const recordedGross = Number(todayRecordedIncomes._sum.amount ?? 0);
  const todayGrossRevenue = Math.max(recordedGross, todayRevenue + todayRefundAmount);

  const monthRevenue = Number(monthIncomes._sum.amount ?? 0);
  const monthExpense = Number(monthExpenses._sum.amount ?? 0);
  const netProfitMonth = monthRevenue - monthExpense;

  const criticalStockItems = allStocks
    .filter((s) => Number(s.currentStock) <= Number(s.minStock))
    .map((s) => ({
      ...s,
      currentStock: Number(s.currentStock),
      minStock: Number(s.minStock),
      costPerUnit: Number(s.costPerUnit),
    }));

  return {
    todayRevenue,
    todayGrossRevenue,
    todayRefundAmount,
    todayRefundCount,
    todayOrdersCount,
    todayExpense,
    monthRevenue,
    monthExpense,
    netProfitMonth,
    criticalStockCount: criticalStockItems.length,
    criticalStockItems,
    // Aliases for compatibility with various frontend representations
    today_sales: todayRevenue,
    today_gross_sales: todayGrossRevenue,
    today_orders: todayOrdersCount,
    total_sales: monthRevenue,
    critical_stocks: criticalStockItems,
  };
};

export const getSalesTrend = async (
  businessId: string,
  range: '7d' | '30d' | '90d' = '7d'
) => {
  const days = range === '90d' ? 90 : range === '30d' ? 30 : 7;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - (days - 1));
  startDate.setHours(0, 0, 0, 0);

  const orders = await prisma.order.findMany({
    where: {
      businessId,
      createdAt: { gte: startDate },
      status: OrderStatus.PAID,
    },
    select: {
      totalAmount: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'asc' },
  });

  // Siapkan map hari lengkap dengan default 0
  const trendMap = new Map<string, { date: string; totalSales: number; totalOrders: number }>();
  for (let i = 0; i < days; i++) {
    const d = new Date(startDate);
    d.setDate(d.getDate() + i);
    const key = d.toISOString().slice(0, 10);
    trendMap.set(key, { date: key, totalSales: 0, totalOrders: 0 });
  }

  for (const order of orders) {
    const key = order.createdAt.toISOString().slice(0, 10);
    const existing = trendMap.get(key);
    if (existing) {
      existing.totalSales += Number(order.totalAmount);
      existing.totalOrders += 1;
    }
  }

  return Array.from(trendMap.values());
};

export const getTopProducts = async (
  businessId: string,
  range: '7d' | '30d' | '90d' = '7d',
  limit = 5
) => {
  const days = range === '90d' ? 90 : range === '30d' ? 30 : 7;
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - (days - 1));
  startDate.setHours(0, 0, 0, 0);

  const orderItems = await prisma.orderItem.findMany({
    where: {
      order: {
        businessId,
        createdAt: { gte: startDate },
        status: OrderStatus.PAID,
      },
    },
    select: {
      productId: true,
      productName: true,
      quantity: true,
      subtotal: true,
    },
  });

  const productAggMap = new Map<
    string,
    { productId: string; productName: string; totalQuantitySold: number; totalRevenue: number }
  >();

  for (const item of orderItems) {
    const key = item.productId || item.productName || 'Unknown';
    const existing = productAggMap.get(key);
    const qty = item.quantity;
    const rev = Number(item.subtotal);

    if (existing) {
      existing.totalQuantitySold += qty;
      existing.totalRevenue += rev;
    } else {
      productAggMap.set(key, {
        productId: item.productId ?? '',
        productName: item.productName ?? 'Menu',
        totalQuantitySold: qty,
        totalRevenue: rev,
      });
    }
  }

  const sorted = Array.from(productAggMap.values()).sort(
    (a, b) => b.totalQuantitySold - a.totalQuantitySold
  );

  return sorted.slice(0, limit);
};
