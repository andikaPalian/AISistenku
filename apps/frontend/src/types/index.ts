export type TabType = 'home' | 'pos' | 'ai' | 'stock' | 'finance';

export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  stock: number;
  minStock: number;
  unit: string;
  image?: string;
  code?: string;
}

export interface CartItem {
  product: Product;
  quantity: number;
  notes?: string;
}

export interface Transaction {
  id: string;
  invoiceNo: string;
  date: string;
  time: string;
  type: 'sale' | 'expense' | 'income';
  category: string;
  amount: number;
  paymentMethod: 'qris' | 'cash' | 'transfer';
  status: 'success' | 'pending' | 'cancelled';
  itemCount?: number;
  notes?: string;
}

export interface StockAlert {
  id: string;
  productName: string;
  currentStock: number;
  minStock: number;
  unit: string;
  urgency: 'high' | 'medium';
}

export interface AiChatMessage {
  id: string;
  sender: 'user' | 'ai';
  text: string;
  timestamp: string;
  recommendations?: { title: string; actionText: string; actionTab: TabType }[];
}
