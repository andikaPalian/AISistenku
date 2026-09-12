# 🌟 AISistenku — Tiga Angkatan

> **Modern Omnichannel Point of Sale (POS), Real-Time BOM Recipe Inventory Management, & AI Business Copilot for Indonesian F&B and Retail MSMEs (UMKM).**

[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express-5.x-black?logo=express&logoColor=white)](https://expressjs.com/)
[![Prisma ORM](https://img.shields.io/badge/Prisma-7.x-2D3748?logo=prisma&logoColor=white)](https://www.prisma.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react&logoColor=black)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-6.x-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-CDN-3448C5?logo=cloudinary&logoColor=white)](https://cloudinary.com/)
[![Google Gemini](https://img.shields.io/badge/Google_Gemini-2.0-8E75B2?logo=google&logoColor=white)](https://ai.google.dev/)
[![Turborepo](https://img.shields.io/badge/Turborepo-Monorepo-EF4444?logo=turborepo&logoColor=white)](https://turbo.build/)
[![Tests](https://img.shields.io/badge/Tests-37%2F37%20Passed-success?logo=github-actions&logoColor=white)](#-pengujian--quality-assurance)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 Daftar Isi

- [Tentang Proyek](#-tentang-proyek)
- [Fitur Utama](#-fitur-utama)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Struktur Monorepo](#-struktur-monorepo)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
- [Panduan Instalasi & Menjalankan](#-panduan-instalasi--menjalankan)
- [Akun Demo Pengujian](#-akun-demo-pengujian)
- [Ringkasan Rute API (Endpoints)](#-ringkasan-rute-api-endpoints)
- [Pengujian & Quality Assurance](#-pengujian--quality-assurance)
- [Desain & Konsep Tema](#-desain--konsep-tema)
- [Rencana Pengembangan (Roadmap)](#-rencana-pengembangan-roadmap)
- [Lisensi](#-lisensi)

---

## 💡 Tentang Proyek

**AISistenku (Tiga Angkatan)** adalah ekosistem digital terintegrasi yang dirancang khusus untuk mentransformasi operasional bisnis kafe, restoran (*F&B*), dan toko ritel UMKM di Indonesia. 

Banyak pelaku usaha UMKM menghadapi kendala operasional klasik:
1. **Kebocoran Stok Bahan Mentah**: Sistem kasir biasa hanya mencatat menu yang terjual tanpa memotong takaran bahan mentah di dapur (misalnya biji kopi, susu, sirup).
2. **Kasir Kaku & Lambat**: Proses checkout yang rumit memperpanjang antrean pelanggan di jam-jam sibuk (*peak hours*).
3. **Ketiadaan Analisis Data**: Pemilik usaha kesulitan membaca pola penjualan, menentukan kapan harus belanja bahan baku, atau membuat konten promosi yang menarik.

**AISistenku** memadukan aplikasi **Kasir Cepat (POS)**, **Automasi Pemotongan Bahan Resep (BOM Engine)**, **Laporan Finansial Real-Time**, dan **Asisten AI Pintar (LLM)** dalam satu arsitektur terpadu berbasis web dan aplikasi mobile native.

---

## ✨ Fitur Utama

### ⚡ 1. Point of Sale (POS) — Kasir Cepat & Responsif
- **Multi-Order Type**: Mendukung pesanan *Dine-In* (Makan di Tempat) dan *Takeaway* (Bawa Pulang).
- **Pencarian & Filter Cepat**: Filter kategori instan (Kopi, Non-Kopi, Makanan, Snack) dengan pencarian teks responsif.
- **Cart & Dynamic Pricing**: Keranjang belanja interaktif dengan kalkulasi otomatis subtotal, pajak PB1 10%, dan diskon.
- **Multi-Metode Pembayaran**:
  - 💵 **Tunai**: Dilengkapi saran nominal cepat (*quick cash buttons*) dan penghitungan uang kembalian otomatis.
  - 📱 **QRIS Dinamis**: Tampilan QR code siap scan untuk e-wallet (GoPay, OVO, Dana, ShopeePay).
  - 🏦 **Virtual Account / Transfer Bank**: Pilihan otomatis nomor VA BCA, Mandiri, BRI, dan BNI.
- **Sinkronisasi Stok Instan**: Stok produk di kasir langsung berkurang secara lokal saat transaksi selesai sebelum disinkronkan ke server.

### 📦 2. Real-Time BOM Recipe & Inventory Management
- **Bill of Materials (BOM) Recipe Engine**: Setiap menu dapat dikaitkan dengan komposisi bahan mentah di gudang.
  > *Contoh*: Penjualan 1 cup *Kopi Susu Gula Aren* secara otomatis memotong:
  > - `18 gram` Biji Kopi Espresso
  > - `120 ml` Susu Segar (Fresh Milk)
  > - `20 ml` Sirup Gula Aren
- **Pencatatan Riwayat Stok Otomatis (Stock Audit Logs)**: Setiap pergerakan stok dicatat dengan sumber mutasi (`ORDER_DEDUCTION`, `RESTOCK`, `MANUAL`, `AI_AGENT`).
- **Restock & Penyesuaian Stok (Adjustment)**: Form penambahan stok bahan dari supplier serta penyesuaian selisih stok fisik disertai alasan audit.
- **Peringatan Stok Menipis (*Low Stock Alert*)**: Penanda visual merah ketika persediaan mendekati atau di bawah batas minimum (`minStock`).

### 🤖 3. AISisten — AI Business Copilot
- **Integrasi LLM Canggih**: Didukung oleh **Google Gemini** dan **KelontongAI (`mimo-v2.5`)**.
- **Percakapan Kontekstual Alami**: Interaksi chat langsung berbahasa Indonesia ramah tanpa template kaku.
- **Autonomous Action Execution**:
  - *Cek Status Stok*: Menampilkan status stok barang gudang terkini.
  - *Saran Restock*: Menghitung kebutuhan belanja bahan baku berdasarkan tren penjualan.
  - *Analisis Finansial*: Memberikan evaluasi performa penjualan dan laba/rugi harian.
  - *Generator Konten Promosi*: Membuat ide caption media sosial (Instagram/TikTok/WhatsApp Story) dan ide promo diskon otomatis.

### ☁️ 4. Cloudinary Enterprise Media Cloud
- **Zero-Disk Streaming**: Server backend tidak menyimpan file fisik sementara ke harddisk lokal (`multer.memoryStorage()` + `upload_stream`), sangat aman dan *stateless* untuk cloud container (Docker, Railway, Cloud Run).
- **Auto WebP/AVIF Transformation**: Konversi otomatis ke format generasi terbaru dengan kualitas optimal (`quality: auto:good`, `fetch_format: auto`), menghemat bandwidth hingga 80%.
- **Multi-Tenant Folder Isolation**: Aset tersimpan rapi per bisnis (`tiga-angkatan/products/:businessId`) dan per akun pengguna (`tiga-angkatan/avatars/:userId`).
- **Smart Face-Centering Crop**: Algoritma AI Cloudinary otomatis mendeteksi wajah dan memotong avatar profil berbentuk lingkaran sempurna.
- **Dual Flow**:
  - *Signed Client Upload* pada Web Frontend untuk efisiensi bandwidth server.
  - *Multipart Stream Upload* pada Flutter Mobile dari galeri atau kamera HP.

### 📊 5. Financial Analytics & Cash Flow Management
- **Ringkasan Finansial Komprehensif**: Saldo kas aktif, total pemasukan, total pengeluaran, dan laba operasional bersih.
- **Grafik Tren Penjualan Interaktif**: Visualisasi histori omzet harian, mingguan, dan bulanan (*Chart.js* & Custom Painters).
- **Pencatatan Otomatis dari POS**: Setiap transaksi kasir otomatis membukukan jurnal pemasukan (`POS_AUTOMATIC`) ke neraca keuangan toko.

---

## 🏗️ Arsitektur Sistem

```mermaid
flowchart TD
    subgraph Clients["Klien Pengguna"]
        WEB["🌐 Web Dashboard<br/>(React + Vite + Tailwind)"]
        MOB["📱 Mobile App<br/>(Flutter Android / iOS)"]
    end

    subgraph Gateway["Backend Gateway & Middleware"]
        API["⚡ Express.js API Server (Port 3000)"]
        AUTH["🔒 JWT & RBAC Middleware"]
        TENANT["🏢 Tenant Context Guard (X-Business-Id)"]
    end

    subgraph Services["Domain Modules"]
        POS_SRV["🛒 Order & POS Service"]
        BOM_SRV["📦 Stock & BOM Recipe Engine"]
        FIN_SRV["💰 Finance & Cashflow Service"]
        AI_SRV["🤖 AI Assistant Service"]
        UPL_SRV["☁️ Cloudinary Upload Service"]
    end

    subgraph External["Layanan Eksternal & Basis Data"]
        DB[("🐘 PostgreSQL Database<br/>(Prisma ORM 7)")]
        CDN["☁️ Cloudinary Media CDN"]
        AI_LLM["🧠 Google Gemini / KelontongAI"]
    end

    WEB -->|REST / JSON| API
    MOB -->|REST / Multipart| API

    API --> AUTH --> TENANT
    TENANT --> POS_SRV & BOM_SRV & FIN_SRV & AI_SRV & UPL_SRV

    POS_SRV -->|Atomic Transaction| DB
    BOM_SRV --> DB
    FIN_SRV --> DB
    AI_SRV -->|Chat & NLP| AI_LLM
    AI_SRV --> DB
    UPL_SRV -->|Zero-Disk Stream| CDN
```

---

## 📂 Struktur Monorepo

Repository ini dikelola menggunakan **Turborepo** dengan arsitektur workspace terisolasi:

```text
Tiga-Angkatan/
├── apps/
│   ├── backend/               # REST API Server (Node.js, Express, TypeScript, Prisma)
│   │   ├── prisma/            # Database schema & migrations
│   │   ├── scripts/           # Seeding script (seed.ts)
│   │   └── src/
│   │       ├── config/        # Environment, Database, Cloudinary config
│   │       ├── middleware/    # Auth, Tenant context, Rate limit, Error handler
│   │       └── modules/       # Auth, Product, Stock, Order, Finance, AI, Upload
│   ├── frontend/              # Web Dashboard & Desktop POS (React 18, Vite, TypeScript)
│   │   └── src/
│   │       ├── components/    # Layout, Navbar, Sidebar, Charts, Pagination
│   │       ├── lib/           # Cloudinary client, API fetcher, Sound fx
│   │       └── screens/       # Home, POS, Stock, Finance, AISisten, Login
│   └── mobile/                # Native Mobile App (Flutter, Dart)
│       ├── assets/            # App icons & brand assets
│       ├── lib/
│       │   ├── core/          # ApiService, Theme, AppColors, Global Widgets
│       │   ├── models/        # Data models (Product, Stock, Order, Finance, AI)
│       │   └── screens/       # Auth, Home, POS, Stock, Finance, AI Assistant, Profile
│       └── test/              # 37 Unit & Widget tests
├── packages/
│   └── shared/                # Shared types & constants
├── package.json               # Root monorepo workspace configuration
├── turbo.json                 # Turborepo pipeline configuration
└── README.md                  # Dokumentasi proyek
```

---

## 💻 Teknologi yang Digunakan

| Komponen | Teknologi | Deskripsi |
|---|---|---|
| **Monorepo Engine** | [Turborepo](https://turbo.build/) + npm Workspaces | Manajemen build terdistribusi dan caching task |
| **Backend Framework** | [Express.js](https://expressjs.com/) v5 | REST API server dengan arsitektur modular TypeScript |
| **Database & ORM** | [PostgreSQL](https://www.postgresql.org/) + [Prisma](https://www.prisma.io/) v7 | Relational persistence dengan type-safe query engine |
| **Web Frontend** | [React](https://react.dev/) 18 + [Vite](https://vitejs.dev/) | Single Page Application (SPA) ultra-cepat |
| **Styling & Icons** | [Tailwind CSS](https://tailwindcss.com/) + [Lucide Icons](https://lucide.dev/) | Utilitas CSS modern dan ikon antarmuka bersih |
| **Mobile App** | [Flutter](https://flutter.dev/) 3.x + [Dart](https://dart.dev/) | Cross-platform native mobile untuk kasir dan owner |
| **Media Cloud Storage**| [Cloudinary](https://cloudinary.com/) SDK | CDN media untuk foto menu dan foto profil avatar |
| **Generative AI** | [Google Gemini](https://ai.google.dev/) / KelontongAI (`mimo-v2.5`) | Model bahasa besar untuk asisten bisnis UMKM |
| **Keamanan & Auth** | JWT (Access + Refresh Token) + Bcrypt | Autentikasi sesi berbasis bearer token & hashing aman |

---

## 🚀 Panduan Instalasi & Menjalankan

### Persyaratan Sistem (Prerequisites)
- **Node.js** >= v18.0.0
- **npm** >= v9.0.0
- **PostgreSQL** Database aktif (Lokal atau Cloud seperti Supabase/Neon/Railway)
- **Flutter SDK** >= v3.19 (untuk menjalankan aplikasi mobile)
- Akun gratis **Cloudinary** (untuk upload gambar)

---

### Langkah 1: Kloning Repository
```bash
git clone https://github.com/andikaPalian/AISistenku.git
cd AISistenku
```

### Langkah 2: Instal Dependensi Seluruh Workspace
```bash
npm install
```

---

### Langkah 3: Konfigurasi Environment (`.env`)

#### 1. Backend (`apps/backend/.env`)
Salin file `.env.example` ke `.env`:
```bash
cp apps/backend/.env.example apps/backend/.env
```
Sesuaikan konfigurasi kunci:
```env
PORT=3000
NODE_ENV=development
FRONTEND_ORIGIN=http://localhost:5173

# Database PostgreSQL
DATABASE_URL="postgresql://postgres:password@localhost:5432/aisistenku_db?schema=public"

# Autentikasi JWT
JWT_SECRET=your_super_secret_jwt_access_key_32chars
JWT_REFRESH_SECRET=your_super_secret_jwt_refresh_key_32chars
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d

# Cloudinary Media Storage
CLOUDINARY_CLOUD_NAMES=your_cloud_name
CLOUDINARY_API_KEYS=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# AI Assistant (Google Gemini / KelontongAI)
GEMINI_API_KEY=your_gemini_api_key
KELONTONG_API_URL=https://api.kelontongai.my.id/v1
KELONTONG_API_KEY=your_kelontong_api_key
KELONTONG_MODEL=mimo-v2.5
```

#### 2. Frontend Web (`apps/frontend/.env`)
```bash
cp apps/frontend/.env.example apps/frontend/.env
```
Isi konfigurasi endpoint backend:
```env
VITE_API_BASE_URL=http://localhost:3000/api
```

---

### Langkah 4: Sinkronisasi Database & Seeding Data Awal

Jalankan migrasi Prisma dan seed data awal (berisi produk kopi, bahan baku, resep BOM, dan transaksi contoh):
```bash
cd apps/backend
npx prisma generate
npx prisma db push
npm run seed
cd ../..
```

---

### Langkah 5: Menjalankan Aplikasi

#### Opsi A: Jalankan Seluruh Aplikasi Sekaligus (Turborepo)
```bash
npm run dev
```

#### Opsi B: Jalankan Secara Terpisah Per Modul

1. **Menjalankan Backend API**:
   ```bash
   cd apps/backend
   npm run dev
   # Server aktif di http://localhost:3000
   ```

2. **Menjalankan Web Dashboard**:
   ```bash
   cd apps/frontend
   npm run dev
   # Akses aplikasi di http://localhost:5173
   ```

3. **Menjalankan Mobile App (Flutter)**:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

---

## 🔑 Akun Demo Pengujian

Setelah menjalankan `npm run seed`, Anda dapat langsung masuk ke Web maupun Mobile menggunakan akun demo berikut:

| Peran (*Role*) | Email | Password | Hak Akses |
|---|---|---|---|
| **Pemilik Usaha (Owner)** | `owner@tigaangkatan.id` | `password123` | Akses penuh: POS, Stok, Resep, Finansial, AISisten, Manajemen Toko |
| **Kasir (Cashier)** | `kasir@tigaangkatan.id` | `password123` | Akses operasional: Kasir POS, Riwayat Transaksi, Cetak Struk |

---

## 📡 Ringkasan Rute API (Endpoints)

Base URL: `http://localhost:3000/api`

| Kategori | Method | Endpoint | Keterangan |
|---|---|---|---|
| **Auth** | `POST` | `/auth/login` | Login pengguna & penerbitan token JWT |
| | `POST` | `/auth/register` | Pendaftaran akun pemilik toko baru |
| | `GET` | `/auth/me` | Ambil profil pengguna & konteks tenant aktif |
| **Produk** | `GET` | `/products` | Daftar menu dengan stok & kalkulasi porsi resep |
| | `POST` | `/products` | Tambah menu baru beserta harga & kategori |
| | `PUT` | `/products/:id` | Update data menu dan harga jual |
| | `DELETE`| `/products/:id` | Nonaktifkan / hapus menu produk |
| **Stok** | `GET` | `/stocks` | Daftar inventaris bahan mentah di gudang |
| | `POST` | `/stocks/:id/restock`| Tambah stok bahan baku dari supplier |
| | `POST` | `/stocks/:id/adjust` | Koreksi penyesuaian stok fisik dan audit |
| **Pesanan** | `POST` | `/orders` | Checkout transaksi POS & auto-potong bahan BOM |
| | `GET` | `/orders` | Riwayat transaksi penjualan toko |
| **Finansial**| `GET` | `/finance/summary` | Ringkasan omzet, pengeluaran, & laba bersih |
| | `GET` | `/finance/transactions`| Daftar mutasi kas operasional |
| **AI** | `POST` | `/ai/chat` | Percakapan interaktif dengan AISisten |
| | `POST` | `/ai/actions/:id/confirm` | Konfirmasi eksekusi aksi restock/finansial AI |
| **Upload** | `POST` | `/upload/product` | Streaming upload foto menu ke Cloudinary |
| | `POST` | `/upload/avatar` | Upload foto profil dengan smart face centering |
| | `POST` | `/upload/sign` | Generate signature untuk direct upload dari Web |

---

## 🧪 Pengujian & Quality Assurance

Sistem telah dilengkapi rangkaian pengujian otomatis (*test suites*) dan kompilasi ketat (*strict TypeScript*):

- **Backend TypeScript Build**:
  ```bash
  cd apps/backend && npm run build
  # Hasil: 0 type errors (Clean Build)
  ```
- **Web Frontend Build**:
  ```bash
  cd apps/frontend && npm run build
  # Hasil: Vite production build berhasil
  ```
- **Flutter Mobile Analysis & Tests**:
  ```bash
  cd apps/mobile
  flutter analyze   # 0 lint issues
  flutter test      # 37/37 unit and widget tests PASSED (100%)
  ```

---

## 🎨 Desain & Konsep Tema

Antarmuka **AISistenku** mengusung konsep **Neo-Clean Minimalist** yang fokus pada kenyamanan mata, kontras tinggi di lingkungan kasir, dan keterbacaan data:

- **Obsidian Dark** (`#111111` / `#1E293B`): Warna dasar elegan yang menonjolkan konten tanpa silau.
- **Emerald Green** (`#22C55E` / `#16A34A`): Warna aksen untuk status sukses, tombol aksi primer, dan indikator aktif.
- **Surface Clean** (`#F8FAFC` / `#FFFFFF`): Latar belakang bersih untuk kenyamanan membaca laporan.
- **Vibrant Alert** (`#EF4444`): Penanda peringatan stok menipis dan pengeluaran.
- **Tipografi**: Menggunakan [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) & [Inter](https://fonts.google.com/specimen/Inter) untuk hierarki teks yang tegas dan modern.

---

## 🗺️ Rencana Pengembangan (Roadmap)

- [x] Sinkronisasi otomatis stok bahan baku resep porsi (BOM) pada transaksi POS.
- [x] Zero-disk memory streaming Cloudinary upload dengan format auto WebP/AVIF.
- [x] Smart face detection avatar cropping.
- [x] AI Assistant terintegrasi model `mimo-v2.5` & Google Gemini.
- [ ] **Bluetooth Thermal Printer (ESC/POS)**: Driver langsung untuk printer kasir thermal fisik 58mm/80mm di aplikasi mobile.
- [ ] **Offline-First SQLite Queue**: Penyimpanan transaksi kasir lokal saat koneksi internet terputus dan auto-sync saat online.
- [ ] **Web Push / FCM Notifications**: Notifikasi instan ke smartphone kasir saat bahan baku mendekati batas kritis.
- [ ] **Multi-Branch Outlet Switcher**: Manajemen banyak cabang toko dalam satu akun induk.

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **[MIT License](LICENSE)** — bebas digunakan, dimodifikasi, dan dikembangkan untuk keperluan komersial maupun non-komersial.

---

<div align="center">
  <sub>Dikembangkan dengan ❤️ untuk kemajuan UMKM Indonesia oleh <b>Tim Tiga Angkatan</b></sub>
</div>
