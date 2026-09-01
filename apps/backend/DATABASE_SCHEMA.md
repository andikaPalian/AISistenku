# Database Schema Documentation

This document describes the database schema for the Tiga Angkatan POS system using PostgreSQL with Supabase.

## Setup

Schema belum ter-deploy ke Supabase. Ikuti langkah ini untuk apply:

1. Login ke [Supabase Dashboard](https://supabase.com/dashboard) → pilih project
2. Buka **SQL Editor** (icon terminal di sidebar kiri)
4. Klik **New query**, paste seluruh isi `apps/backend/schema.sql`
5. Klik **Run** (atau `Ctrl+Enter`)
6. Pastikan tidak ada error — akan ada 10 tabel terbuat (`users`, `products`, `stock_items`, `product_recipes`, `orders`, `order_items`, `stock_logs`, `finance_transactions`, `ai_messages`, `ai_actions`) + 4 indexes
7. Verifikasi dengan query `SELECT table_name FROM information_schema.tables WHERE table_schema='public';`
8. Restart backend (`npm run dev`) — log harus menampilkan `✅ Supabase connection verified`

## Extensions

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

## Tables

### 1. users (Integrated with Supabase Auth)

```sql
CREATE TABLE public.users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'owner', -- 'owner' / 'cashier'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 2. products

```sql
CREATE TABLE public.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    category TEXT NOT NULL, -- 'Kopi', 'Non-Kopi', 'Snack', 'Makanan'
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 3. stock_items

```sql
CREATE TABLE public.stock_items (
    stock_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT NOT NULL, -- 'kg', 'L', 'btl', 'g'
    minimum_stock NUMERIC(10, 2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Baik' CHECK (status IN ('Baik', 'Rendah', 'Kritis')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 4. product_recipes

```sql
CREATE TABLE public.product_recipes (
    recipe_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(product_id) ON DELETE CASCADE,
    stock_id UUID NOT NULL REFERENCES public.stock_items(stock_id) ON DELETE CASCADE,
    quantity_required NUMERIC(10, 2) NOT NULL CHECK (quantity_required > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_product_stock UNIQUE (product_id, stock_id)
);
```

### 5. orders

```sql
CREATE TABLE public.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code TEXT NOT NULL UNIQUE, -- Contoh: '#3A-88895'
    user_id UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    payment_method TEXT CHECK (payment_method IN ('Cash', 'QRIS / E-Wallet', 'Debit / Credit Card')),
    status TEXT NOT NULL DEFAULT 'PAID',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 6. order_items

```sql
CREATE TABLE public.order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(product_id) ON DELETE SET NULL,
    variant TEXT, -- Contoh: 'Regular', 'Butter'
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_at_sale NUMERIC(12, 2) NOT NULL CHECK (price_at_sale >= 0),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0)
);
```

### 7. stock_logs

```sql
CREATE TABLE public.stock_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID NOT NULL REFERENCES public.stock_items(stock_id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('IN', 'OUT')),
    quantity NUMERIC(10, 2) NOT NULL,
    source TEXT NOT NULL, -- 'POS', 'MANUAL_ADD', 'AI_AGENT'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 8. finance_transactions

```sql
CREATE TABLE public.finance_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    title TEXT NOT NULL, -- Contoh: 'Iced Latte Sales', 'Coffee Beans Purchase'
    type TEXT NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    category TEXT NOT NULL, -- Contoh: 'Sales', 'Ingredients', 'Utility'
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    source TEXT NOT NULL, -- 'POS_AUTOMATIC', 'MANUAL', 'AI_AGENT'
    notes TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 9. ai_messages

```sql
CREATE TABLE public.ai_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE,
    sender TEXT NOT NULL CHECK (sender IN ('USER', 'AI')),
    text TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 10. ai_actions

```sql
CREATE TABLE public.ai_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES public.ai_messages(message_id) ON DELETE CASCADE,
    intent TEXT NOT NULL, -- Contoh: 'ADD_STOCK', 'ADD_EXPENSE'
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## Indexes

```sql
CREATE INDEX idx_orders_created_at ON public.orders(created_at);
CREATE INDEX idx_finance_timestamp ON public.finance_transactions(timestamp);
CREATE INDEX idx_stock_logs_stock_id ON public.stock_logs(stock_id);
CREATE INDEX idx_ai_messages_user_id ON public.ai_messages(user_id);
```

## Relationships Summary

- `users` → `orders` (1:N, user_id FK, ON DELETE SET NULL)
- `users` → `finance_transactions` (1:N, user_id FK, ON DELETE SET NULL)
- `users` → `ai_messages` (1:N, user_id FK, ON DELETE CASCADE)
- `products` → `product_recipes` (1:N, product_id FK, ON DELETE CASCADE)
- `products` → `order_items` (1:N, product_id FK, ON DELETE SET NULL)
- `stock_items` → `product_recipes` (1:N, stock_id FK, ON DELETE CASCADE)
- `stock_items` → `stock_logs` (1:N, stock_id FK, ON DELETE CASCADE)
- `orders` → `order_items` (1:N, order_id FK, ON DELETE CASCADE)
- `orders` → `finance_transactions` (1:N, order_id FK, ON DELETE SET NULL)
- `ai_messages` → `ai_actions` (1:N, message_id FK, ON DELETE CASCADE)

## Enum-like Values

### users.role
- `owner`
- `cashier`

### products.category
- `Kopi`
- `Non-Kopi`
- `Snack`
- `Makanan`

### stock_items.unit
- `kg`
- `L`
- `btl`
- `g`

### stock_items.status
- `Baik`
- `Rendah`
- `Kritis`

### orders.payment_method
- `Cash`
- `QRIS / E-Wallet`
- `Debit / Credit Card`

### orders.status
- `PAID` (default)

### stock_logs.type
- `IN`
- `OUT`

### stock_logs.source
- `POS`
- `MANUAL_ADD`
- `AI_AGENT`

### finance_transactions.type
- `INCOME`
- `EXPENSE`

### finance_transactions.source
- `POS_AUTOMATIC`
- `MANUAL`
- `AI_AGENT`

### ai_messages.sender
- `USER`
- `AI`

### ai_actions.status
- `PENDING`
- `CONFIRMED`
- `CANCELLED`