import { useCallback, useEffect, useState } from 'react';
import { apiGet, apiPost, apiPut, apiDelete } from '../lib/api';
import {
  adaptProduct, adaptStockItem, adaptTransaction, adaptAiMessage, adaptStockAlert,
  ProductRow, StockItemRow, FinanceRow, AiMessageRow,
} from '../lib/adapters';
import type { Product, Transaction, StockAlert, AiChatMessage, CartItem } from '../types';

interface UseListState<T> {
  data: T[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  setData: React.Dispatch<React.SetStateAction<T[]>>;
}

function useList<T>(loader: () => Promise<T[]>): UseListState<T> {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const items = await loader();
      setData(items);
    } catch (e: any) {
      setError(e?.error || 'Gagal memuat data');
    } finally {
      setLoading(false);
    }
  }, [loader]);

  useEffect(() => { refresh(); }, [refresh]);
  return { data, loading, error, refresh, setData };
}

export function useProducts() {
  const list = useList<Product>(async () => {
    const res = await apiGet<{ products: ProductRow[] }>('/products');
    return (res.products || []).map(adaptProduct);
  });

  const createOrder = useCallback(async (payload: {
    items: CartItem[];
    paymentMethod: 'qris' | 'cash' | 'transfer';
    orderType: string;
    customerName?: string;
    tableNumber?: string;
    cashGiven: number;
    change: number;
  }) => {
    const items = payload.items.map((ci) => ({
      product_id: ci.product.id,
      product_name: ci.product.name,
      variant: ci.product.code,
      quantity: ci.quantity,
      price: ci.product.price,
      subtotal: ci.product.price * ci.quantity,
      note: ci.notes,
    }));
    const subtotal = items.reduce((s, i) => s + i.subtotal, 0);
    const res = await apiPost<{ order: { order_id: string; order_code: string; total_amount: number } }>('/orders', {
      orderType: payload.orderType,
      tableNumber: payload.tableNumber,
      customerName: payload.customerName,
      paymentMethod: payload.paymentMethod === 'qris' ? 'QRIS' : payload.paymentMethod === 'cash' ? 'Cash' : 'Bank Transfer',
      items,
      subtotal,
      tax: 0,
      total: subtotal,
      cashGiven: payload.cashGiven,
      change: payload.change,
    });
    return res.order;
  }, []);

  return { ...list, createOrder };
}

export function useStocks() {
  const list = useList<Product>(async () => {
    const res = await apiGet<{ stocks: StockItemRow[] }>('/stocks');
    return (res.stocks || []).map(adaptStockItem);
  });

  const restock = useCallback(async (stockId: string, body: { quantity: number; cost_per_unit?: number; supplier?: string; note?: string }) => {
    const res = await apiPost<{ stock: StockItemRow }>(`/stocks/${stockId}/restock`, body);
    await list.refresh();
    return res.stock;
  }, [list]);

  const adjust = useCallback(async (stockId: string, body: { actual_quantity: number; reason?: string; note?: string }) => {
    const res = await apiPost<{ stock: StockItemRow }>(`/stocks/${stockId}/adjust`, body);
    await list.refresh();
    return res.stock;
  }, [list]);

  const create = useCallback(async (body: Partial<StockItemRow>) => {
    const res = await apiPost<{ stock: StockItemRow }>('/stocks', body);
    await list.refresh();
    return res.stock;
  }, [list]);

  const update = useCallback(async (stockId: string, body: Partial<StockItemRow>) => {
    const res = await apiPut<{ stock: StockItemRow }>(`/stocks/${stockId}`, body);
    await list.refresh();
    return res.stock;
  }, [list]);

  const remove = useCallback(async (stockId: string) => {
    await apiDelete(`/stocks/${stockId}`);
    await list.refresh();
  }, [list]);

  return { ...list, restock, adjust, create, update, remove };
}

export function useTransactions(query?: { type?: string; q?: string }) {
  const params = new URLSearchParams();
  if (query?.type) params.set('type', query.type);
  if (query?.q) params.set('query', query.q);
  const qs = params.toString() ? `?${params.toString()}` : '';
  const list = useList<Transaction>(async () => {
    const res = await apiGet<{ transactions: FinanceRow[] }>(`/finance/transactions${qs}`);
    return (res.transactions || []).map(adaptTransaction);
  });

  const create = useCallback(async (body: { title: string; type: 'INCOME' | 'EXPENSE'; category: string; amount: number; notes?: string; source?: string }) => {
    await apiPost('/finance/transactions', body);
    await list.refresh();
  }, [list]);

  const remove = useCallback(async (id: string) => {
    await apiDelete(`/finance/transactions/${id}`);
    await list.refresh();
  }, [list]);

  return { ...list, create, remove };
}

export function useDashboard() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const refresh = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await apiGet<any>('/dashboard/overview');
      setData(res);
    } catch (e: any) { setError(e?.error || 'Gagal memuat dashboard'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { refresh(); }, [refresh]);
  return { data, loading, error, refresh };
}

export function useAiMessages() {
  const list = useList<AiChatMessage>(async () => {
    const res = await apiGet<{ messages: AiMessageRow[] }>('/ai/messages');
    return (res.messages || []).map(adaptAiMessage);
  });

  const send = useCallback(async (text: string) => {
    const res = await apiPost<{ userMessage: AiMessageRow; aiResponse: AiMessageRow }>('/ai/chat', { text });
    await list.refresh();
    return { user: adaptAiMessage(res.userMessage), ai: adaptAiMessage(res.aiResponse) };
  }, [list]);

  const confirmAction = useCallback(async (actionId: string) => {
    await apiPost(`/ai/actions/${actionId}/confirm`, {});
    await list.refresh();
  }, [list]);

  const clear = useCallback(async () => {
    await apiDelete('/ai/messages');
    await list.refresh();
  }, [list]);

  return { ...list, send, confirmAction, clear };
}

export function useStockAlerts() {
  const [data, setData] = useState<StockAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiGet<{ stocks: StockItemRow[] }>('/stocks');
      const alerts = (res.stocks || [])
        .filter((s) => Number(s.current_stock) <= Number(s.min_stock))
        .map(adaptStockAlert);
      setData(alerts);
    } catch {
    } finally { setLoading(false); }
  }, []);
  useEffect(() => { refresh(); }, [refresh]);
  return { data, loading, refresh };
}
