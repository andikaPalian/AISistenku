-- Tiga Angkatan PostgreSQL / Supabase Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. users
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'cashier')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. products
CREATE TABLE IF NOT EXISTS public.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    category TEXT NOT NULL CHECK (category IN ('Kopi', 'Non-Kopi', 'Snack', 'Makanan')),
    image_url TEXT,
    default_variant TEXT DEFAULT 'Regular',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. stock_items
CREATE TABLE IF NOT EXISTS public.stock_items (
    stock_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Topping & Lainnya',
    current_stock NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    min_stock NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'kg',
    cost_per_unit NUMERIC(12, 2) NOT NULL DEFAULT 0,
    supplier TEXT DEFAULT 'Supplier Utama',
    note TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. product_recipes
CREATE TABLE IF NOT EXISTS public.product_recipes (
    recipe_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(product_id) ON DELETE CASCADE,
    stock_id UUID NOT NULL REFERENCES public.stock_items(stock_id) ON DELETE CASCADE,
    quantity_required NUMERIC(10, 2) NOT NULL CHECK (quantity_required > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_product_stock UNIQUE (product_id, stock_id)
);

-- 5. orders
CREATE TABLE IF NOT EXISTS public.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    order_type TEXT DEFAULT 'Dine In' CHECK (order_type IN ('Dine In', 'Take Away')),
    table_number TEXT,
    customer_name TEXT,
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    tax NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    payment_method TEXT CHECK (payment_method IN ('Cash', 'QRIS / E-Wallet', 'Debit / Credit Card')),
    cash_given NUMERIC(12, 2) DEFAULT 0,
    change_amount NUMERIC(12, 2) DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'PAID',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. order_items
CREATE TABLE IF NOT EXISTS public.order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(product_id) ON DELETE SET NULL,
    product_name TEXT,
    variant TEXT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_at_sale NUMERIC(12, 2) NOT NULL CHECK (price_at_sale >= 0),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    note TEXT
);

-- 7. stock_logs
CREATE TABLE IF NOT EXISTS public.stock_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_id UUID NOT NULL REFERENCES public.stock_items(stock_id) ON DELETE CASCADE,
    stock_name TEXT,
    type TEXT NOT NULL CHECK (type IN ('IN', 'OUT')),
    quantity NUMERIC(10, 2) NOT NULL,
    unit TEXT,
    source TEXT NOT NULL,
    reference_code TEXT,
    operator_name TEXT DEFAULT 'Kasir',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. finance_transactions
CREATE TABLE IF NOT EXISTS public.finance_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    category TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    source TEXT NOT NULL CHECK (source IN ('POS_AUTOMATIC', 'MANUAL', 'AI_AGENT')),
    notes TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. ai_messages
CREATE TABLE IF NOT EXISTS public.ai_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE,
    sender TEXT NOT NULL CHECK (sender IN ('USER', 'AI')),
    text TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text',
    extra_data JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. ai_actions
CREATE TABLE IF NOT EXISTS public.ai_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES public.ai_messages(message_id) ON DELETE CASCADE,
    intent TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);
CREATE INDEX IF NOT EXISTS idx_finance_timestamp ON public.finance_transactions(timestamp);
CREATE INDEX IF NOT EXISTS idx_stock_logs_stock_id ON public.stock_logs(stock_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_user_id ON public.ai_messages(user_id);
