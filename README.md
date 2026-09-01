# Tiga Angkatan — Monorepo

Monorepo untuk aplikasi **Tiga Angkatan** menggunakan [Turborepo](https://turbo.build/).

## Stack

| Layer    | Tech                        |
|----------|-----------------------------|
| Monorepo | Turborepo + npm workspaces  |
| Backend  | Express.js (Docker)         |
| Frontend | React + Vite                |
| Mobile   | Flutter                     |
| Database | Supabase (PostgreSQL)       |

## Struktur

```
apps/
  backend/    → Express.js API (Docker)
  frontend/   → React + Vite
  mobile/     → Flutter
packages/
  shared/     → Shared constants & utilities
```

## Cara Menjalankan

### Prerequisites
- Node.js >= 18
- Docker & Docker Compose
- Flutter SDK
- Supabase project (isi `.env` setelah clone)

### Install dependencies

```bash
npm install
```

### Development

```bash
# Jalankan semua apps sekaligus
npm run dev

# Atau per-app
cd apps/backend  && npm run dev
cd apps/frontend && npm run dev
cd apps/mobile   && flutter run
```

### Backend via Docker

```bash
docker compose up --build
```

### Build semua

```bash
npm run build
```

## Environment Variables

Copy `.env.example` ke `.env` di masing-masing folder dan isi sesuai project Supabase Anda.

```bash
cp apps/backend/.env.example apps/backend/.env
cp apps/frontend/.env.example apps/frontend/.env
```
