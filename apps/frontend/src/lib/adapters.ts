import type { Product, Transaction, StockAlert, AiChatMessage, TabType } from '../types';

export interface ProductRow {
  id?: string;
  product_id?: string;
  name: string;
  category: string;
  price: number | string;
  default_variant?: string;
  defaultVariant?: string;
  image_url?: string | null;
  imageUrl?: string | null;
  image?: string | null;
  code?: string;
  unit?: string;
  current_stock?: number;
  currentStock?: number;
  stock?: number;
  min_stock?: number;
  minStock?: number;
  created_at?: string;
  createdAt?: string;
}

export interface StockItemRow {
  id?: string;
  stock_id?: string;
  name: string;
  category?: string;
  current_stock?: number;
  currentStock?: number;
  stock?: number;
  min_stock?: number;
  minStock?: number;
  unit?: string;
  cost_per_unit?: number;
  costPerUnit?: number;
  price?: number;
  supplier?: string;
  note?: string;
  status?: string;
  updated_at?: string;
  updatedAt?: string;
}

export interface FinanceRow {
  id?: string;
  transaction_id?: string;
  user_id?: string;
  userId?: string;
  order_id?: string | null;
  orderId?: string | null;
  title: string;
  type: 'INCOME' | 'EXPENSE' | string;
  category: string;
  amount: number | string;
  source?: string;
  notes?: string | null;
  payment_method?: string | null;
  paymentMethod?: string | null;
  timestamp?: string;
  createdAt?: string;
}

export interface AiMessageRow {
  id?: string;
  message_id?: string;
  user_id?: string;
  userId?: string;
  sender: 'USER' | 'AI' | 'user' | 'ai' | string;
  text: string;
  type: string;
  actionPayload?: any;
  action_payload?: any;
  extra_data?: any;
  extraData?: any;
  timestamp?: string;
  createdAt?: string;
}

export function normalizeCategoryToDisplay(cat?: string | null): string {
  if (!cat) return 'Lainnya';
  const clean = cat.trim().toUpperCase().replace(/[\s_-]+/g, '');
  if (clean === 'COFFEE' || clean === 'KOPI') return 'Kopi';
  if (clean === 'NONCOFFEE' || clean === 'NONKOPI') return 'Non-Kopi';
  if (clean === 'FOOD' || clean === 'MAKANAN') return 'Makanan';
  if (clean === 'SNACK' || clean === 'CAMILAN') return 'Snack';
  if (clean === 'OTHER' || clean === 'LAINNYA') return 'Lainnya';
  return cat;
}

export function adaptProduct(row: ProductRow): Product {
  const id = row.id || row.product_id || '';
  const code = row.code || (id ? id.slice(0, 8).toUpperCase() : 'PROD');
  const rawStock = row.stock ?? row.current_stock ?? row.currentStock ?? 0;
  const rawMinStock = row.minStock ?? row.min_stock ?? 0;
  const rawPrice = row.price ?? 0;
  const rawImg = row.imageUrl || row.image_url || row.image || undefined;

  let category = normalizeCategoryToDisplay(row.category);
  if (row.name && row.name.toLowerCase().includes('pepaya')) {
    category = 'Snack';
  }

  return {
    id,
    code,
    name: row.name || 'Menu Tanpa Nama',
    category,
    price: Number(rawPrice) || 0,
    stock: Number(rawStock) || 0,
    minStock: Number(rawMinStock) || 0,
    unit: row.unit || 'pcs',
    image: rawImg || undefined,
  };
}

export function adaptStockItem(
  row: StockItemRow
): Product & { stockId: string; costPerUnit: number; supplier?: string; status?: string } {
  const id = row.id || row.stock_id || '';
  const code = row.id ? row.id.slice(0, 8).toUpperCase() : (row.stock_id ? row.stock_id.toUpperCase() : 'STK');
  const cost = Number(row.costPerUnit ?? row.cost_per_unit ?? row.price ?? 0);
  const currentStock = Number(row.currentStock ?? row.current_stock ?? row.stock ?? 0);
  const minStock = Number(row.minStock ?? row.min_stock ?? 0);

  return {
    id,
    code,
    name: row.name || 'Item Stok',
    category: row.category || 'Topping & Lainnya',
    price: cost,
    stock: currentStock,
    minStock,
    unit: row.unit || 'pcs',
    stockId: id,
    costPerUnit: cost,
    supplier: row.supplier || 'Supplier Utama',
    status: row.status || (currentStock <= minStock ? 'low' : 'available'),
  };
}

export function adaptStockAlert(item: StockItemRow | ProductRow): StockAlert {
  const name = (item as any).name as string || 'Item Stok';
  const curr = Number((item as any).currentStock ?? (item as any).current_stock ?? (item as any).stock ?? 0);
  const min = Number((item as any).minStock ?? (item as any).min_stock ?? 0);
  const unit = (item as any).unit || 'pcs';
  const id = (item as any).id || (item as any).product_id || (item as any).stock_id || '';

  // Kritis when at or below 50% of the safety stock, otherwise rendah.
  const urgency: StockAlert['urgency'] = curr <= min * 0.5 ? 'high' : 'medium';

  return {
    id,
    productName: name,
    currentStock: curr,
    minStock: min,
    unit,
    urgency,
  };
}

function mapPaymentMethod(
  paymentMethod?: string | null,
  source?: string,
  notes?: string | null
): 'qris' | 'cash' | 'transfer' {
  const all = `${paymentMethod || ''} ${source || ''} ${notes || ''}`.toLowerCase();
  if (all.includes('qris') || all.includes('e-wallet') || all.includes('ewallet')) return 'qris';
  if (all.includes('cash') || all.includes('tunai')) return 'cash';
  return 'transfer';
}

export function adaptTransaction(row: FinanceRow): Transaction {
  const rawTimestamp = row.createdAt || row.timestamp || new Date().toISOString();
  const d = new Date(rawTimestamp);
  const isExpense = row.type === 'EXPENSE';
  const notes = row.notes || '';
  const title = row.title || '';
  const cleanTitle = title.replace(/^(Penjualan Kasir|Kulakan Stok|Listrik & WiFi)\s*/i, '');
  const id = row.id || row.transaction_id || '';

  return {
    id,
    invoiceNo: cleanTitle || (id ? id.slice(0, 8).toUpperCase() : 'TRX'),
    date: !isNaN(d.getTime()) ? d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '',
    time: !isNaN(d.getTime()) ? d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '',
    type: isExpense ? 'expense' : 'sale',
    category:
      row.category === 'sales'
        ? 'Penjualan Kasir'
        : row.category === 'operational'
        ? 'Operasional'
        : row.category === 'ingredients'
        ? 'Kulakan Stok'
        : row.category || 'Umum',
    amount: Number(row.amount ?? 0),
    paymentMethod: mapPaymentMethod(row.paymentMethod || row.payment_method, row.source, row.notes),
    status: 'success',
    notes: notes || undefined,
    title: title || undefined,
  };
}

export interface AdaptedAiMessage extends AiChatMessage {
  raw: AiMessageRow;
  actionPayload?: any;
  actionStatus?: 'pending' | 'confirmed' | 'cancelled';
  messageType?: string;
}

export function adaptAiMessage(row: AiMessageRow): AdaptedAiMessage {
  const rawTimestamp = row.createdAt || row.timestamp || new Date().toISOString();
  const d = new Date(rawTimestamp);
  const actionPayload = row.actionPayload ?? row.action_payload;
  const rawRecs = actionPayload?.recommendations || row.extraData?.recommendations || row.extra_data?.recommendations;
  const recs: { title: string; actionText: string; actionTab: TabType }[] | undefined =
    Array.isArray(rawRecs)
      ? rawRecs.map((r: any) => ({
          title: r.title,
          actionText: r.actionText,
          actionTab: (r.actionTab as TabType) || 'home',
        }))
      : undefined;

  const id = row.id || row.message_id || String(Date.now());
  const isAi = row.sender === 'AI' || row.sender === 'ai';

  return {
    id,
    sender: isAi ? 'ai' : 'user',
    text: row.text || '',
    timestamp: !isNaN(d.getTime()) ? d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '',
    recommendations: recs,
    raw: row,
    actionPayload,
    actionStatus: actionPayload?.status,
    messageType: row.type || 'text',
  };
}