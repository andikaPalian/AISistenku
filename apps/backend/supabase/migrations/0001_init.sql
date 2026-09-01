-- 0001_init.sql
-- Schema initialization for Tiga Angkatan backend
-- Run in Supabase SQL Editor

create extension if not exists "pgcrypto";

-- USERS
create table if not exists public.users (
  user_id uuid primary key default gen_random_uuid(),
  email text unique,
  name text,
  role text default 'owner',
  created_at timestamptz not null default now()
);

-- PRODUCTS
create table if not exists public.products (
  product_id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  price numeric not null default 0,
  default_variant text,
  image_url text,
  code text,
  unit text,
  current_stock numeric default 0,
  min_stock numeric default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_products_category on public.products(category);

-- STOCK ITEMS
create table if not exists public.stock_items (
  stock_id text primary key,
  name text not null,
  category text,
  current_stock numeric default 0,
  min_stock numeric default 0,
  unit text,
  cost_per_unit numeric default 0,
  supplier text,
  note text,
  updated_at timestamptz not null default now()
);
create index if not exists idx_stock_items_category on public.stock_items(category);

-- PRODUCT RECIPES (links products to stock items)
create table if not exists public.product_recipes (
  recipe_id text primary key,
  product_id uuid references public.products(product_id) on delete cascade,
  stock_id text references public.stock_items(stock_id) on delete cascade,
  quantity_required numeric not null default 0
);

-- ORDERS
create table if not exists public.orders (
  order_id text primary key,
  order_code text,
  user_id uuid,
  order_type text,
  table_number text,
  customer_name text,
  subtotal numeric default 0,
  tax numeric default 0,
  total_amount numeric default 0,
  payment_method text,
  cash_given numeric default 0,
  change_amount numeric default 0,
  status text default 'PAID',
  created_at timestamptz not null default now()
);
create index if not exists idx_orders_created_at on public.orders(created_at desc);

-- ORDER ITEMS
create table if not exists public.order_items (
  order_item_id text primary key,
  order_id text references public.orders(order_id) on delete cascade,
  product_id uuid,
  product_name text,
  variant text,
  quantity numeric default 1,
  price_at_sale numeric default 0,
  subtotal numeric default 0,
  note text
);
create index if not exists idx_order_items_order_id on public.order_items(order_id);

-- FINANCE TRANSACTIONS
create table if not exists public.finance_transactions (
  transaction_id text primary key,
  user_id uuid,
  order_id text,
  title text,
  type text,
  category text,
  amount numeric default 0,
  source text,
  notes text,
  timestamp timestamptz not null default now()
);
create index if not exists idx_finance_timestamp on public.finance_transactions(timestamp desc);
create index if not exists idx_finance_type on public.finance_transactions(type);

-- STOCK LOGS
create table if not exists public.stock_logs (
  log_id text primary key,
  stock_id text,
  stock_name text,
  type text,
  quantity numeric default 0,
  unit text,
  source text,
  reference_code text,
  operator_name text,
  note text,
  created_at timestamptz not null default now()
);
create index if not exists idx_stock_logs_stock_id on public.stock_logs(stock_id);
create index if not exists idx_stock_logs_created_at on public.stock_logs(created_at desc);

-- AI MESSAGES
create table if not exists public.ai_messages (
  message_id text primary key,
  user_id uuid,
  sender text,
  text text,
  type text,
  actionPayload jsonb,
  extra_data jsonb,
  timestamp timestamptz not null default now()
);
create index if not exists idx_ai_messages_timestamp on public.ai_messages(timestamp);

-- AI ACTIONS
create table if not exists public.ai_actions (
  action_id text primary key,
  message_id text,
  intent text,
  payload jsonb,
  status text,
  created_at timestamptz not null default now()
);

-- RLS OFF (service role key bypasses RLS anyway, but keep it simple)
alter table public.users disable row level security;
alter table public.products disable row level security;
alter table public.stock_items disable row level security;
alter table public.product_recipes disable row level security;
alter table public.orders disable row level security;
alter table public.order_items disable row level security;
alter table public.finance_transactions disable row level security;
alter table public.stock_logs disable row level security;
alter table public.ai_messages disable row level security;
alter table public.ai_actions disable row level security;
