import { useCallback, useEffect, useRef, useState } from 'react';
import type { Product, Transaction, StockAlert, AiChatMessage, CartItem } from '../types';
import { apiGet, apiPost, apiPut, apiDelete } from '../lib/api';
import {
  adaptProduct,
  adaptStockItem,
  adaptStockAlert,
  adaptTransaction,
  adaptAiMessage,
  type AdaptedAiMessage,
  type AiMessageRow,
  type FinanceRow,
  type ProductRow,
  type StockItemRow,
} from '../lib/adapters';

// =============================================================
// Generic fetch helper used by every hook.
// =============================================================
function useFetch<T>(path: string | null) {
  const [data, setData] = useState<T>([] as unknown as T);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    if (!path) return;
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<any>(path);
      if (!mountedRef.current) return;
      setData(res as T);
    } catch (e: any) {
      if (!mountedRef.current) return;
      setError(e?.error || 'Gagal memuat data');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, [path]);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  return { data, setData, loading, error, refresh };
}

// =============================================================
// useProducts — POS menu catalog (products table)
// =============================================================
export interface CreateOrderResponse {
  order_id: string;
  order_code: string;
  total_amount: number;
  items: any[];
}

export function useProducts() {
  const [items, setItems] = useState<Product[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<{ products: ProductRow[] }>('/products');
      if (!mountedRef.current) return;
      setItems((res.products || []).map(adaptProduct));
    } catch (e: any) {
      if (mountedRef.current) setError(e?.error || 'Gagal memuat produk');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  const createOrder = useCallback(
    async (payload: {
      items: CartItem[];
      paymentMethod: 'qris' | 'cash' | 'transfer';
      orderType: string;
      customerName?: string;
      tableNumber?: string;
      cashGiven: number;
      change: number;
    }): Promise<CreateOrderResponse> => {
      const itemsPayload = payload.items.map((i) => ({
        product_id: i.product.id,
        product_name: i.product.name,
        variant: 'Regular',
        quantity: i.quantity,
        price: i.product.price,
        subtotal: i.product.price * i.quantity,
      }));
      const subtotal = payload.items.reduce(
        (sum, i) => sum + i.product.price * i.quantity,
        0
      );
      const res = await apiPost<{ message: string; order: any; items: any[] }>(
        '/orders',
        {
          orderType: payload.orderType.split(' • ')[0] || 'Dine In',
          tableNumber: payload.tableNumber || null,
          customerName: payload.customerName || null,
          paymentMethod:
            payload.paymentMethod === 'cash'
              ? 'Cash'
              : payload.paymentMethod === 'qris'
              ? 'QRIS / E-Wallet'
              : 'Transfer Bank',
          items: itemsPayload,
          subtotal,
          tax: 0,
          total: subtotal,
          cashGiven: payload.cashGiven,
          change: payload.change,
        }
      );
      const order = res.order;
      return {
        order_id: order.order_id,
        order_code: order.order_code,
        total_amount: Number(order.total_amount),
        items: res.items,
      };
    },
    []
  );

  return {
    data: items,
    loading,
    error,
    refresh,
    setData: setItems,
    createOrder,
  };
}

// =============================================================
// useStocks — raw materials + POS products
// =============================================================
export function useStocks() {
  const [items, setItems] = useState<(Product & { stockId: string; costPerUnit: number; supplier?: string; status?: string })[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<{ stocks: StockItemRow[] }>('/stocks');
      if (!mountedRef.current) return;
      setItems((res.stocks || []).map(adaptStockItem));
    } catch (e: any) {
      if (mountedRef.current) setError(e?.error || 'Gagal memuat stok');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  const restock = useCallback(
    async (
      stockId: string,
      body: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }
    ) => {
      const res = await apiPost<{ stock: any }>(`/stocks/${stockId}/restock`, {
        quantity: body.quantity,
        cost_per_unit: body.cost_per_unit,
        supplier: body.supplier,
        note: body.note,
        recordExpense: false,
      });
      return res.stock;
    },
    []
  );

  const adjust = useCallback(
    async (
      stockId: string,
      body: { actual_quantity: number; reason?: string; note?: string }
    ) => {
      const res = await apiPost<{ stock: any }>(`/stocks/${stockId}/adjust`, {
        actual_quantity: body.actual_quantity,
        reason: body.reason,
        note: body.note,
      });
      return res.stock;
    },
    []
  );

  const create = useCallback(
    async (body: {
      name: string;
      category: string;
      price: number;
      sellingPrice?: number;
      stock: number;
      minStock: number;
      unit: string;
      code?: string;
      isPosProduct?: boolean;
      image?: string;
    }) => {
      const imageUrl = body.image || null;

      if (body.isPosProduct) {
        await apiPost('/products', {
          name: body.name,
          category: body.category,
          price: body.sellingPrice ?? body.price,
          default_variant: 'Regular',
          image_url: imageUrl,
        });
      }

      const res = await apiPost<{ stock: any }>('/stocks', {
        name: body.name,
        category: body.category,
        current_stock: body.stock,
        min_stock: body.minStock,
        unit: body.unit,
        cost_per_unit: body.price,
        supplier: 'Supplier Utama',
        note: null,
      });
      return res.stock;
    },
    []
  );

  const update = useCallback(
    async (
      stockId: string,
      body: Partial<Product> & { sellingPrice?: number; image?: string; supplier?: string }
    ) => {
      const res = await apiPut<{ stock: any }>(`/stocks/${stockId}`, {
        name: body.name,
        category: body.category,
        min_stock: body.minStock,
        unit: body.unit,
        cost_per_unit: body.price,
        supplier: body.supplier,
        note: (body as any).note,
      });
      if (body.image && body.image.startsWith('https://')) {
        // Best-effort: keep products table in sync if a category update also affects POS menu
        await apiPut(`/products/${stockId}`, { image_url: body.image }).catch(() => null);
      }
      return res.stock;
    },
    []
  );

  const remove = useCallback(async (stockId: string) => {
    await apiDelete(`/stocks/${stockId}`);
  }, []);

  return {
    data: items,
    loading,
    error,
    refresh,
    setData: setItems,
    restock,
    adjust,
    create,
    update,
    remove,
  };
}

// =============================================================
// useTransactions — finance_transactions table
// =============================================================
export function useTransactions(query?: { type?: string; q?: string; category?: string }) {
  const [items, setItems] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);
  const queryRef = useRef(query);
  queryRef.current = query;

  const buildPath = useCallback((q?: { type?: string; q?: string; category?: string }) => {
    const params = new URLSearchParams();
    if (q?.type) params.set('type', q.type);
    if (q?.category) params.set('category', q.category);
    if (q?.q) params.set('query', q.q);
    const qs = params.toString();
    return qs ? `/finance/transactions?${qs}` : '/finance/transactions';
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<{ transactions: FinanceRow[] }>(buildPath(queryRef.current));
      if (!mountedRef.current) return;
      setItems((res.transactions || []).map(adaptTransaction));
    } catch (e: any) {
      if (mountedRef.current) setError(e?.error || 'Gagal memuat transaksi');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, [buildPath]);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  const create = useCallback(
    async (body: {
      title: string;
      type: 'INCOME' | 'EXPENSE';
      category: string;
      amount: number;
      notes?: string;
      source?: string;
    }) => {
      await apiPost('/finance/transactions', body);
      await refresh();
    },
    [refresh]
  );

  const remove = useCallback(
    async (id: string) => {
      await apiDelete(`/finance/transactions/${id}`);
      await refresh();
    },
    [refresh]
  );

  return { data: items, loading, error, refresh, setData: setItems, create, remove };
}

// =============================================================
// useDashboard
// =============================================================
export function useDashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<any>('/dashboard/overview');
      if (!mountedRef.current) return;
      setData(res);
    } catch (e: any) {
      if (mountedRef.current) setError(e?.error || 'Gagal memuat dashboard');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  return { data, loading, error, refresh };
}

// =============================================================
// useAiMessages
// =============================================================
export function useAiMessages() {
  const [items, setItems] = useState<AdaptedAiMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<{ messages: AiMessageRow[] }>('/ai/messages');
      if (!mountedRef.current) return;
      setItems((res.messages || []).map(adaptAiMessage));
    } catch (e: any) {
      if (mountedRef.current) setError(e?.error || 'Gagal memuat pesan AI');
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    mountedRef.current = true;
    refresh();
    return () => {
      mountedRef.current = false;
    };
  }, [refresh]);

  const send = useCallback(
    async (text: string) => {
      const res = await apiPost<{ userMessage: AiMessageRow; aiResponse: AiMessageRow }>(
        '/ai/chat',
        { text }
      );
      const userMsg = adaptAiMessage(res.userMessage);
      const aiMsg = adaptAiMessage(res.aiResponse);
      setItems((prev) => [...prev, userMsg, aiMsg]);
      return { user: userMsg as unknown as AiChatMessage, ai: aiMsg as unknown as AiChatMessage };
    },
    []
  );

  const confirmAction = useCallback(
    async (actionId: string) => {
      await apiPost(`/ai/actions/${actionId}/confirm`, {});
      // Reflect confirmed status locally so the UI hides the button.
      setItems((prev) =>
        prev.map((m) => {
          if (m.actionPayload && m.actionPayload.actionId === actionId) {
            return {
              ...m,
              actionStatus: 'confirmed',
              actionPayload: { ...m.actionPayload, status: 'confirmed' },
            };
          }
          return m;
        })
      );
    },
    []
  );

  const clear = useCallback(async () => {
    await apiDelete('/ai/messages');
    setItems([]);
  }, []);

  return {
    data: items as unknown as AiChatMessage[],
    raw: items,
    loading,
    error,
    refresh,
    setData: setItems,
    send,
    confirmAction,
    clear,
  };
}

// =============================================================
// useStockAlerts — derives from useStocks; kept as a separate
// hook so the ShellLayout can call refresh() independently.
// =============================================================
export function useStockAlerts() {
  const { data, loading, refresh } = useStocks();
  const alerts: StockAlert[] = (data || [])
    .filter((s) => Number(s.stock) <= Number(s.minStock))
    .map((s) =>
      adaptStockAlert({
        stock_id: s.stockId,
        name: s.name,
        current_stock: s.stock,
        min_stock: s.minStock,
        unit: s.unit,
      } as StockItemRow)
    );
  return { data: alerts, loading, refresh };
}