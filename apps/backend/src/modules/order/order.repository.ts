import { prisma } from '@/config/database.config.js';
import {
  FinanceSource,
  FinanceType,
  Order,
  OrderStatus,
  OrderType,
  PaymentMethod,
  Prisma,
  StockLogSource,
  StockLogType,
} from '@prisma/client';

export interface CreateOrderItemInput {
  productId: string;
  quantity: number;
  variant?: string | null;
  note?: string | null;
  // Fallback in case product details are passed directly
  product_id?: string;
  product_name?: string;
  price?: number;
}

export interface CreateOrderInput {
  orderType?: OrderType;
  tableNumber?: string | null;
  customerName?: string | null;
  paymentMethod?: PaymentMethod | null;
  cashGiven?: number | null;
  items: CreateOrderItemInput[];
}

export interface ListOrdersOptions {
  from?: Date;
  to?: Date;
  status?: OrderStatus;
  orderType?: OrderType;
  limit?: number;
  offset?: number;
}

export const generateOrderCode = async (
  businessId: string,
  tx: Prisma.TransactionClient
): Promise<string> => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
  
  // Hitung jumlah order hari ini untuk urutan
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const count = await tx.order.count({
    where: {
      businessId,
      createdAt: { gte: startOfDay },
    },
  });

  const seq = String(count + 1).padStart(3, '0');
  const code = `ORD-${dateStr}-${seq}`;

  // Double check uniqueness for this business
  const existing = await tx.order.findUnique({
    where: {
      businessId_orderCode: {
        businessId,
        orderCode: code,
      },
    },
  });

  if (existing) {
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    return `ORD-${dateStr}-${seq}-${randomSuffix}`;
  }

  return code;
};

export const createOrderAtomic = async (
  businessId: string,
  userId: string | null,
  input: CreateOrderInput
) => {
  return await prisma.$transaction(async (tx) => {
    // 1. Ambil semua produk terkait untuk snapshot harga & nama
    const productIds = input.items
      .map((i) => i.productId || i.product_id)
      .filter((id): id is string => Boolean(id));

    const products = await tx.product.findMany({
      where: {
        id: { in: productIds },
        businessId,
      },
      include: {
        recipes: {
          include: {
            stock: true,
          },
        },
      },
    });

    const productMap = new Map(products.map((p) => [p.id, p]));

    // 2. Hitung subtotal dan siapkan order items
    let calculatedSubtotal = 0;
    const preparedItems: {
      productId: string;
      productName: string;
      variant: string;
      quantity: number;
      priceAtSale: number;
      subtotal: number;
      note?: string | null;
      recipes: typeof products[0]['recipes'];
    }[] = [];

    for (const item of input.items) {
      const pid = item.productId || item.product_id;
      if (!pid) continue;

      const product = productMap.get(pid);
      if (!product) {
        throw new Error(`Produk dengan ID ${pid} tidak ditemukan dalam bisnis ini`);
      }

      const price = Number(product.price);
      const qty = item.quantity;
      const itemSubtotal = price * qty;
      calculatedSubtotal += itemSubtotal;

      preparedItems.push({
        productId: product.id,
        productName: product.name,
        variant: item.variant ?? product.defaultVariant ?? 'Regular',
        quantity: qty,
        priceAtSale: price,
        subtotal: itemSubtotal,
        note: item.note ?? null,
        recipes: product.recipes,
      });
    }

    if (preparedItems.length === 0) {
      throw new Error('Pesanan harus memiliki setidaknya satu item yang valid');
    }

    const tax = 0;
    const totalAmount = calculatedSubtotal + tax;
    const cashGiven = input.cashGiven ? Number(input.cashGiven) : null;
    const changeAmount = cashGiven && cashGiven >= totalAmount ? cashGiven - totalAmount : 0;

    // 3. Generate Order Code unik per-bisnis
    const orderCode = await generateOrderCode(businessId, tx);

    // 4. Buat Order dan OrderItems
    const order = await tx.order.create({
      data: {
        businessId,
        orderCode,
        userId,
        orderType: input.orderType ?? OrderType.DineIn,
        tableNumber: input.tableNumber ?? null,
        customerName: input.customerName ?? null,
        subtotal: calculatedSubtotal,
        tax,
        totalAmount,
        paymentMethod: input.paymentMethod ?? PaymentMethod.Cash,
        cashGiven,
        changeAmount,
        status: OrderStatus.PAID,
        items: {
          create: preparedItems.map((item) => ({
            productId: item.productId,
            productName: item.productName,
            variant: item.variant,
            quantity: item.quantity,
            priceAtSale: item.priceAtSale,
            subtotal: item.subtotal,
            note: item.note,
          })),
        },
      },
      include: {
        items: true,
      },
    });

    // 5. Deduksi stok otomatis via Bill of Materials (ProductRecipe)
    for (const item of preparedItems) {
      for (const recipe of item.recipes) {
        const requiredQty = Number(recipe.quantityRequired) * item.quantity;

        // Kurangi stok di StockItem
        await tx.stockItem.update({
          where: { id: recipe.stockId },
          data: {
            currentStock: {
              decrement: requiredQty,
            },
          },
        });

        // Catat di StockLog
        await tx.stockLog.create({
          data: {
            stockId: recipe.stockId,
            stockName: recipe.stock.name,
            type: StockLogType.OUT,
            quantity: requiredQty,
            unit: recipe.stock.unit,
            source: StockLogSource.ORDER_DEDUCTION,
            referenceCode: orderCode,
            userId,
            operatorName: 'Sistem POS',
            note: `Deduksi otomatis pesanan ${orderCode} (${item.productName} x${item.quantity})`,
          },
        });
      }
    }

    // 6. Catat transaksi keuangan pemasukan otomatis (FinanceTransaction)
    await tx.financeTransaction.create({
      data: {
        businessId,
        userId,
        orderId: order.id,
        title: `Penjualan Kasir ${orderCode}`,
        type: FinanceType.INCOME,
        category: 'sales',
        amount: totalAmount,
        source: FinanceSource.POS_AUTOMATIC,
        notes: `Transaksi ${order.orderType}${order.tableNumber ? ` - Meja ${order.tableNumber}` : ''}${
          order.customerName ? ` (${order.customerName})` : ''
        }`,
      },
    });

    return order;
  });
};

export const findOrdersByBusinessId = async (
  businessId: string,
  options?: ListOrdersOptions
): Promise<{ orders: Order[]; total: number }> => {
  const where: Prisma.OrderWhereInput = {
    businessId,
  };

  if (options?.from || options?.to) {
    where.createdAt = {};
    if (options.from) where.createdAt.gte = options.from;
    if (options.to) where.createdAt.lte = options.to;
  }

  if (options?.status) {
    where.status = options.status;
  }

  if (options?.orderType) {
    where.orderType = options.orderType;
  }

  const [orders, total] = await Promise.all([
    prisma.order.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: options?.offset ?? 0,
      take: options?.limit ?? 50,
      include: {
        items: true,
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    }),
    prisma.order.count({ where }),
  ]);

  return { orders, total };
};

export const findOrderById = async (
  id: string,
  businessId: string
): Promise<Order | null> => {
  return await prisma.order.findFirst({
    where: { id, businessId },
    include: {
      items: true,
      user: {
        select: {
          id: true,
          name: true,
        },
      },
      financeTransactions: true,
    },
  });
};
