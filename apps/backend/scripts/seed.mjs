import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
config({ path: path.resolve(__dirname, '../.env') });

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in apps/backend/.env');
  process.exit(1);
}

const supabase = createClient(url, key, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const now = new Date();
const isoOffset = (hours) => new Date(now.getTime() - hours * 3600 * 1000).toISOString();

const seed = {
  users: [
    {
      user_id: '00000000-0000-0000-0000-000000000001',
      email: 'owner@tigaangkatan.id',
      name: 'Owner Tiga Angkatan',
      role: 'owner',
    },
  ],
  products: [
    { product_id: '11111111-1111-1111-1111-000000000001', name: 'Beras Pandan Wangi 5kg', category: 'Sembako', price: 78000, default_variant: 'Regular', code: 'PRD-001', unit: 'karung', current_stock: 24, min_stock: 10 },
    { product_id: '11111111-1111-1111-1111-000000000002', name: 'Minyak Goreng SunCo 2L', category: 'Sembako', price: 38500, default_variant: 'Regular', code: 'PRD-002', unit: 'pouch', current_stock: 5, min_stock: 12 },
    { product_id: '11111111-1111-1111-1111-000000000003', name: 'Gula Pasir Gulaku 1kg', category: 'Sembako', price: 17500, default_variant: 'Regular', code: 'PRD-003', unit: 'kg', current_stock: 3, min_stock: 15 },
    { product_id: '11111111-1111-1111-1111-000000000004', name: 'Telur Ayam Negeri 1kg', category: 'Sembako', price: 29000, default_variant: 'Regular', code: 'PRD-004', unit: 'kg', current_stock: 45, min_stock: 20 },
    { product_id: '11111111-1111-1111-1111-000000000005', name: 'Kopi Kapal Api Special 165g', category: 'Minuman', price: 14500, default_variant: 'Regular', code: 'PRD-005', unit: 'bungkus', current_stock: 18, min_stock: 8 },
    { product_id: '11111111-1111-1111-1111-000000000006', name: 'Teh Celup Sosri 25s', category: 'Minuman', price: 7200, default_variant: 'Regular', code: 'PRD-006', unit: 'kotak', current_stock: 30, min_stock: 10 },
    { product_id: '11111111-1111-1111-1111-000000000007', name: 'Susu Indomilk Kental Manis', category: 'Minuman', price: 12000, default_variant: 'Regular', code: 'PRD-007', unit: 'kaleng', current_stock: 2, min_stock: 10 },
    { product_id: '11111111-1111-1111-1111-000000000008', name: 'Mie Goreng Indomie (Karton)', category: 'Makanan', price: 112000, default_variant: 'Regular', code: 'PRD-008', unit: 'karton', current_stock: 8, min_stock: 5 },
    { product_id: '11111111-1111-1111-1111-000000000009', name: 'Sabun Cuci Piring Rinso 770ml', category: 'Kebutuhan Rumah', price: 19500, default_variant: 'Regular', code: 'PRD-009', unit: 'pouch', current_stock: 14, min_stock: 6 },
  ],
  stock_items: [
    { stock_id: 'sugar', name: 'Sugar', category: 'Gula & Pemanis', current_stock: 3, min_stock: 5, unit: 'kg', cost_per_unit: 16000, supplier: 'PT Sumber Manis Nusantara', note: 'Gula pasir kristal putih premium' },
    { stock_id: 'fresh_milk', name: 'Fresh Milk', category: 'Susu & Dairy', current_stock: 5, min_stock: 8, unit: 'L', cost_per_unit: 24000, supplier: 'Greenfield Dairy Farm' },
    { stock_id: 'coffee_beans', name: 'Coffee Beans', category: 'Biji Kopi', current_stock: 8, min_stock: 3, unit: 'kg', cost_per_unit: 95000, supplier: 'Aceh Gayo Specialty Roastery' },
    { stock_id: 'chocolate_syrup', name: 'Chocolate Syrup', category: 'Sirup & Perisa', current_stock: 6, min_stock: 2, unit: 'btl', cost_per_unit: 65000, supplier: 'Diva Flavor Indonesia' },
    { stock_id: 'caramel_syrup', name: 'Caramel Syrup', category: 'Sirup & Perisa', current_stock: 1.5, min_stock: 2, unit: 'btl', cost_per_unit: 68000, supplier: 'Diva Flavor Indonesia' },
    { stock_id: 'cup_16oz', name: 'Cup Plastic 16oz + Lid', category: 'Cup & Kemasan', current_stock: 45, min_stock: 100, unit: 'pcs', cost_per_unit: 850, supplier: 'Mitra Pack Tangerang' },
    { stock_id: 'beras', name: 'Beras Pandan Wangi', category: 'Sembako', current_stock: 24, min_stock: 10, unit: 'karung', cost_per_unit: 65000, supplier: 'Sumber Karung Indonesia' },
    { stock_id: 'minyak', name: 'Minyak Goreng SunCo', category: 'Sembako', current_stock: 5, min_stock: 12, unit: 'pouch', cost_per_unit: 32000, supplier: 'Distributor SunCo' },
    { stock_id: 'telur', name: 'Telur Ayam Negeri', category: 'Sembako', current_stock: 45, min_stock: 20, unit: 'kg', cost_per_unit: 24000, supplier: 'Peternakan Lokal' },
  ],
  product_recipes: [
    { recipe_id: 'rec-1', product_id: '11111111-1111-1111-1111-000000000001', stock_id: 'beras', quantity_required: 1 },
    { recipe_id: 'rec-2', product_id: '11111111-1111-1111-1111-000000000002', stock_id: 'minyak', quantity_required: 1 },
    { recipe_id: 'rec-3', product_id: '11111111-1111-1111-1111-000000000003', stock_id: 'sugar', quantity_required: 1 },
    { recipe_id: 'rec-4', product_id: '11111111-1111-1111-1111-000000000004', stock_id: 'telur', quantity_required: 1 },
    { recipe_id: 'rec-5', product_id: '11111111-1111-1111-1111-000000000007', stock_id: 'fresh_milk', quantity_required: 0.5 },
  ],
  finance_transactions: [
    { transaction_id: 'tx-1', user_id: '00000000-0000-0000-0000-000000000001', title: 'Penjualan Kasir INV/20260901/001', type: 'INCOME', category: 'sales', amount: 134000, source: 'POS_AUTOMATIC', notes: 'Pelanggan Member', timestamp: isoOffset(4) },
    { transaction_id: 'tx-2', user_id: '00000000-0000-0000-0000-000000000001', title: 'Penjualan Kasir INV/20260901/002', type: 'INCOME', category: 'sales', amount: 56000, source: 'POS_AUTOMATIC', notes: null, timestamp: isoOffset(6) },
    { transaction_id: 'tx-3', user_id: '00000000-0000-0000-0000-000000000001', title: 'Kulakan Stok EXP/20260901/001', type: 'EXPENSE', category: 'operational', amount: 450000, source: 'MANUAL', notes: 'Restock Minyak & Gula', timestamp: isoOffset(8) },
    { transaction_id: 'tx-4', user_id: '00000000-0000-0000-0000-000000000001', title: 'Penjualan Kasir INV/20260831/045', type: 'INCOME', category: 'sales', amount: 215000, source: 'POS_AUTOMATIC', notes: null, timestamp: isoOffset(28) },
    { transaction_id: 'tx-5', user_id: '00000000-0000-0000-0000-000000000001', title: 'Listrik & WiFi EXP/20260831/002', type: 'EXPENSE', category: 'operational', amount: 280000, source: 'MANUAL', notes: null, timestamp: isoOffset(32) },
  ],
  ai_messages: [
    {
      message_id: 'msg-seed-1',
      user_id: '00000000-0000-0000-0000-000000000001',
      sender: 'AI',
      text: 'Halo! Saya AI Assistant Tiga Angkatan. Ada yang bisa saya bantu untuk analisis bisnis toko Anda hari ini?',
      type: 'text',
      actionPayload: {
        recommendations: [
          { title: 'Lihat Produk Restock', actionText: 'Buka Stok', actionTab: 'stock' },
          { title: 'Analisis Omzet Hari Ini', actionText: 'Buka Keuangan', actionTab: 'finance' },
        ],
      },
      extra_data: null,
      timestamp: isoOffset(1),
    },
  ],
};

const order = ['users', 'products', 'stock_items', 'product_recipes', 'finance_transactions', 'ai_messages'];

for (const table of order) {
  const rows = seed[table];
  const { error } = await supabase.from(table).upsert(rows);
  if (error) {
    console.error(`❌ ${table}:`, error.message);
    process.exit(1);
  }
  console.log(`✅ ${table}: ${rows.length} rows upserted`);
}

console.log('🎉 Seed complete');
