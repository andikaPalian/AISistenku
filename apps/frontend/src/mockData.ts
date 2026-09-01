import { Product, Transaction, StockAlert, AiChatMessage } from './types';

export const INITIAL_PRODUCTS: Product[] = [
  { id: '1', code: 'PRD-001', name: 'Beras Pandan Wangi 5kg', category: 'Sembako', price: 78000, stock: 24, minStock: 10, unit: 'karung' },
  { id: '2', code: 'PRD-002', name: 'Minyak Goreng SunCo 2L', category: 'Sembako', price: 38500, stock: 5, minStock: 12, unit: 'pouch' },
  { id: '3', code: 'PRD-003', name: 'Gula Pasir Gulaku 1kg', category: 'Sembako', price: 17500, stock: 3, minStock: 15, unit: 'kg' },
  { id: '4', code: 'PRD-004', name: 'Telur Ayam Negeri 1kg', category: 'Sembako', price: 29000, stock: 45, minStock: 20, unit: 'kg' },
  { id: '5', code: 'PRD-005', name: 'Kopi Kapal Api Special 165g', category: 'Minuman', price: 14500, stock: 18, minStock: 8, unit: 'bungkus' },
  { id: '6', code: 'PRD-006', name: 'Teh Celup Sosri 25s', category: 'Minuman', price: 7200, stock: 30, minStock: 10, unit: 'kotak' },
  { id: '7', code: 'PRD-007', name: 'Susu Indomilk Kental Manis', category: 'Minuman', price: 12000, stock: 2, minStock: 10, unit: 'kaleng' },
  { id: '8', code: 'PRD-008', name: 'Mie Goreng Indomie (Karton)', category: 'Makanan', price: 112000, stock: 8, minStock: 5, unit: 'karton' },
  { id: '9', code: 'PRD-009', name: 'Sabun Cuci Piring Rinso 770ml', category: 'Kebutuhan Rumah', price: 19500, stock: 14, minStock: 6, unit: 'pouch' },
];

export const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: 'tx-1', invoiceNo: 'INV/20260901/001', date: '01 Sep 2026', time: '14:32', type: 'sale', category: 'Penjualan Kasir', amount: 134000, paymentMethod: 'qris', status: 'success', itemCount: 3, notes: 'Pelanggan Member' },
  { id: 'tx-2', invoiceNo: 'INV/20260901/002', date: '01 Sep 2026', time: '12:15', type: 'sale', category: 'Penjualan Kasir', amount: 56000, paymentMethod: 'cash', status: 'success', itemCount: 2 },
  { id: 'tx-3', invoiceNo: 'EXP/20260901/001', date: '01 Sep 2026', time: '10:00', type: 'expense', category: 'Kulakan Stok', amount: 450000, paymentMethod: 'transfer', status: 'success', notes: 'Restock Minyak & Gula' },
  { id: 'tx-4', invoiceNo: 'INV/20260831/045', date: '31 Agu 2026', time: '19:40', type: 'sale', category: 'Penjualan Kasir', amount: 215000, paymentMethod: 'qris', status: 'success', itemCount: 5 },
  { id: 'tx-5', invoiceNo: 'EXP/20260831/002', date: '31 Agu 2026', time: '09:20', type: 'expense', category: 'Listrik & WiFi', amount: 280000, paymentMethod: 'transfer', status: 'success' },
];

export const STOCK_ALERTS: StockAlert[] = [
  { id: 'sa-1', productName: 'Susu Indomilk Kental Manis', currentStock: 2, minStock: 10, unit: 'kaleng', urgency: 'high' },
  { id: 'sa-2', productName: 'Gula Pasir Gulaku 1kg', currentStock: 3, minStock: 15, unit: 'kg', urgency: 'high' },
  { id: 'sa-3', productName: 'Minyak Goreng SunCo 2L', currentStock: 5, minStock: 12, unit: 'pouch', urgency: 'medium' },
];

export const INITIAL_CHAT_MESSAGES: AiChatMessage[] = [
  {
    id: 'msg-1',
    sender: 'ai',
    text: 'Halo Pak Budi! Saya AI Assistant Tiga Angkatan. Ada yang bisa saya bantu untuk analisis bisnis toko Anda hari ini?',
    timestamp: '14:00',
    recommendations: [
      { title: 'Lihat Produk Restock', actionText: 'Buka Stok', actionTab: 'stock' },
      { title: 'Analisis Omzet Hari Ini', actionText: 'Buka Keuangan', actionTab: 'finance' }
    ]
  }
];
