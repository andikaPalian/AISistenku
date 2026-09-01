-- 0002_seed.sql
-- Seed initial data mirroring apps/frontend/src/mockData.ts
-- Run AFTER 0001_init.sql in Supabase SQL Editor

-- USERS (default owner used as fallback in middleware)
insert into public.users (user_id, email, name, role) values
  ('00000000-0000-0000-0000-000000000001', 'owner@tigaangkatan.id', 'Owner Tiga Angkatan', 'owner')
on conflict (user_id) do nothing;

-- PRODUCTS (9 rows matching mockData)
insert into public.products (product_id, name, category, price, default_variant, image_url, code, unit, current_stock, min_stock) values
  ('11111111-1111-1111-1111-000000000001', 'Beras Pandan Wangi 5kg', 'Sembako', 78000, 'Regular', null, 'PRD-001', 'karung', 24, 10),
  ('11111111-1111-1111-1111-000000000002', 'Minyak Goreng SunCo 2L', 'Sembako', 38500, 'Regular', null, 'PRD-002', 'pouch', 5, 12),
  ('11111111-1111-1111-1111-000000000003', 'Gula Pasir Gulaku 1kg', 'Sembako', 17500, 'Regular', null, 'PRD-003', 'kg', 3, 15),
  ('11111111-1111-1111-1111-000000000004', 'Telur Ayam Negeri 1kg', 'Sembako', 29000, 'Regular', null, 'PRD-004', 'kg', 45, 20),
  ('11111111-1111-1111-1111-000000000005', 'Kopi Kapal Api Special 165g', 'Minuman', 14500, 'Regular', null, 'PRD-005', 'bungkus', 18, 8),
  ('11111111-1111-1111-1111-000000000006', 'Teh Celup Sosri 25s', 'Minuman', 7200, 'Regular', null, 'PRD-006', 'kotak', 30, 10),
  ('11111111-1111-1111-1111-000000000007', 'Susu Indomilk Kental Manis', 'Minuman', 12000, 'Regular', null, 'PRD-007', 'kaleng', 2, 10),
  ('11111111-1111-1111-1111-000000000008', 'Mie Goreng Indomie (Karton)', 'Makanan', 112000, 'Regular', null, 'PRD-008', 'karton', 8, 5),
  ('11111111-1111-1111-1111-000000000009', 'Sabun Cuci Piring Rinso 770ml', 'Kebutuhan Rumah', 19500, 'Regular', null, 'PRD-009', 'pouch', 14, 6)
on conflict (product_id) do nothing;

-- STOCK ITEMS (9 rows)
insert into public.stock_items (stock_id, name, category, current_stock, min_stock, unit, cost_per_unit, supplier, note) values
  ('sugar', 'Sugar', 'Gula & Pemanis', 3.0, 5.0, 'kg', 16000, 'PT Sumber Manis Nusantara', 'Gula pasir kristal putih premium'),
  ('fresh_milk', 'Fresh Milk', 'Susu & Dairy', 5.0, 8.0, 'L', 24000, 'Greenfield Dairy Farm', 'Pasteurized Fresh Milk 1L per pack'),
  ('coffee_beans', 'Coffee Beans', 'Biji Kopi', 8.0, 3.0, 'kg', 95000, 'Aceh Gayo Specialty Roastery', 'House Blend 70% Arabica Gayo & 30% Robusta Temanggung'),
  ('chocolate_syrup', 'Chocolate Syrup', 'Sirup & Perisa', 6.0, 2.0, 'btl', 65000, 'Diva Flavor Indonesia', 'Botol 750ml rasa Dark Rich Chocolate'),
  ('caramel_syrup', 'Caramel Syrup', 'Sirup & Perisa', 1.5, 2.0, 'btl', 68000, 'Diva Flavor Indonesia', null),
  ('cup_16oz', 'Cup Plastic 16oz + Lid', 'Cup & Kemasan', 45.0, 100.0, 'pcs', 850, 'Mitra Pack Tangerang', null),
  ('beras', 'Beras Pandan Wangi', 'Sembako', 24.0, 10.0, 'karung', 65000, 'Sumber Karung Indonesia', null),
  ('minyak', 'Minyak Goreng SunCo', 'Sembako', 5.0, 12.0, 'pouch', 32000, 'Distributor SunCo', null),
  ('telur', 'Telur Ayam Negeri', 'Sembako', 45.0, 20.0, 'kg', 24000, 'Peternakan Lokal', null)
on conflict (stock_id) do nothing;

-- PRODUCT RECIPES (link each product to one stock item)
insert into public.product_recipes (recipe_id, product_id, stock_id, quantity_required) values
  ('rec-1', '11111111-1111-1111-1111-000000000001', 'beras', 1),
  ('rec-2', '11111111-1111-1111-1111-000000000002', 'minyak', 1),
  ('rec-3', '11111111-1111-1111-1111-000000000003', 'sugar', 1),
  ('rec-4', '11111111-1111-1111-1111-000000000004', 'telur', 1),
  ('rec-5', '11111111-1111-1111-1111-000000000007', 'fresh_milk', 0.5)
on conflict (recipe_id) do nothing;

-- FINANCE TRANSACTIONS (5 rows mirroring INITIAL_TRANSACTIONS)
insert into public.finance_transactions (transaction_id, user_id, order_id, title, type, category, amount, source, notes, timestamp) values
  ('tx-1', '00000000-0000-0000-0000-000000000001', null, 'Penjualan Kasir INV/20260901/001', 'INCOME', 'sales', 134000, 'POS_AUTOMATIC', 'Pelanggan Member', now() - interval '4 hours'),
  ('tx-2', '00000000-0000-0000-0000-000000000001', null, 'Penjualan Kasir INV/20260901/002', 'INCOME', 'sales', 56000, 'POS_AUTOMATIC', null, now() - interval '6 hours'),
  ('tx-3', '00000000-0000-0000-0000-000000000001', null, 'Kulakan Stok EXP/20260901/001', 'EXPENSE', 'operational', 450000, 'MANUAL', 'Restock Minyak & Gula', now() - interval '8 hours'),
  ('tx-4', '00000000-0000-0000-0000-000000000001', null, 'Penjualan Kasir INV/20260831/045', 'INCOME', 'sales', 215000, 'POS_AUTOMATIC', null, now() - interval '1 day'),
  ('tx-5', '00000000-0000-0000-0000-000000000001', null, 'Listrik & WiFi EXP/20260831/002', 'EXPENSE', 'operational', 280000, 'MANUAL', null, now() - interval '1 day 4 hours')
on conflict (transaction_id) do nothing;

-- AI MESSAGES (1 row greeting)
insert into public.ai_messages (message_id, user_id, sender, text, type, actionPayload, extra_data, timestamp) values
  ('msg-1', '00000000-0000-0000-0000-000000000001', 'AI', 'Halo Pak Budi! Saya AI Assistant Tiga Angkatan. Ada yang bisa saya bantu untuk analisis bisnis toko Anda hari ini?', 'text', null,
   '{"recommendations":[{"title":"Lihat Produk Restock","actionText":"Buka Stok","actionTab":"stock"},{"title":"Analisis Omzet Hari Ini","actionText":"Buka Keuangan","actionTab":"finance"}]}'::jsonb,
   now() - interval '30 minutes')
on conflict (message_id) do nothing;
