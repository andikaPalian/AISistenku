# API Contract — AIsistenku

Ini kontrak yang **wajib diikuti persis** oleh backend (yang mengimplementasikan) dan kedua client (yang mengonsumsi). Kalau ada kebutuhan endpoint baru, ubah dokumen ini dulu sebelum implementasi, supaya web dan mobile tidak pernah beda asumsi.

Base URL: `https://<host>/api/v1`

## 1. Header Wajib

| Header | Kapan dipakai |
|---|---|
| `Authorization: Bearer <access token>` | Semua endpoint kecuali `/auth/register`, `/auth/login`, `/auth/refresh` |
| `X-Business-Id: <businessId>` | Semua endpoint domain (products, stock, orders, finance, dashboard, ai/*, marketing-content) — **tidak** dipakai di `/auth/*` dan `/businesses` |

## 2. Format Response Standar

```json
// Sukses
{ "success": true, "data": { ... } }

// Gagal
{ "success": false, "error": { "code": "STRING_CODE", "message": "Pesan untuk ditampilkan" } }
```

Status code: `200` sukses, `201` created, `400` validasi gagal, `401` tidak terautentikasi, `403` tidak diizinkan (termasuk kalau `X-Business-Id` bukan bisnis milik user), `404` tidak ditemukan, `409` konflik, `500` error server.

## 3. Auth

| Method | Path | Keterangan |
|---|---|---|
| POST | `/auth/register` | `{ name, email, password }` → buat user baru |
| POST | `/auth/login` | `{ email, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | `{ refreshToken }` → `{ accessToken }` baru |
| POST | `/auth/logout` | `{ refreshToken }` → hapus `RefreshToken` terkait (revoke sesi ini) |
| GET | `/auth/me` | Data user yang sedang login |

## 4. Businesses (tanpa `X-Business-Id` — ini yang dipakai untuk *memilih* konteks)

| Method | Path | Keterangan |
|---|---|---|
| GET | `/businesses` | List bisnis yang diikuti user (lewat `BusinessMember`), termasuk `role` di masing-masing |
| POST | `/businesses` | Buat bisnis baru — pembuatnya otomatis jadi `BusinessMember` dengan role `OWNER` |
| PATCH | `/businesses/:id` | Update data bisnis (nama, alamat, telepon) — hanya OWNER |
| GET | `/businesses/:id/members` | List anggota bisnis |
| POST | `/businesses/:id/members` | Tambah anggota (`{ email, role }`) — hanya OWNER, user tujuan harus sudah terdaftar |
| PATCH | `/businesses/:id/members/:memberId` | Ubah role anggota — hanya OWNER |
| DELETE | `/businesses/:id/members/:memberId` | Keluarkan anggota — hanya OWNER |

## 5. Products *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| GET | `/products` | List produk bisnis aktif (`?isActive=true` default) |
| POST | `/products` | Buat produk baru |
| PATCH | `/products/:id` | Update produk (termasuk toggle `isActive`) |
| GET | `/products/:id/recipe` | Lihat resep (BOM) produk |
| PUT | `/products/:id/recipe` | Set/replace resep produk |

## 6. Stock *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| GET | `/stock` | List stok (`?belowMin=true` untuk filter stok menipis) |
| POST | `/stock` | Tambah item stok baru |
| PATCH | `/stock/:id` | Update detail stok item |
| POST | `/stock/:id/adjust` | `{ type: "IN"|"OUT", quantity, source, note }` — mutasi stok manual, otomatis buat `StockLog` |
| GET | `/stock/:id/logs` | Riwayat pergerakan stok item tsb |

## 7. Orders / POS *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| POST | `/orders` | Buat transaksi baru — `{ orderType, tableNumber?, customerName?, items: [{ productId, quantity, variant?, note? }], paymentMethod, cashGiven? }`. Backend hitung subtotal/tax/total, deduksi stok, catat finance income — satu DB transaction. |
| GET | `/orders` | List transaksi (`?from&to`) |
| GET | `/orders/:id` | Detail satu transaksi + items |

## 8. Finance *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| GET | `/finance` | List transaksi keuangan (`?type=INCOME|EXPENSE&from&to`) |
| POST | `/finance` | Catat transaksi manual (`source` otomatis `MANUAL`) |

## 9. Dashboard / Analytics *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| GET | `/dashboard/summary` | Ringkasan: omzet hari ini, jumlah transaksi, stok kritis |
| GET | `/dashboard/sales-trend` | `?range=7d|30d|90d` → data time-series untuk grafik |
| GET | `/dashboard/top-products` | Produk terlaris pada rentang tertentu |

## 10. AI Agent *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| POST | `/ai/chat` | `{ message }` → balasan AI, dibatasi konteks bisnis aktif |
| GET | `/ai/messages` | Riwayat chat bisnis aktif |
| POST | `/ai/actions/:id/confirm` | Eksekusi aksi yang diusulkan AI (`PENDING` → `CONFIRMED`) |
| POST | `/ai/actions/:id/cancel` | Batalkan aksi (`PENDING` → `CANCELLED`) |
| POST | `/ai/content-ideas` | `{ theme, tone?, platform? }` → `{ draftId, captions: string[], hashtags: string[] }`. Generatif, tanpa alur konfirmasi. `draftId` dipakai kalau user ingin menyimpan salah satu hasilnya. |

## 11. Marketing Content *(butuh `X-Business-Id`)*

| Method | Path | Keterangan |
|---|---|---|
| GET | `/marketing-content` | List konten tersimpan (`?status=SAVED` default, bisa filter `ARCHIVED`) |
| POST | `/marketing-content` | Simpan hasil generate — `{ type, platform?, content, prompt?, productId?, sourceMessageId? }`, status awal `SAVED` |
| PATCH | `/marketing-content/:id` | Update status (mis. ke `ARCHIVED`) atau edit isi konten |
| DELETE | `/marketing-content/:id` | Hapus permanen |

### Contoh: `POST /ai/chat` (aksi tulis)
```json
// Request
{ "message": "tambah stok gula 5kg" }

// Response
{
  "success": true,
  "data": {
    "type": "action_confirmation",
    "action": {
      "id": "uuid-ai-action",
      "intent": "add_stock",
      "payload": { "item": "Gula", "quantity": 5, "unit": "kg" },
      "status": "PENDING"
    },
    "message": "Mau saya tambahkan stok Gula sebanyak 5kg?"
  }
}
```

### Contoh: `POST /ai/content-ideas` lalu simpan salah satunya
```json
// 1) Request generate
{ "theme": "promo kopi susu setiap Senin", "platform": "instagram" }

// Response
{
  "success": true,
  "data": {
    "draftId": "temp-abc123",
    "captions": [
      "Senin makin semangat kalau ada Kopi Susu favorit ☕✨ ...",
      "...",
      "..."
    ],
    "hashtags": ["#KopiSusu", "#PromoSenin", "#UMKMKopi"]
  }
}

// 2) User pilih salah satu caption, tekan "Simpan"
// POST /marketing-content
{
  "type": "CAPTION",
  "platform": "instagram",
  "content": "Senin makin semangat kalau ada Kopi Susu favorit ☕✨ ...",
  "prompt": "promo kopi susu setiap Senin"
}
```

## 12. Aturan untuk Client

- Mobile dan website **wajib** memakai endpoint yang sama — jangan buat endpoint khusus mobile atau khusus web.
- Semua perhitungan (subtotal, pajak, total) dilakukan backend. Client hanya menampilkan hasilnya.
- Untuk aksi AI yang bersifat tulis, client wajib menampilkan dialog konfirmasi sebelum memanggil `/ai/actions/:id/confirm` — tidak boleh auto-confirm.
- Client wajib menyimpan `businessId` yang sedang aktif dan menyertakannya sebagai `X-Business-Id` di setiap request domain — kalau user berpindah bisnis (business switcher), header ini yang diganti, bukan login ulang.
