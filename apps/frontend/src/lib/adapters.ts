import type { Product, Transaction, StockAlert, AiChatMessage, TabType } from '../types';

export interface ProductRow {
  product_id: string;
  name: string;
  category: string;
  price: number;
  default_variant?: string;
  image_url?: string | null;
  code?: string;
  unit?: string;
  current_stock?: number;
  min_stock?: number;
  created_at?: string;
}

export interface StockItemRow {
  stock_id: string;
  name: string;
  category?: string;
  current_stock: number;
  min_stock: number;
  unit?: string;
  cost_per_unit?: number;
  supplier?: string;
  note?: string;
  status?: string;
  updated_at?: string;
}

export interface FinanceRow {
  transaction_id: string;
  user_id?: string;
  order_id?: string | null;
  title: string;
  type: 'INCOME' | 'EXPENSE' | string;
  category: string;
  amount: number;
  source?: string;
  notes?: string | null;
  timestamp: string;
}

export interface AiMessageRow {
  message_id: string;
  user_id?: string;
  sender: 'USER' | 'AI' | string;
  text: string;
  type: string;
  actionPayload?: any;
  extra_data?: any;
  timestamp: string;
}

export function adaptProduct(row: ProductRow): Product {
  return {
    id: row.product_id,
    code: row.code || row.product_id.slice(0, 8).toUpperCase(),
    name: row.name,
    category: row.category,
    price: Number(row.price),
    stock: Number(row.current_stock ?? 0),
    minStock: Number(row.min_stock ?? 0),
    unit: row.unit || 'pcs',
    image: row.image_url || undefined,
  };
}

export function adaptStockItem(row: StockItemRow): Product & { stockId: string; costPerUnit: number; supplier?: string; status?: string } {
  return {
    id: row.stock_id,
    code: row.stock_id.toUpperCase(),
    name: row.name,
    category: row.category || 'Lainnya',
    price: Number(row.cost_per_unit ?? 0),
    stock: Number(row.current_stock),
    minStock: Number(row.min_stock),
    unit: row.unit || 'pcs',
    stockId: row.stock_id,
    costPerUnit: Number(row.cost_per_unit ?? 0),
    supplier: row.supplier,
    status: row.status,
  };
}

export function adaptStockAlert(item: StockItemRow | ProductRow): StockAlert {
  const name = (item as any).name as string;
  const curr = Number((item as any).current_stock);
  const min = Number((item as any).min_stock);
  const unit = (item as any).unit || 'pcs';
  const id = (item as any).product_id || (item as any).stock_id;
  return {
    id,
    productName: name,
    currentStock: curr,
    minStock: min,
    unit,
    urgency: curr <= min * 0.5 ? 'high' : 'high',
  };
}

function mapPaymentMethod(source?: string, notes?: string | null): 'qris' | 'cash' | 'transfer' {
  const s = (source || '').toUpperCase();
  const n = (notes || '').toLowerCase();
  if (s.includes('QRIS') || n.includes('qris')) return 'qris';
  if (s.includes('CASH') || n.includes('cash') || n.includes('tunai')) return 'cash';
  return 'transfer';
}

export function adaptTransaction(row: FinanceRow): Transaction {
  const d = new Date(row.timestamp);
  const isExpense = row.type === 'EXPENSE';
  return {
    id: row.transaction_id,
    invoiceNo: row.title.replace(/^(Penjualan Kasir|Kulakan Stok|Listrik & WiFi)\s*/i, '') || row.transaction_id,
    date: d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
    time: d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
    type: isExpense ? 'expense' : 'sale',
    category: row.category === 'sales' ? 'Penjualan Kasir' : row.category === 'operational' ? 'Operasional' : row.category,
    amount: Number(row.amount),
    paymentMethod: mapPaymentMethod(row.source, row.notes),
    status: 'success',
    notes: row.notes || undefined,
  };
}

export function adaptAiMessage(row: AiMessageRow): AiChatMessage {
  const d = new Date(row.timestamp);
  const recs: { title: string; actionText: string; actionTab: TabType }[] | undefined =
    row.actionPayload?.recommendations || row.extra_data?.recommendations
      ? (row.actionPayload?.recommendations || row.extra_data?.recommendations).map((r: any) => ({
          title: r.title,
          actionText: r.actionText,
          actionTab: (r.actionTab as TabType) || 'home',
        }))
      : undefined;

  return {
    id: row.message_id,
    sender: row.sender === 'AI' ? 'ai' : 'user',
    text: row.text,
    timestamp: d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
    recommendations: recs,
  };
}
