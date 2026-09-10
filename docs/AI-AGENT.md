# AI Agent — AIsistenku

## 1. Prinsip Keamanan (wajib dipatuhi)

> **AI tidak pernah punya akses tulis langsung ke database.** Setiap aksi yang mengubah data (`add_stock`, `add_expense`, dst) hanya menghasilkan *usulan terstruktur* (`AiAction` berstatus `PENDING`). Eksekusi sungguhan hanya terjadi setelah pengguna menekan konfirmasi secara eksplisit.

Aksi baca (`get_*`) dan aksi generatif (`generate_promo_content`) **tidak** memerlukan konfirmasi karena tidak mengubah data apapun.

> Semua tool — baca, tulis, maupun generatif — dijalankan dalam konteks `businessId` aktif (dari header `X-Business-Id`, lihat `02-ARCHITECTURE.md` §6.2). AI Agent tidak pernah mengakses atau membocorkan data dari bisnis lain milik user yang sama sekalipun.

## 2. Model

- Pakai **Gemini generasi 3.x Flash** (mis. `gemini-3.1-flash`) — jangan pakai 2.5/2.0, keduanya sudah/akan di-shutdown.
- Dipanggil langsung dari Express memakai SDK resmi `@google/genai`. `GEMINI_API_KEY` disimpan sebagai env var server-side, tidak pernah dikirim ke client.

## 3. Daftar Tools (Function Declarations)

| Tool | Tipe | Parameter | Fungsi |
|---|---|---|---|
| `get_sales` | read | `range` (`today`\|`7d`\|`30d`\|custom) | Ambil data penjualan |
| `get_stock` | read | `item?` | Cek stok (semua atau item tertentu) |
| `get_expense` | read | `range` | Ambil data pengeluaran |
| `add_stock` | write | `item`, `quantity`, `unit` | Usulkan penambahan stok |
| `add_expense` | write | `category`, `amount`, `note?` | Usulkan pencatatan pengeluaran |
| `generate_promo_content` | generative | `theme`, `tone?`, `platform?` | Buat ide caption/promo |

## 4. Alur Read

```
User: "berapa omzet minggu ini?"
  → Gemini pilih tool get_sales({ range: "7d" })
  → Backend query FinanceTransaction (type=INCOME) 7 hari terakhir
  → Hasil dikirim balik ke Gemini sebagai tool result
  → Gemini rangkai jawaban natural: "Omzet 7 hari terakhir Rp X, naik/turun dari minggu lalu..."
```

## 5. Alur Write (dengan konfirmasi)

```
User: "tambah stok gula 5kg"
  → Gemini pilih tool add_stock({ item: "Gula", quantity: 5, unit: "kg" })
  → Backend BUAT AiAction (status PENDING), BELUM ubah StockItem
  → Client tampilkan dialog konfirmasi
  → User tekan "Ya" → POST /ai/actions/:id/confirm
  → Backend eksekusi mutasi + StockLog(source=AI_AGENT) + AiAction.status=CONFIRMED
```

Kalau user tekan "Batal" → `AiAction.status = CANCELLED`, tidak ada perubahan data.

## 6. Alur Generate (dan Simpan) Konten Promosi

```
User: "bikinin caption promo kopi susu buat hari Senin"
  → Gemini pilih tool generate_promo_content({ theme: "promo kopi susu Senin", platform: "instagram" })
  → Backend sertakan konteks: nama produk relevan dari Product milik business aktif, harga, stok tersedia —
    supaya caption yang dihasilkan akurat (misal tidak promosi produk yang stoknya habis)
  → Gemini hasilkan 2-4 variasi caption + saran hashtag
  → Langsung ditampilkan ke user, tanpa alur konfirmasi (tidak mengubah data)

User menekan "Simpan" pada salah satu variasi:
  → Client panggil POST /marketing-content dengan isi caption terpilih
  → Backend simpan sebagai MarketingContent (businessId = bisnis aktif, status = SAVED,
    type = CAPTION, sourceMessageId = pesan AI asalnya kalau tersedia)
```

Catatan desain: sertakan data produk/stok aktual ke prompt sebagai konteks (bukan biarkan Gemini mengarang nama produk), supaya ide promosi yang dihasilkan relevan dengan menu yang benar-benar ada dan sedang ingin didorong penjualannya (misal stok berlebih). Yang disimpan ke `MarketingContent` adalah **teks caption final**, bukan prompt mentahnya saja — supaya nanti terlihat langsung tanpa generate ulang.

## 7. Prinsip System Prompt

- AI hanya boleh menjawab pertanyaan data lewat tool call, **tidak boleh mengarang angka** dari pengetahuan umum.
- AI harus menyatakan dengan jelas ketika mengusulkan aksi tulis ("Mau saya tambahkan...?"), bukan berasumsi sudah dieksekusi.
- Untuk `generate_promo_content`, boleh kreatif dan bervariasi nada, tapi nama produk/harga yang disebut harus konsisten dengan data yang diberikan sebagai konteks.
- Bahasa respons: Indonesia, nada ramah dan santai (sesuai gaya komunikasi UMKM), kecuali user memberi instruksi nada lain untuk konten promosi.

## 8. Status Item yang Sebelumnya Terbuka

- ~~Riwayat/penyimpanan caption favorit belum ada tabelnya~~ → **selesai**, lewat `MarketingContent` (lihat §6 dan `DATA-MODEL.md`).
- ~~Belum ada rate-limiting eksplisit untuk endpoint `/ai/*`~~ → **selesai**, lewat `RateLimiterFlexible` (`rate_limiter_flexible`). Pastikan middleware rate-limit benar-benar dipasang di semua route `/ai/*`, bukan cuma tabelnya yang ada.

## 9. Item Terbuka Baru

- Field `draftId` di response `/ai/content-ideas` (lihat `API-CONTRACT.md`) saat ini konseptual — perlu diputuskan apakah backend benar-benar menyimpan draft sementara sebelum di-`SAVED`, atau `draftId` cukup dibuat client-side dan hanya dipakai untuk mengirim ulang teks caption saat menyimpan.
