-- =============================================================
-- Tiga Angkatan — Seed Data
-- =============================================================
-- Mirror of apps/backend/src/lib/store.js.
-- Run AFTER 0001_init.sql.
-- Uses the default owner UUID '00000000-0000-0000-0000-000000000001'
-- so backend fallback user_id resolves to a real row.

-- ---------- Default Owner ----------
insert into public.users (user_id, email, name, role)
values (
  '00000000-0000-0000-0000-000000000001',
  'owner@tigaangkatan.id',
  'Owner Tiga Angkatan',
  'owner'
)
on conflict (user_id) do nothing;

-- ---------- Products (POS menu) ----------
insert into public.products (product_id, name, category, price, default_variant, image_url, code, unit, current_stock, min_stock)
values
  ('prod-1', 'Iced Latte',     'Kopi',     15000, 'Less Sugar, Ice', null, 'CF-001', 'cup',   42, 15),
  ('prod-2', 'Americano',      'Kopi',     18000, 'Hot / No Sugar',  null, 'CF-002', 'cup',   35, 12),
  ('prod-3', 'Cappuccino',     'Kopi',     20000, 'Regular',         null, 'CF-003', 'cup',   25, 10),
  ('prod-4', 'Chocolate',      'Non-Kopi', 17000, 'Ice',             null, 'NK-001', 'cup',   20, 10),
  ('prod-5', 'Matcha Latte',   'Non-Kopi', 20000, 'Oatmilk',         null, 'NK-002', 'cup',   18,  8),
  ('prod-6', 'Croissant',      'Snack',    15000, 'Butter',          null, 'SN-001', 'pcs',   14,  6),
  ('prod-7', 'Avocado Toast',  'Makanan',  25000, 'Sourdough',       null, 'FD-001', 'porsi', 10,  5)
on conflict (product_id) do nothing;

-- ---------- Stock Items ----------
insert into public.stock_items (stock_id, name, category, current_stock, min_stock, unit, cost_per_unit, supplier, note)
values
  ('sugar',            'Sugar',                'Gula & Pemanis',  3.0, 5.0,  'kg',  16000, 'PT Sumber Manis Nusantara',   'Gula pasir kristal putih premium'),
  ('fresh_milk',       'Fresh Milk',           'Susu & Dairy',    5.0, 8.0,  'L',   24000, 'Greenfield Dairy Farm',       'Pasteurized Fresh Milk 1L per pack'),
  ('coffee_beans',     'Coffee Beans',         'Biji Kopi',       8.0, 3.0,  'kg',  95000, 'Aceh Gayo Specialty Roastery','House Blend 70% Arabica Gayo & 30% Robusta Temanggung'),
  ('chocolate_syrup',  'Chocolate Syrup',      'Sirup & Perisa',  6.0, 2.0,  'btl', 65000, 'Diva Flavor Indonesia',       'Botol 750ml rasa Dark Rich Chocolate'),
  ('caramel_syrup',    'Caramel Syrup',        'Sirup & Perisa',  1.5, 2.0,  'btl', 68000, 'Diva Flavor Indonesia',       null),
  ('cup_16oz',         'Cup Plastic 16oz + Lid','Cup & Kemasan',  45.0, 100.0,'pcs',  850,  'Mitra Pack Tangerang',        null)
on conflict (stock_id) do nothing;

-- ---------- Product Recipes (cover all 7 products) ----------
insert into public.product_recipes (recipe_id, product_id, stock_id, quantity_required)
values
  -- Iced Latte
  ('rec-1', 'prod-1', 'coffee_beans',    0.018),
  ('rec-2', 'prod-1', 'fresh_milk',      0.15),
  ('rec-3', 'prod-1', 'sugar',           0.01),
  ('rec-4', 'prod-1', 'cup_16oz',        1.0),
  -- Americano
  ('rec-5', 'prod-2', 'coffee_beans',    0.02),
  ('rec-6', 'prod-2', 'cup_16oz',        1.0),
  -- Cappuccino
  ('rec-7', 'prod-3', 'coffee_beans',    0.02),
  ('rec-8', 'prod-3', 'fresh_milk',      0.18),
  ('rec-9', 'prod-3', 'sugar',           0.008),
  ('rec-10','prod-3', 'cup_16oz',        1.0),
  -- Chocolate
  ('rec-11','prod-4', 'chocolate_syrup', 0.02),
  ('rec-12','prod-4', 'fresh_milk',      0.15),
  ('rec-13','prod-4', 'sugar',           0.01),
  ('rec-14','prod-4', 'cup_16oz',        1.0),
  -- Matcha Latte
  ('rec-15','prod-5', 'fresh_milk',      0.18),
  ('rec-16','prod-5', 'sugar',           0.01),
  ('rec-17','prod-5', 'cup_16oz',        1.0),
  -- Croissant
  ('rec-18','prod-6', 'sugar',           0.02),
  -- Avocado Toast
  ('rec-19','prod-7', 'sugar',           0.005)
on conflict (recipe_id) do nothing;

-- ---------- Sample Order ----------
insert into public.orders (order_id, order_code, user_id, order_type, table_number, customer_name,
                            subtotal, tax, total_amount, payment_method, cash_given, change_amount, status, created_at)
values (
  'ord-1001', '#3A-88895',
  '00000000-0000-0000-0000-000000000001',
  'Dine In', '04', 'Budi',
  45000, 4500, 49500,
  'QRIS / E-Wallet', 0, 0,
  'PAID',
  now()
)
on conflict (order_id) do nothing;

insert into public.order_items (order_item_id, order_id, product_id, product_name, variant, quantity, price_at_sale, subtotal, note)
values
  ('item-1', 'ord-1001', 'prod-1', 'Iced Latte',  'Less Sugar, Ice', 2, 15000, 30000, 'Extra ice'),
  ('item-2', 'ord-1001', 'prod-6', 'Croissant',   'Butter',         1, 15000, 15000, null)
on conflict (order_item_id) do nothing;

-- ---------- Sample Stock Logs ----------
insert into public.stock_logs (log_id, stock_id, stock_name, type, quantity, unit, source, reference_code, operator_name, note, created_at)
values
  ('log-1', 'sugar', 'Sugar', 'OUT', 2.0,  'kg',  'POS',                 '#3A-88895',  'Kasir Budi', 'Penjualan minuman shift sore',         now() - interval '2 hour'),
  ('log-2', 'sugar', 'Sugar', 'IN',  10.0, 'kg',  'Restock / Pembelian', '#PO-2026-08','Owner',      'Pembelian stok grosir mingguan',       now() - interval '3 day')
on conflict (log_id) do nothing;

-- ---------- Sample Finance Transactions ----------
insert into public.finance_transactions (transaction_id, user_id, order_id, title, type, category, amount, source, notes, timestamp)
values
  ('tx-001', '00000000-0000-0000-0000-000000000001', 'ord-1001',
   'Iced Latte & Croissant Sales', 'INCOME',  'sales',       49500,  'POS_AUTOMATIC', 'Order #3A-88895',                                now()),
  ('tx-002', '00000000-0000-0000-0000-000000000001', null,
   'Coffee Beans Purchase',        'EXPENSE', 'ingredients', 250000, 'MANUAL',        'Restock 2kg Espresso Blend dari Roastery Lokal',  now() - interval '1 day'),
  ('tx-003', '00000000-0000-0000-0000-000000000001', null,
   'Sugar Purchase',               'EXPENSE', 'ingredients', 170000, 'MANUAL',        'Gula Aren Cair 5 Jerigen',                       now() - interval '2 day')
on conflict (transaction_id) do nothing;

-- ---------- Sample AI Conversation ----------
insert into public.ai_messages (message_id, user_id, sender, text, type, actionPayload, extra_data, timestamp)
values
  ('msg-001', '00000000-0000-0000-0000-000000000001', 'USER',
   'Bagaimana bisnis saya hari ini?', 'text', null, null,
   now() - interval '30 minute'),
  ('msg-002', '00000000-0000-0000-0000-000000000001', 'AI',
   'Kinerja bisnis hari ini tampak baik. Pendapatan telah mencapai Rp1.250.000, naik 12% dibandingkan kemarin.',
   'businessSummary', null,
   '{"revenue":1250000,"profit":450000,"bestSeller":"Iced Latte"}',
   now() - interval '29 minute')
on conflict (message_id) do nothing;

insert into public.ai_actions (action_id, message_id, intent, payload, status, created_at)
values (
  'act-001', 'msg-002', 'ADD_STOCK_AND_EXPENSE',
  '{"actionId":"act-001","intent":"ADD_STOCK_AND_EXPENSE","itemName":"Sugar","quantity":10,"unit":"kg","expenseAmount":170000,"category":"Bahan Baku","status":"confirmed"}',
  'CONFIRMED',
  now() - interval '29 minute'
)
on conflict (action_id) do nothing;