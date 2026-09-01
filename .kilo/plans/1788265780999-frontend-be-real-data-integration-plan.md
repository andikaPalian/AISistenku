# Frontend ↔ Backend Real-Data Integration Plan

Goal: replace `apps/frontend/src/mockData.ts` with live data from the existing Express + Supabase backend (`apps/backend/`), including a JWT login flow, for **all five screens** (Home, POS, Stock, Finance, AI Assistant).

---

## 1. Decisions Locked

- **Auth strategy:** Direct `fetch` from frontend to backend; backend uses Supabase Auth via the service role to issue/validate JWTs. Bearer token stored in `localStorage` and sent as `Authorization: Bearer <token>` on every API call.
- **Scope:** Every screen (Home, POS, Stock, Finance, AI Assistant) reads/writes real backend data.
- **Data layer:** Add seed/migration SQL so Supabase tables match what the controllers already query (`products`, `stock_items`, `orders`, `order_items`, `finance_transactions`, `stock_logs`, `ai_messages`, `ai_actions`, `users`).

---

## 2. Backend Changes (required first)

### 2.1 Add login route
The middleware (`apps/backend/src/middleware/auth.js:28`) already validates Supabase JWTs, but no route issues one. Add:

- `POST /api/auth/login` — accepts `{ email, password }`, calls `supabase.auth.signInWithPassword`, returns `{ access_token, refresh_token, user }`.
- `POST /api/auth/register` — accepts `{ email, password, name }`, calls `supabase.auth.signUp`, returns the same shape.
- `POST /api/auth/logout` — optional, no-op server-side.

Place under `apps/backend/src/controllers/authController.js` (extend) and `apps/backend/src/routes/auth.js` (extend). Both endpoints must be mounted **before** `authMiddleware` — split into `router.post('/login', ...)` (no middleware) and `router.post('/register', ...)` (no middleware), keep `router.get('/me', authMiddleware, getMe)`.

### 2.2 Response-shape normalization
Backend currently returns wrappers like `{ products: [...] }`, `{ stocks: [...] }`, `{ orders: [...] }`, `{ transactions: [...] }`, `{ messages: [...] }`, `{ summary: {...} }`. The frontend adapter layer will read these wrappers. No controller changes required.

### 2.3 CORS
`apps/backend/src/index.js:15` uses `cors()` with default options. Change to allow the frontend origin from env (`process.env.FRONTEND_ORIGIN`, default `http://localhost:5173`) and explicitly allow `Authorization` header.

### 2.4 Seed/Migration SQL (new file)
Create `apps/backend/supabase/migrations/0001_init.sql` covering:

- `products (product_id uuid pk, name text, category text, price numeric, default_variant text, image_url text, code text, unit text, current_stock numeric, min_stock numeric, created_at timestamptz)`
- `stock_items (stock_id uuid pk, name text, category text, current_stock numeric, min_stock numeric, unit text, cost_per_unit numeric, supplier text, note text, updated_at timestamptz)`
- `orders (order_id text pk, order_code text, user_id uuid, order_type text, table_number text, customer_name text, subtotal numeric, tax numeric, total_amount numeric, payment_method text, cash_given numeric, change_amount numeric, status text, created_at timestamptz)`
- `order_items (order_item_id text pk, order_id text fk, product_id uuid, product_name text, variant text, quantity numeric, price_at_sale numeric, subtotal numeric, note text)`
- `finance_transactions (transaction_id text pk, user_id uuid, order_id text, title text, type text, category text, amount numeric, source text, notes text, timestamp timestamptz)`
- `stock_logs (log_id text pk, stock_id text, stock_name text, type text, quantity numeric, unit text, source text, reference_code text, operator_name text, note text, created_at timestamptz)`
- `ai_messages (message_id text pk, user_id uuid, sender text, text text, type text, actionPayload jsonb, extra_data jsonb, timestamp timestamptz)`
- `ai_actions (action_id text pk, message_id text, intent text, payload jsonb, status text, created_at timestamptz)`
- `users (user_id uuid pk, email text, name text, role text, created_at timestamptz)`
- Enable RLS but add service-role bypass policy OR keep service-role client for writes (already used).
- Add `0002_seed.sql` to insert the rows currently in `mockData.ts` (9 products mapped to `products`, 9 stock_items, 5 finance_transactions, 3 stock alerts derived from current_stock ≤ min_stock, 1 ai_message). Money/category must match backend field names (`type` = INCOME/EXPENSE, `category` = sales/operational, etc.).

Add `apps/backend/scripts/seed.mjs` that runs the SQL files against the configured Supabase project using the service-role key.

---

## 3. Frontend Changes (`apps/frontend/src`)

### 3.1 New files
- `lib/api.ts` — small typed `fetch` wrapper:
  - `apiGet<T>(path)`, `apiPost<T>(path, body)`, `apiPut<T>(path, body)`, `apiDelete<T>(path)`
  - Reads `VITE_API_BASE_URL` (default `http://localhost:3000/api`) from `import.meta.env`
  - Reads token from `localStorage.getItem('ta_token')`, attaches `Authorization` header
  - On `401` clears token and redirects to `/login`
  - Centralized error throwing with `{ error, status }`
- `lib/auth.ts` — `login`, `register`, `logout`, `getMe`, `getToken`, `setToken`, `clearToken`. Persists token in `localStorage` (`ta_token`, `ta_user`).
- `lib/adapters.ts` — pure functions converting backend rows → frontend `Product` / `Transaction` / `StockAlert` / `AiChatMessage` types. E.g.:
  - `adaptProduct(row)` → `{ id: row.product_id, code: row.code, name, category, price, stock: row.current_stock, minStock: row.min_stock, unit }`
  - `adaptStockAlert(item)` → computed when `current_stock ≤ min_stock`
  - `adaptTransaction(row)` → maps `finance_transactions` row to `Transaction`
  - `adaptAiMessage(row)` → maps `ai_messages` row to `AiChatMessage` (handles `sender: 'AI' | 'USER'`, `actionPayload`)
- `hooks/useProducts.ts`, `useStocks.ts`, `useTransactions.ts`, `useDashboard.ts`, `useAiMessages.ts` — each exposes `{ data, loading, error, refresh }`. They call the API on mount and expose mutation helpers (`createOrder`, `restockStock`, `createTransaction`, `sendChatMessage`, `confirmAiAction`).
- `screens/LoginScreen.tsx` (+ `.css`) — email/password form, calls `login()`, stores token, navigates to Home.
- `routes/ProtectedApp.tsx` — wraps `ShellLayout`, redirects to `LoginScreen` when no token.

### 3.2 Modify existing files
- `App.tsx` — choose between `LoginScreen` and `ProtectedApp` based on token presence.
- `types/index.ts` — keep current types; add optional backend fields where useful (`backendId?: string`).
- `components/layout/ShellLayout.tsx` — replace each `useState<Product[]>(INITIAL_PRODUCTS)` etc. with the corresponding hook. Pass `loading`/`error` flags down to screens for skeleton/error UI. Remove `INITIAL_PRODUCTS`, `INITIAL_TRANSACTIONS`, `STOCK_ALERTS`, `INITIAL_CHAT_MESSAGES` imports.
- `screens/HomeScreen.tsx` — read from `useDashboard()` (`/api/dashboard/overview`) for revenue/activity/AI insight, from `useStocks()` for low-stock alerts.
- `screens/PosScreen.tsx` — products from `useProducts()`. On checkout, call `POST /api/orders` with `{ items: [{ product_id, quantity, price, subtotal }], paymentMethod, orderType, subtotal, tax, total, cashGiven, change }` matching `orderController.createOrder` body. On success, refresh stocks + transactions. Display server-returned `order.order_code` instead of locally-generated invoice number.
- `screens/StockScreen.tsx` — list from `useStocks()`. Wire mutations to `POST /api/stocks`, `PUT /api/stocks/:id`, `DELETE /api/stocks/:id`, `POST /api/stocks/:id/restock`, `POST /api/stocks/:id/adjust`.
- `screens/FinanceScreen.tsx` — summary from `GET /api/finance/summary?period=...`, list from `GET /api/finance/transactions`, create via `POST /api/finance/transactions`, delete via `DELETE /api/finance/transactions/:id`. Map backend `{ title, type, category, amount, timestamp, notes }` → `{ invoiceNo, date, time, type, category, amount, paymentMethod, status, notes }` via `adaptTransaction`.
- `screens/AiAssistantScreen.tsx` — load messages via `GET /api/ai/messages`. Send via `POST /api/ai/chat`. Confirm action via `POST /api/ai/actions/:actionId/confirm`. Clear via `DELETE /api/ai/messages`. Render `recommendations` from the existing `actionPayload`-shaped response (build cards from `type === 'stockAlert' | 'actionConfirm' | 'contentCaption' | 'businessSummary'`).

### 3.3 Frontend env
Create `apps/frontend/.env.example` with `VITE_API_BASE_URL=http://localhost:3000/api`. Document in `apps/frontend/README.md` (only if missing — check first; create only if not present).

---

## 4. Risk Register

| Risk | Mitigation |
|---|---|
| Backend controllers have hard-coded fallback numbers (`dashboardController.js:7-12`) that ignore real DB rows | Out of scope for this plan; leave fallback for `INCOME=0` case but rely on real Supabase data once seeded. Document as a follow-up. |
| Field-name drift between backend rows and frontend types (e.g. `product_id` vs `id`) | Centralize in `lib/adapters.ts`; never read raw backend fields in screens. |
| `authMiddleware` allows unauthenticated requests when no `Authorization` header is sent (`middleware/auth.js:6-14`) | Frontend always sends the Bearer token; do not rely on the fallback path. |
| CORS preflight blocked on `Authorization` header | Update `cors()` config to allow `http://localhost:5173` and `Authorization`. |
| `CREATE /api/orders` body uses `product_id` not `product.id` | Frontend cart must send `product_id`. Update `PosScreen` checkout payload. |
| `financeController.getTransactions` filters by `t.title.toLowerCase().includes(q)` | Search bar in `FinanceScreen` should call `GET /api/finance/transactions?query=...`. |
| Stock deduction via `productRecipes` (`orderController.js:67`) won't fire if `product_recipes` table is empty | Add to migration and seed; otherwise orders won't reduce stock. Plan includes `product_recipes` in `0001_init.sql` + sample rows in `0002_seed.sql` for the 9 seeded products. |

---

## 5. Validation Plan

1. **Backend boots clean:** `npm run dev` in `apps/backend`. `/health` returns `{ status: 'ok', database: 'initialized' }`.
2. **Seed runs:** `node apps/backend/scripts/seed.mjs` exits 0. Supabase Studio shows rows in `products` (9), `stock_items` (9), `finance_transactions` (5), `ai_messages` (1).
3. **Auth:** `curl -X POST :3000/api/auth/login -d '{"email":"...","password":"..."}' -H 'content-type: application/json'` returns `{ access_token, user }`.
4. **GET with token:** `curl -H "Authorization: Bearer <token>" :3000/api/products` returns the seeded 9 products wrapped as `{ products: [...] }`.
5. **POST order:** `curl -X POST :3000/api/orders -H "Authorization: Bearer <token>" -d '{...}'` returns `201` and `stock_items.current_stock` decreases by recipe quantity in Supabase.
6. **Frontend smoke:** `npm run dev` in `apps/frontend` (default port 5173).
   - Visit `/` → redirected to login.
   - Login with seeded owner email → redirected to Home; `dailyRevenue.amount` matches seeded finance rows.
   - POS: add 3 items → checkout → success toast shows backend `order_code`; Stock tab shows reduced quantities; Finance tab shows new INCOME row.
   - Stock: click "Restock" → enter `quantity=10` → success; Finance tab shows new EXPENSE row.
   - AI: send "stok" → backend returns `stockAlert` shape; UI renders list. Send "beli gula 5kg 170rb" → confirm button works, mutation visible in Stock + Finance.
   - Network tab: every request has `Authorization: Bearer …`; no 4xx in console.

---

## 6. Out of Scope

- Real-time updates (Supabase realtime channels). Plan uses polling on tab focus / pull-to-refresh hooks.
- Mobile app (`apps/mobile/`) integration — separate effort.
- Production deployment, secrets management, rate limiting.
- Replacing remaining hard-coded fallbacks in `dashboardController.js` and `financeController.getFinanceSummary` (chart points / peak hours / top products still come from the static arrays).

---

## 7. Ordered Implementation Tasks (for the executor)

1. Create `apps/backend/supabase/migrations/0001_init.sql` with all tables, FKs, indexes, RLS disabled for service-role usage.
2. Create `apps/backend/supabase/migrations/0002_seed.sql` mirroring `apps/frontend/src/mockData.ts` and including `product_recipes` rows that connect each `products.product_id` to one `stock_items.stock_id`.
3. Create `apps/backend/scripts/seed.mjs` and run it; verify row counts via `/health`.
4. Add `POST /api/auth/login` and `POST /api/auth/register` to `apps/backend/src/controllers/authController.js` and `apps/backend/src/routes/auth.js` (no middleware).
5. Tighten CORS in `apps/backend/src/index.js` to allow `Authorization` from `process.env.FRONTEND_ORIGIN`.
6. Add `apps/frontend/src/lib/api.ts`, `lib/auth.ts`, `lib/adapters.ts`.
7. Add `apps/frontend/src/screens/LoginScreen.tsx` + `.css`; gate `App.tsx` on token presence.
8. Add `apps/frontend/src/hooks/useProducts.ts`, `useStocks.ts`, `useTransactions.ts`, `useDashboard.ts`, `useAiMessages.ts`.
9. Wire each screen to its hook(s) and remove `mockData` imports.
10. Manual validation pass per §5; fix adapter field drift discovered during testing.