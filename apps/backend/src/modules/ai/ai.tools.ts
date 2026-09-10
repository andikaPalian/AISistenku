import { prisma } from '@/config/database.config.js';
import { ActionStatus, FinanceType, OrderStatus } from '@prisma/client';

export const AI_TOOLS_DECLARATIONS = [
  {
    name: 'get_sales',
    description: 'Mengambil data penjualan dan omzet bisnis pada rentang waktu tertentu',
    parameters: {
      type: 'OBJECT',
      properties: {
        range: {
          type: 'STRING',
          description: 'Rentang waktu: "today", "7d", "30d", atau rentang hari lainnya',
        },
      },
      required: ['range'],
    },
  },
  {
    name: 'get_stock',
    description: 'Mengecek ketersediaan dan level stok bahan baku (semua atau item tertentu)',
    parameters: {
      type: 'OBJECT',
      properties: {
        item: {
          type: 'STRING',
          description: 'Nama item bahan baku yang dicari (opsional, kosongkan untuk cek semua)',
        },
      },
    },
  },
  {
    name: 'get_expense',
    description: 'Mengambil ringkasan dan rincian pengeluaran operasional bisnis',
    parameters: {
      type: 'OBJECT',
      properties: {
        range: {
          type: 'STRING',
          description: 'Rentang waktu: "today", "7d", "30d"',
        },
      },
      required: ['range'],
    },
  },
  {
    name: 'add_stock',
    description: 'Mengusulkan penambahan stok bahan baku. Wajib dikonfirmasi oleh pengguna sebelum tersimpan.',
    parameters: {
      type: 'OBJECT',
      properties: {
        item: { type: 'STRING', description: 'Nama item bahan baku' },
        quantity: { type: 'NUMBER', description: 'Jumlah penambahan stok' },
        unit: { type: 'STRING', description: 'Satuan ukuran (mis. kg, L, pcs, btl)' },
      },
      required: ['item', 'quantity', 'unit'],
    },
  },
  {
    name: 'add_expense',
    description: 'Mengusulkan pencatatan transaksi pengeluaran. Wajib dikonfirmasi oleh pengguna sebelum tersimpan.',
    parameters: {
      type: 'OBJECT',
      properties: {
        category: { type: 'STRING', description: 'Kategori pengeluaran (mis. operational, bahan baku, utilitas)' },
        amount: { type: 'NUMBER', description: 'Nominal pengeluaran dalam Rupiah' },
        note: { type: 'STRING', description: 'Catatan tambahan pengeluaran' },
      },
      required: ['category', 'amount'],
    },
  },
  {
    name: 'generate_promo_content',
    description: 'Membuat draf ide promosi atau caption media sosial berdasarkan menu dan konteks bisnis',
    parameters: {
      type: 'OBJECT',
      properties: {
        theme: { type: 'STRING', description: 'Tema atau fokus promo' },
        tone: { type: 'STRING', description: 'Nada bahasa (mis. ramah, santai, persuasif)' },
        platform: { type: 'STRING', description: 'Platform sasaran (mis. instagram, whatsapp, tiktok)' },
      },
      required: ['theme'],
    },
  },
];

export const executeGetSales = async (businessId: string, params: { range: string }) => {
  const days = params.range === 'today' ? 1 : params.range === '30d' ? 30 : 7;
  const startDate = new Date();
  if (params.range === 'today') {
    startDate.setHours(0, 0, 0, 0);
  } else {
    startDate.setDate(startDate.getDate() - days);
  }

  const [incomes, ordersCount] = await Promise.all([
    prisma.financeTransaction.aggregate({
      where: {
        businessId,
        timestamp: { gte: startDate },
        type: FinanceType.INCOME,
      },
      _sum: { amount: true },
    }),
    prisma.order.count({
      where: {
        businessId,
        createdAt: { gte: startDate },
        status: OrderStatus.PAID,
      },
    }),
  ]);

  const totalSales = Number(incomes._sum.amount ?? 0);

  return {
    range: params.range,
    totalSales,
    totalSalesFormatted: `Rp ${totalSales.toLocaleString('id-ID')}`,
    totalOrders: ordersCount,
  };
};

export const executeGetStock = async (businessId: string, params: { item?: string }) => {
  const where: any = { businessId };
  if (params.item) {
    where.name = { contains: params.item, mode: 'insensitive' };
  }

  const items = await prisma.stockItem.findMany({
    where,
    take: 15,
    orderBy: { currentStock: 'asc' },
  });

  return {
    found: items.length,
    stocks: items.map((i) => ({
      name: i.name,
      currentStock: Number(i.currentStock),
      minStock: Number(i.minStock),
      unit: i.unit,
      status:
        Number(i.currentStock) <= 0
          ? 'Habis'
          : Number(i.currentStock) <= Number(i.minStock)
          ? 'Kritis / Menipis'
          : 'Aman',
    })),
  };
};

export const executeGetExpense = async (businessId: string, params: { range: string }) => {
  const days = params.range === 'today' ? 1 : params.range === '30d' ? 30 : 7;
  const startDate = new Date();
  if (params.range === 'today') {
    startDate.setHours(0, 0, 0, 0);
  } else {
    startDate.setDate(startDate.getDate() - days);
  }

  const expenses = await prisma.financeTransaction.findMany({
    where: {
      businessId,
      timestamp: { gte: startDate },
      type: FinanceType.EXPENSE,
    },
    orderBy: { timestamp: 'desc' },
  });

  const totalExpense = expenses.reduce((sum, e) => sum + Number(e.amount), 0);

  return {
    range: params.range,
    totalExpense,
    totalExpenseFormatted: `Rp ${totalExpense.toLocaleString('id-ID')}`,
    count: expenses.length,
    recentExpenses: expenses.slice(0, 5).map((e) => ({
      title: e.title,
      category: e.category,
      amount: Number(e.amount),
      notes: e.notes,
    })),
  };
};

export const executeAddStockProposal = async (
  messageId: string | null,
  params: { item: string; quantity: number; unit: string }
) => {
  const action = await prisma.aiAction.create({
    data: {
      messageId,
      intent: 'add_stock',
      payload: {
        item: params.item,
        quantity: params.quantity,
        unit: params.unit,
      },
      status: ActionStatus.PENDING,
    },
  });

  return {
    type: 'action_confirmation',
    action: {
      id: action.id,
      intent: action.intent,
      payload: action.payload,
      status: action.status,
    },
    message: `Mau saya tambahkan stok ${params.item} sebanyak ${params.quantity} ${params.unit}?`,
  };
};

export const executeAddExpenseProposal = async (
  messageId: string | null,
  params: { category: string; amount: number; note?: string }
) => {
  const action = await prisma.aiAction.create({
    data: {
      messageId,
      intent: 'add_expense',
      payload: {
        category: params.category,
        amount: params.amount,
        note: params.note ?? null,
      },
      status: ActionStatus.PENDING,
    },
  });

  return {
    type: 'action_confirmation',
    action: {
      id: action.id,
      intent: action.intent,
      payload: action.payload,
      status: action.status,
    },
    message: `Mau saya catatkan pengeluaran ${params.category} sebesar Rp ${Number(
      params.amount
    ).toLocaleString('id-ID')}${params.note ? ` (${params.note})` : ''}?`,
  };
};

export const getBusinessProductContext = async (businessId: string) => {
  const products = await prisma.product.findMany({
    where: { businessId, isActive: true },
    select: {
      name: true,
      price: true,
      category: true,
    },
    take: 20,
  });

  return products.map((p) => `${p.name} (Rp ${Number(p.price).toLocaleString('id-ID')})`).join(', ');
};
