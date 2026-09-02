import { useCallback, useState } from 'react';
import type { Product, Transaction, StockAlert, AiChatMessage, CartItem } from '../types';

// ── 1. MOCK PRODUCT DATA (F&B / Cafe) ─────────────────────────
const INITIAL_PRODUCTS: Product[] = [
  { id: '1', code: 'CF-001', name: 'Iced Latte', category: 'Kopi', price: 15000, stock: 42, minStock: 15, unit: 'cup', image: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&auto=format&fit=crop&q=80' },
  { id: '2', code: 'CF-002', name: 'Americano', category: 'Kopi', price: 18000, stock: 35, minStock: 12, unit: 'cup', image: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=80' },
  { id: '3', code: 'CF-003', name: 'Cappuccino', category: 'Kopi', price: 20000, stock: 25, minStock: 10, unit: 'cup', image: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500&auto=format&fit=crop&q=80' },
  { id: '4', code: 'NK-001', name: 'Chocolate Ice', category: 'Non-Kopi', price: 17000, stock: 20, minStock: 10, unit: 'cup', image: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500&auto=format&fit=crop&q=80' },
  { id: '5', code: 'NK-002', name: 'Matcha Latte', category: 'Non-Kopi', price: 20000, stock: 18, minStock: 8, unit: 'cup', image: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&auto=format&fit=crop&q=80' },
  { id: '6', code: 'SN-001', name: 'Croissant Butter', category: 'Snack', price: 15000, stock: 14, minStock: 6, unit: 'pcs', image: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&auto=format&fit=crop&q=80' },
  { id: '7', code: 'FD-001', name: 'Avocado Toast', category: 'Makanan', price: 25000, stock: 10, minStock: 5, unit: 'porsi', image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500&auto=format&fit=crop&q=80' },
  { id: '8', code: 'SN-002', name: 'Blueberry Muffin', category: 'Snack', price: 18000, stock: 12, minStock: 5, unit: 'pcs', image: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=500&auto=format&fit=crop&q=80' },
  { id: '9', code: 'FD-002', name: 'Beef Pie', category: 'Makanan', price: 30000, stock: 8, minStock: 4, unit: 'porsi', image: 'https://images.unsplash.com/photo-1621236378699-8597faf6a173?w=500&auto=format&fit=crop&q=80' },
  { id: '10', code: 'SN-003', name: 'Cheese Danish', category: 'Snack', price: 22000, stock: 9, minStock: 5, unit: 'pcs', image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=80' },
  { id: '11', code: 'FD-003', name: 'Club Sandwich', category: 'Makanan', price: 35000, stock: 6, minStock: 4, unit: 'porsi', image: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&auto=format&fit=crop&q=80' },
  { id: '12', code: 'FD-004', name: 'Tuna Melt', category: 'Makanan', price: 28000, stock: 7, minStock: 4, unit: 'porsi', image: 'https://images.unsplash.com/photo-1619860860774-1e2e17343432?w=500&auto=format&fit=crop&q=80' },
];

// ── 2. MOCK STOCK / INGREDIENT DATA ───────────────────────────
const INITIAL_STOCKS: Product[] = [
  { id: 'ing-1', code: 'ING-001', name: 'Gula Aren Organik', category: 'Bahan Baku', price: 28000, stock: 1, minStock: 5, unit: 'kg' },
  { id: 'ing-2', code: 'ING-002', name: 'Susu UHT Full Cream', category: 'Bahan Baku', price: 24000, stock: 3, minStock: 8, unit: 'liter' },
  { id: 'ing-3', code: 'ING-003', name: 'Paper Cup 16oz', category: 'Kemasan', price: 650, stock: 45, minStock: 100, unit: 'pcs' },
  { id: 'ing-4', code: 'ING-004', name: 'Biji Kopi Arabika House Blend', category: 'Bahan Baku', price: 185000, stock: 5, minStock: 2, unit: 'kg' },
  { id: 'ing-5', code: 'ING-005', name: 'Bubuk Matcha Uji Premium', category: 'Bahan Baku', price: 220000, stock: 4, minStock: 2, unit: 'kg' },
  { id: 'ing-6', code: 'ING-006', name: 'Cokelat Bubuk Belgia', category: 'Bahan Baku', price: 140000, stock: 6, minStock: 3, unit: 'kg' },
  { id: 'ing-7', code: 'ING-007', name: 'Mentega Elle & Vire', category: 'Bahan Baku', price: 95000, stock: 2, minStock: 4, unit: 'kg' },
  { id: 'ing-8', code: 'ING-008', name: 'Sirup Vanilla Monin', category: 'Bahan Baku', price: 165000, stock: 8, minStock: 3, unit: 'botol' },
  { id: 'ing-9', code: 'ING-009', name: 'Sedotan Kertas Eco', category: 'Kemasan', price: 150, stock: 250, minStock: 100, unit: 'pcs' },
];

// ── 3. MOCK TRANSACTIONS ──────────────────────────────────────
const INITIAL_TRANSACTIONS: Transaction[] = [
  {
    id: 'tx-1',
    invoiceNo: 'INV/20260902/001',
    date: '02 Sep 2026',
    time: '14:32',
    type: 'sale',
    category: 'Penjualan Kasir',
    amount: 55000,
    paymentMethod: 'qris',
    status: 'success',
    itemCount: 3,
    notes: 'Dine In • Meja 04'
  },
  {
    id: 'tx-2',
    invoiceNo: 'INV/20260902/002',
    date: '02 Sep 2026',
    time: '13:15',
    type: 'sale',
    category: 'Penjualan Kasir',
    amount: 72000,
    paymentMethod: 'cash',
    status: 'success',
    itemCount: 3,
    notes: 'Take Away'
  },
  {
    id: 'tx-3',
    invoiceNo: 'EXP/20260902/001',
    date: '02 Sep 2026',
    time: '10:00',
    type: 'expense',
    category: 'Kulakan Bahan',
    amount: 420000,
    paymentMethod: 'transfer',
    status: 'success',
    notes: 'Restock Biji Kopi Arabika 5kg & Susu UHT 12L'
  },
  {
    id: 'tx-4',
    invoiceNo: 'INV/20260902/003',
    date: '02 Sep 2026',
    time: '09:40',
    type: 'sale',
    category: 'Penjualan Kasir',
    amount: 85000,
    paymentMethod: 'qris',
    status: 'success',
    itemCount: 3,
    notes: 'Dine In • Meja 02'
  },
  {
    id: 'tx-5',
    invoiceNo: 'EXP/20260901/002',
    date: '01 Sep 2026',
    time: '09:20',
    type: 'expense',
    category: 'Operasional Toko',
    amount: 180000,
    paymentMethod: 'transfer',
    status: 'success',
    notes: 'Gas Elpiji & Sedotan Kertas'
  },
  {
    id: 'tx-6',
    invoiceNo: 'INV/20260901/045',
    date: '01 Sep 2026',
    time: '19:40',
    type: 'sale',
    category: 'Penjualan Kasir',
    amount: 110000,
    paymentMethod: 'qris',
    status: 'success',
    itemCount: 4,
    notes: 'Take Away'
  }
];

// ── 4. MOCK STOCK ALERTS ──────────────────────────────────────
const INITIAL_ALERTS: StockAlert[] = [
  { id: 'alt-1', productName: 'Gula Aren Organik', currentStock: 1, minStock: 5, unit: 'kg', urgency: 'high' },
  { id: 'alt-2', productName: 'Susu UHT Full Cream', currentStock: 3, minStock: 8, unit: 'liter', urgency: 'high' },
  { id: 'alt-3', productName: 'Paper Cup 16oz', currentStock: 45, minStock: 100, unit: 'pcs', urgency: 'medium' }
];

// ── 5. MOCK AI MESSAGES ───────────────────────────────────────
const INITIAL_AI_MESSAGES: AiChatMessage[] = [
  {
    id: 'msg-1',
    sender: 'ai',
    text: 'Halo Pak Budi! Saya **AIsistenku**, AI Copilot Bisnis Toko Tiga Angkatan 🤖.\n\nPenjualan hari ini berjalan sangat lancar. **Iced Latte** menjadi produk terlaris dengan **42 cup terjual**, namun stok **Gula Aren** dan **Susu UHT** mulai menipis.\n\nAda yang bisa saya bantu untuk analisis omzet atau strategi promosi hari ini?',
    timestamp: '14:00',
    recommendations: [
      { title: 'Periksa Stok Bahan Menipis', actionText: 'Ke Menu Stok', actionTab: 'stock' },
      { title: 'Lihat Ringkasan Omzet Hari Ini', actionText: 'Ke Keuangan', actionTab: 'finance' }
    ]
  }
];

// ── GLOBAL SHARED MOCK STATE ──────────────────────────────────
let productsStore = [...INITIAL_PRODUCTS];
let stocksStore = [...INITIAL_STOCKS];
let transactionsStore = [...INITIAL_TRANSACTIONS];
let alertsStore = [...INITIAL_ALERTS];
let aiMessagesStore = [...INITIAL_AI_MESSAGES];

// ── HOOK: USE PRODUCTS ────────────────────────────────────────
export function useProducts() {
  const [data, setData] = useState<Product[]>(productsStore);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setData([...productsStore]);
  }, []);

  const createOrder = useCallback(async (payload: {
    items: CartItem[];
    paymentMethod: 'qris' | 'cash' | 'transfer';
    orderType: string;
    customerName?: string;
    tableNumber?: string;
    cashGiven: number;
    change: number;
  }) => {
    const totalAmount = payload.items.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
    const orderNo = `INV/${new Date().toISOString().slice(0, 10).replace(/-/g, '')}/${String(transactionsStore.length + 1).padStart(3, '0')}`;

    const newTx: Transaction = {
      id: `tx-${Date.now()}`,
      invoiceNo: orderNo,
      date: '02 Sep 2026',
      time: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      type: 'sale',
      category: 'Penjualan Kasir',
      amount: totalAmount,
      paymentMethod: payload.paymentMethod,
      status: 'success',
      itemCount: payload.items.length,
      notes: `${payload.orderType}${payload.tableNumber ? ` • Meja ${payload.tableNumber}` : ''}`
    };

    transactionsStore = [newTx, ...transactionsStore];
    return { order_id: newTx.id, order_code: orderNo, total_amount: totalAmount };
  }, []);

  return { data, loading, error: null, refresh, setData, createOrder };
}

// ── HOOK: USE STOCKS ──────────────────────────────────────────
export function useStocks() {
  const [data, setData] = useState<Product[]>(stocksStore);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setData([...stocksStore]);
  }, []);

  const restock = useCallback(async (stockId: string, body: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }) => {
    stocksStore = stocksStore.map((item) => {
      if (item.id === stockId) {
        return { ...item, stock: item.stock + (body.quantity || 10) };
      }
      return item;
    });

    alertsStore = alertsStore.filter((alt) => {
      const updated = stocksStore.find((s) => s.name === alt.productName);
      return updated ? updated.stock <= updated.minStock : false;
    });

    setData([...stocksStore]);
    return stocksStore.find((s) => s.id === stockId);
  }, []);

  const adjust = useCallback(async (stockId: string, body: { actual_quantity: number; reason?: string; note?: string }) => {
    stocksStore = stocksStore.map((item) => {
      if (item.id === stockId) {
        return { ...item, stock: body.actual_quantity };
      }
      return item;
    });
    setData([...stocksStore]);
    return stocksStore.find((s) => s.id === stockId);
  }, []);

  const create = useCallback(async (body: {
    name: string;
    category: string;
    price: number; // Harga Modal / Beli
    sellingPrice?: number; // Harga Jual POS
    stock: number;
    minStock: number;
    unit: string;
    code?: string;
    isPosProduct?: boolean;
    image?: string;
  }) => {
    const isPOS = body.isPosProduct || ['Kopi', 'Non-Kopi', 'Snack', 'Makanan'].includes(body.category);
    const codePrefix = isPOS ? (body.category === 'Kopi' ? 'CF' : body.category === 'Non-Kopi' ? 'NK' : body.category === 'Makanan' ? 'FD' : 'SN') : 'ING';

    const newItem: Product = {
      id: `item-${Date.now()}`,
      code: body.code || `${codePrefix}-${String(stocksStore.length + 1).padStart(3, '0')}`,
      name: body.name,
      category: body.category,
      price: body.price,
      stock: Number(body.stock) || 0,
      minStock: Number(body.minStock) || 5,
      unit: body.unit || 'pcs',
      image: body.image || (isPOS ? 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&auto=format&fit=crop&q=80' : undefined)
    };

    stocksStore = [newItem, ...stocksStore];
    setData([...stocksStore]);

    // If marked as POS product, also add to productsStore
    if (isPOS) {
      const posItem: Product = {
        id: `pos-${newItem.id}`,
        code: newItem.code,
        name: newItem.name,
        category: newItem.category === 'Bahan Baku' || newItem.category === 'Kemasan' ? 'Snack' : newItem.category,
        price: body.sellingPrice || (body.price > 0 ? body.price : 15000),
        stock: newItem.stock,
        minStock: newItem.minStock,
        unit: newItem.unit,
        image: newItem.image || 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&auto=format&fit=crop&q=80'
      };
      productsStore = [posItem, ...productsStore];
    }

    return newItem;
  }, []);

  const update = useCallback(async (stockId: string, body: Partial<Product> & { sellingPrice?: number }) => {
    stocksStore = stocksStore.map((item) => {
      if (item.id === stockId) {
        return { ...item, ...body };
      }
      return item;
    });

    // Also sync to productsStore if it exists there
    productsStore = productsStore.map((p) => {
      if (p.id === stockId || p.id === `pos-${stockId}` || p.name === body.name) {
        return {
          ...p,
          name: body.name || p.name,
          category: body.category || p.category,
          price: body.sellingPrice || body.price || p.price,
          stock: body.stock !== undefined ? body.stock : p.stock,
          minStock: body.minStock !== undefined ? body.minStock : p.minStock,
          unit: body.unit || p.unit,
          image: body.image || p.image
        };
      }
      return p;
    });

    setData([...stocksStore]);
    return stocksStore.find((s) => s.id === stockId);
  }, []);

  const remove = useCallback(async (stockId: string) => {
    stocksStore = stocksStore.filter((item) => item.id !== stockId);
    productsStore = productsStore.filter((item) => item.id !== stockId && item.id !== `pos-${stockId}`);
    setData([...stocksStore]);
  }, []);

  return { data, loading, error: null, refresh, setData, restock, adjust, create, update, remove };
}

// ── HOOK: USE TRANSACTIONS ────────────────────────────────────
export function useTransactions(_query?: { type?: string; q?: string }) {
  const [data, setData] = useState<Transaction[]>(transactionsStore);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setData([...transactionsStore]);
  }, []);

  const create = useCallback(async (body: { title: string; type: 'INCOME' | 'EXPENSE'; category: string; amount: number; notes?: string; source?: string }) => {
    const newTx: Transaction = {
      id: `tx-${Date.now()}`,
      invoiceNo: `EXP/${new Date().toISOString().slice(0, 10).replace(/-/g, '')}/${String(transactionsStore.length + 1).padStart(3, '0')}`,
      date: '02 Sep 2026',
      time: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      type: body.type === 'INCOME' ? 'income' : 'expense',
      category: body.category,
      amount: body.amount,
      paymentMethod: 'transfer',
      status: 'success',
      notes: body.notes || body.title
    };
    transactionsStore = [newTx, ...transactionsStore];
    setData([...transactionsStore]);
  }, []);

  const remove = useCallback(async (id: string) => {
    transactionsStore = transactionsStore.filter((tx) => tx.id !== id);
    setData([...transactionsStore]);
  }, []);

  return { data, loading, error: null, refresh, setData, create, remove };
}

// ── HOOK: USE DASHBOARD ───────────────────────────────────────
export function useDashboard() {
  const [data, setData] = useState<any>({
    dailyRevenue: { amount: 1250000, percentChange: 12.0 },
    dailyActivity: {
      transactionCount: 32,
      percentChange: 18.0,
      bestSellerName: 'Iced Latte',
      bestSellerQty: 42,
      bestSellerUnit: 'cup'
    },
    lowStockAlertsCount: 3,
    aiInsight: {
      message: 'Penjualan hari ini berjalan sangat lancar. Iced Latte saat ini menjadi produk terlaris (42 cup), namun stok Gula Aren dan Susu UHT mulai menipis.',
      timestamp: '14:00'
    }
  });
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    const totalSales = transactionsStore
      .filter((t) => t.type === 'sale' || t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    setData({
      dailyRevenue: { amount: totalSales || 1250000, percentChange: 12.0 },
      dailyActivity: {
        transactionCount: transactionsStore.filter((t) => t.type === 'sale').length || 32,
        percentChange: 18.0,
        bestSellerName: 'Iced Latte',
        bestSellerQty: 42,
        bestSellerUnit: 'cup'
      },
      lowStockAlertsCount: alertsStore.length,
      aiInsight: {
        message: 'Penjualan hari ini berjalan sangat lancar. Iced Latte saat ini menjadi produk terlaris (42 cup), namun stok Gula Aren dan Susu UHT mulai menipis.',
        timestamp: '14:00'
      }
    });
  }, []);

  return { data, loading, error: null, refresh };
}

// ── HOOK: USE AI MESSAGES ─────────────────────────────────────
export function useAiMessages() {
  const [data, setData] = useState<AiChatMessage[]>(aiMessagesStore);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setData([...aiMessagesStore]);
  }, []);

  const send = useCallback(async (text: string) => {
    const userMsg: AiChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    };

    let replyText = 'Halo! Saya **AIsistenku**. Data omzet dan performa toko Anda hari ini terpantau sangat baik.';
    let recommendations: any[] = [];
    const lower = text.toLowerCase();

    if (lower.includes('restock') || lower.includes('stok') || lower.includes('habis')) {
      replyText =
        '⚠️ **Diagnosa Restock Bahan Baku Cafe Tiga Angkatan**:\n\n' +
        '1. **Gula Aren Organik**: Sisa **1 kg** (Batas aman: 5 kg) — *Estimasi habis: 4 jam*\n' +
        '2. **Susu UHT Full Cream**: Sisa **3 liter** (Batas aman: 8 liter) — *Estimasi habis: 6 jam*\n' +
        '3. **Paper Cup 16oz**: Sisa **45 pcs** (Batas aman: 100 pcs) — *Estimasi habis: 12 jam*\n\n' +
        '💡 **Saran AI**: Pesan 1 dus susu UHT (12 liter) dan 10 kg gula aren sekarang untuk mengantisipasi lonjakan sore.';
      recommendations = [{ title: 'Periksa Menu Stok', actionText: 'Ke Stok Bahan', actionTab: 'stock' }];
    } else if (lower.includes('omzet') || lower.includes('laba') || lower.includes('margin')) {
      replyText =
        '📊 **Laporan Profitabilitas & Margin Hari Ini**:\n\n' +
        '• **Total Omzet**: Rp 1.250.000 (+12% vs kemarin)\n' +
        '• **Estimasi Laba Bersih**: Rp 830.000 (Gross Margin: **66.4%**)\n' +
        '• **Menu Terlaris**: Iced Latte (42 cup terjual hari ini).';
      recommendations = [{ title: 'Lihat Arus Kas Lengkap', actionText: 'Ke Keuangan', actionTab: 'finance' }];
    } else if (lower.includes('promo') || lower.includes('whatsapp') || lower.includes('caption')) {
      replyText =
        '📣 **Draf Promo WhatsApp & Instagram Siap Pakai**:\n\n' +
        '☕ *PROMO NGOPI HEMAT - CAFE TIGA ANGKATAN* ☕\n\n' +
        'Hai Sahabat Setia Tiga Angkatan! Mau booster semangat hari ini?\n\n' +
        '🔥 *Paket Spesial Hari Ini*:\n' +
        '✅ Iced Latte + Croissant Butter -> Cuma Rp 25.000\n' +
        '✅ Matcha Latte Oatmilk -> Cuma Rp 18.000\n\n' +
        '📍 Alamat: Jl. Pemuda No. 45\n' +
        '📱 Pesan: wa.me/6281234567890';
      recommendations = [{ title: 'Buka Kasir POS', actionText: 'Ke POS Kasir', actionTab: 'pos' }];
    }

    const aiMsg: AiChatMessage = {
      id: `ai-${Date.now() + 1}`,
      sender: 'ai',
      text: replyText,
      timestamp: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      recommendations
    };

    aiMessagesStore = [...aiMessagesStore, userMsg, aiMsg];
    setData([...aiMessagesStore]);
    return { user: userMsg, ai: aiMsg };
  }, []);

  const confirmAction = useCallback(async (_actionId: string): Promise<void> => {
    return;
  }, []);

  const clear = useCallback(async () => {
    aiMessagesStore = [INITIAL_AI_MESSAGES[0]];
    setData([...aiMessagesStore]);
  }, []);

  return { data, loading, error: null, refresh, send, confirmAction, clear };
}

// ── HOOK: USE STOCK ALERTS ────────────────────────────────────
export function useStockAlerts() {
  const [data, setData] = useState<StockAlert[]>(alertsStore);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setData([...alertsStore]);
  }, []);

  return { data, loading, refresh };
}
