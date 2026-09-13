import { prisma } from '@/config/database.config.js';
import { eventBus, LowStockItemAlert } from '@/events/event-bus.js';
import { BadRequestError, NotFoundError } from '@/errors/http.error.js';
import {
  FinanceSource,
  FinanceType,
  Order,
  OrderStatus,
  OrderType,
  PaymentMethod,
  Prisma,
  StockItem,
  StockLogSource,
  StockLogType,
} from '@prisma/client';

export interface CreateOrderItemInput {
  productId?: string;
  quantity: number;
  variant?: string | null;
  note?: string | null;
  // Fallback in case product details are passed directly
  product_id?: string;
  productName?: string;
  product_name?: string;
  name?: string;
  price?: number;
  unit_price?: number;
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
  const result = await prisma.$transaction(async (tx) => {
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
      productId: string | null;
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
      let product = pid ? productMap.get(pid) : null;

      const rawName = (item.productName || item.product_name || (item as any).name || '').trim();

      // 1. Jika tidak ditemukan via ID (misal dibuat offline di HP), cari berdasarkan nama
      if (!product && rawName) {
        product = await tx.product.findFirst({
          where: {
            businessId,
            name: { equals: rawName, mode: 'insensitive' },
          },
          include: {
            recipes: {
              include: {
                stock: true,
              },
            },
          },
        });
      }

      // 2. Jika masih belum ada di DB, auto-create produk baru di tenant ini agar riwayat pesanan tetap tercatat rapi
      if (!product && rawName) {
        const itemPrice = Number(item.price ?? (item as any).unit_price ?? 0);
        product = await tx.product.create({
          data: {
            businessId,
            name: rawName,
            price: itemPrice,
            category: 'FOOD',
            defaultVariant: item.variant ?? 'Regular',
          },
          include: {
            recipes: {
              include: {
                stock: true,
              },
            },
          },
        });
      }

      const itemName = product ? product.name : (rawName || 'Menu');
      const price = product ? Number(product.price) : Number(item.price ?? (item as any).unit_price ?? 0);
      const qty = item.quantity > 0 ? item.quantity : 1;
      const itemSubtotal = price * qty;
      calculatedSubtotal += itemSubtotal;

      preparedItems.push({
        productId: product ? product.id : null,
        productName: itemName,
        variant: item.variant ?? product?.defaultVariant ?? 'Regular',
        quantity: qty,
        priceAtSale: price,
        subtotal: itemSubtotal,
        note: item.note ?? null,
        recipes: product ? product.recipes : [],
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
    const updatedStockMap = new Map<string, StockItem>();

    for (const item of preparedItems) {
      for (const recipe of item.recipes) {
        const requiredQty = Number(recipe.quantityRequired) * item.quantity;

        // Kurangi stok di StockItem
        const updated = await tx.stockItem.update({
          where: { id: recipe.stockId },
          data: {
            currentStock: {
              decrement: requiredQty,
            },
          },
        });

        updatedStockMap.set(recipe.stockId, updated);

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

    // Identifikasi stok yang berada di bawah atau sama dengan minStock
    const lowStockAlerts: LowStockItemAlert[] = [];
    for (const stock of updatedStockMap.values()) {
      const current = Number(stock.currentStock);
      const min = Number(stock.minStock);
      if (current <= min) {
        lowStockAlerts.push({
          stockId: stock.id,
          name: stock.name,
          category: stock.category,
          currentStock: current,
          minStock: min,
          unit: stock.unit,
          severity: current <= min * 0.6 ? 'critical' : 'warning',
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
        notes: `Transaksi ${order.orderType}${
          order.tableNumber
            ? ` - Meja ${order.tableNumber.replace(/^Meja\s*/i, '').trim()}`
            : ''
        }${order.customerName ? ` (${order.customerName})` : ''}`,
      },
    });

    return { order, lowStockAlerts, updatedStocks: Array.from(updatedStockMap.values()) };
  });

  // Emit event ke EventBus setelah transaksi PostgreSQL sukses di-commit
  if (result.lowStockAlerts.length > 0) {
    eventBus.emitStockLowAlert({
      businessId,
      orderCode: result.order.orderCode,
      alerts: result.lowStockAlerts,
      timestamp: new Date().toISOString(),
    });
  }

  for (const stock of result.updatedStocks) {
    eventBus.emitStockMutated({
      businessId,
      stockId: stock.id,
      stockName: stock.name,
      currentStock: Number(stock.currentStock),
      minStock: Number(stock.minStock),
      unit: stock.unit,
      source: 'POS_ORDER',
      type: 'OUT',
      quantity: 0,
      timestamp: new Date().toISOString(),
    });
  }

  return result.order;
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

export interface RefundOrderInput {
  reason?: string | null;
  targetStatus?: OrderStatus;
  restoreStock?: boolean;
  operatorName?: string;
}

export const refundOrderAtomic = async (
  orderId: string,
  businessId: string,
  userId: string | null,
  input: RefundOrderInput
) => {
  const result = await prisma.$transaction(async (tx) => {
    // 1. Ambil pesanan dan validasi keberadaannya di tenant bisnis
    const order = await tx.order.findFirst({
      where: { id: orderId, businessId },
      include: {
        items: {
          include: {
            product: {
              include: {
                recipes: {
                  include: {
                    stock: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundError('Pesanan tidak ditemukan dalam bisnis ini.', 'ORDER_NOT_FOUND');
    }

    if (order.status === OrderStatus.REFUNDED) {
      throw new BadRequestError('Pesanan ini sudah direfund sebelumnya.', 'ORDER_ALREADY_REFUNDED');
    }

    if (order.status === OrderStatus.CANCELLED) {
      throw new BadRequestError('Pesanan ini sudah dibatalkan sebelumnya.', 'ORDER_ALREADY_CANCELLED');
    }

    const targetStatus = input.targetStatus ?? OrderStatus.REFUNDED;
    const shouldRestoreStock = input.restoreStock ?? true;
    const restoredStocks: StockItem[] = [];

    // 2. Rollback stok bahan baku resep
    if (shouldRestoreStock) {
      // Cari log deduksi stok yang tercatat dengan orderCode pesanan ini
      const deductionLogs = await tx.stockLog.findMany({
        where: {
          referenceCode: order.orderCode,
          type: StockLogType.OUT,
          source: StockLogSource.ORDER_DEDUCTION,
        },
      });

      if (deductionLogs.length > 0) {
        for (const log of deductionLogs) {
          const updatedStock = await tx.stockItem.update({
            where: { id: log.stockId },
            data: {
              currentStock: {
                increment: log.quantity,
              },
            },
          });

          restoredStocks.push(updatedStock);

          await tx.stockLog.create({
            data: {
              stockId: log.stockId,
              stockName: log.stockName,
              type: StockLogType.IN,
              quantity: log.quantity,
              unit: log.unit,
              source: StockLogSource.MANUAL,
              referenceCode: order.orderCode,
              userId,
              operatorName: input.operatorName ?? 'Sistem POS (Refund)',
              note: `Rollback stok dari ${targetStatus === OrderStatus.CANCELLED ? 'pembatalan' : 'refund'} pesanan ${order.orderCode}${input.reason ? ` (${input.reason})` : ''}`,
            },
          });
        }
      } else {
        // Fallback: jika log deduksi historis tidak ada, hitung dari resep produk
        for (const item of order.items) {
          if (!item.product?.recipes) continue;
          for (const recipe of item.product.recipes) {
            const requiredQty = Number(recipe.quantityRequired) * item.quantity;
            const updatedStock = await tx.stockItem.update({
              where: { id: recipe.stockId },
              data: {
                currentStock: {
                  increment: requiredQty,
                },
              },
            });

            restoredStocks.push(updatedStock);

            await tx.stockLog.create({
              data: {
                stockId: recipe.stockId,
                stockName: recipe.stock.name,
                type: StockLogType.IN,
                quantity: requiredQty,
                unit: recipe.stock.unit,
                source: StockLogSource.MANUAL,
                referenceCode: order.orderCode,
                userId,
                operatorName: input.operatorName ?? 'Sistem POS (Refund)',
                note: `Rollback stok fallback dari ${targetStatus === OrderStatus.CANCELLED ? 'pembatalan' : 'refund'} pesanan ${order.orderCode}`,
              },
            });
          }
        }
      }
    }

    // 3. Catat Jurnal Balik di Tabel Keuangan (FinanceTransaction)
    const financeTransaction = await tx.financeTransaction.create({
      data: {
        businessId,
        userId,
        orderId: order.id,
        title: `Jurnal Balik / Refund ${order.orderCode}`,
        type: FinanceType.EXPENSE,
        category: 'refund',
        amount: order.totalAmount,
        source: FinanceSource.POS_AUTOMATIC,
        notes: `Jurnal balik ${targetStatus === OrderStatus.CANCELLED ? 'pembatalan' : 'refund'} transaksi ${order.orderCode}${
          input.reason ? ` (Alasan: ${input.reason})` : ''
        }`,
      },
    });

    // 4. Update status Order menjadi REFUNDED / CANCELLED
    const updatedOrder = await tx.order.update({
      where: { id: order.id },
      data: {
        status: targetStatus,
      },
      include: {
        items: true,
        financeTransactions: true,
      },
    });

    return {
      order: updatedOrder,
      restoredStocks,
      financeTransaction,
    };
  });

  // Emit event ke EventBus untuk setiap bahan baku yang dikembalikan
  for (const stock of result.restoredStocks) {
    eventBus.emitStockMutated({
      businessId,
      stockId: stock.id,
      stockName: stock.name,
      currentStock: Number(stock.currentStock),
      minStock: Number(stock.minStock),
      unit: stock.unit,
      source: 'REFUND_ROLLBACK',
      type: 'IN',
      quantity: 0,
      timestamp: new Date().toISOString(),
    });
  }

  return result;
};
