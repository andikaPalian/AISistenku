-- =============================================================
-- Tiga Angkatan — Initial Schema
-- =============================================================
-- Run via Supabase SQL Editor or supabase CLI.
-- RLS is enabled but service_role key bypasses it, so backend
-- can write freely while anon key is read-restricted if you ever
-- expose Supabase directly to the browser.

create extension if not exists "pgcrypto";

-- ---------- users (mirror of auth.users) ----------
create table if not exists public.users (
  user_id   uuid primary key,
  email     text not null unique,
  name      text not null default 'Owner',
  role      text not null default 'owner',
  created_at timestamptz not null default now()
);

-- ---------- products (POS menu) ----------
create table if not exists public.products (
  product_id     text primary key,
  name           text not null,
  category       text not null,
  price          numeric not null default 0,
  default_variant text,
  image_url      text,
  code           text,
  unit           text default 'cup',
  current_stock  numeric default 0,
  min_stock      numeric default 0,
  created_at     timestamptz default now()
);

-- ---------- stock_items (raw materials / inventory) ----------
create table if not exists public.stock_items (
  stock_id       text primary key,
  name           text not null,
  category       text,
  current_stock  numeric not null default 0,
  min_stock      numeric not null default 0,
  unit           text default 'kg',
  cost_per_unit  numeric default 0,
  supplier       text,
  note           text,
  image_url      text,
  updated_at     timestamptz default now()
);

-- ---------- product_recipes (POS auto-deduct) ----------
create table if not exists public.product_recipes (
  recipe_id        text primary key,
  product_id       text references public.products(product_id) on delete cascade,
  stock_id         text references public.stock_items(stock_id) on delete cascade,
  quantity_required numeric not null
);

-- ---------- orders + order_items ----------
create table if not exists public.orders (
  order_id      text primary key,
  order_code    text not null,
  user_id       uuid references public.users(user_id),
  order_type    text default 'Dine In',
  table_number  text,
  customer_name text,
  subtotal      numeric default 0,
  tax           numeric default 0,
  total_amount  numeric default 0,
  payment_method text default 'Cash',
  cash_given    numeric default 0,
  change_amount numeric default 0,
  status        text default 'PAID',
  created_at    timestamptz default now()
);

create table if not exists public.order_items (
  order_item_id text primary key,
  order_id      text references public.orders(order_id) on delete cascade,
  product_id    text references public.products(product_id),
  product_name  text not null,
  variant       text,
  quantity      numeric not null,
  price_at_sale numeric not null,
  subtotal      numeric not null,
  note          text
);

-- ---------- stock_logs ----------
create table if not exists public.stock_logs (
  log_id          text primary key,
  stock_id        text references public.stock_items(stock_id) on delete cascade,
  stock_name      text,
  type            text check (type in ('IN','OUT')),
  quantity        numeric not null,
  unit            text,
  source          text,
  reference_code  text,
  operator_name   text,
  note            text,
  created_at      timestamptz default now()
);

-- ---------- finance_transactions ----------
create table if not exists public.finance_transactions (
  transaction_id text primary key,
  user_id        uuid references public.users(user_id),
  order_id       text references public.orders(order_id) on delete set null,
  title          text not null,
  type           text check (type in ('INCOME','EXPENSE')) not null,
  category       text not null,
  amount         numeric not null,
  source         text default 'MANUAL',
  notes          text,
  timestamp      timestamptz default now()
);

-- ---------- ai_messages + ai_actions ----------
create table if not exists public.ai_messages (
  message_id    text primary key,
  user_id       uuid references public.users(user_id),
  sender        text check (sender in ('USER','AI')) not null,
  text          text not null,
  type          text default 'text',
  actionPayload jsonb,
  extra_data    jsonb,
  timestamp     timestamptz default now()
);

create table if not exists public.ai_actions (
  action_id  text primary key,
  message_id text references public.ai_messages(message_id) on delete cascade,
  intent     text not null,
  payload    jsonb,
  status     text default 'PENDING',
  created_at timestamptz default now()
);

-- ---------- indexes ----------
create index if not exists idx_stock_logs_stock    on public.stock_logs(stock_id);
create index if not exists idx_finance_timestamp  on public.finance_transactions(timestamp desc);
create index if not exists idx_ai_messages_ts     on public.ai_messages(timestamp);
create index if not exists idx_orders_created_at  on public.orders(created_at desc);

-- ---------- RLS ----------
-- Enabled but service_role bypasses, so backend is unaffected.
alter table public.products             enable row level security;
alter table public.stock_items          enable row level security;
alter table public.product_recipes      enable row level security;
alter table public.orders               enable row level security;
alter table public.order_items          enable row level security;
alter table public.stock_logs           enable row level security;
alter table public.finance_transactions enable row level security;
alter table public.ai_messages          enable row level security;
alter table public.ai_actions           enable row level security;
alter table public.users                enable row level security;