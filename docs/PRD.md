# PRD — AIsistenku
**AI Business Assistant untuk UMKM Coffee Shop Kecil**

Status: Living document — versi ini disusun setelah aplikasi menang Juara 1 & Best Presentation di CREATHON 2026, saat proyek diperluas dari mobile-only menjadi mobile + website + backend terpusat.

---

## 1. Ringkasan Eksekutif

AIsistenku adalah asisten bisnis berbasis AI untuk UMKM coffee shop kecil, yang menggabungkan POS sederhana, manajemen stok berbasis resep (BOM), pencatatan keuangan, dashboard bisnis, dan AI Agent percakapan yang bisa **membaca data bisnis**, **melakukan aksi (tambah stok, catat pengeluaran) lewat chat**, dan **membuatkan (serta menyimpan) ide konten promosi/caption**. Platformnya **multi-bisnis**: satu akun pengguna bisa terhubung ke lebih dari satu usaha, dengan peran (Owner/Kasir) yang diatur per-bisnis.

## 2. Latar Belakang & Konteks

- Awalnya dibangun sebagai proyek mobile (Flutter) untuk CREATHON 2026 — hackathon AI 24 jam bertema "AI untuk UMKM" oleh HMIF-FT UNISMUH.
- Tim: Andika Palian, Taqil Sarwat Fayyadh, Muhammad Ilhamsyah Mokhram (lintas angkatan).
- Hasil: Juara 1 sekaligus Best Presentation.
- Fase saat ini: memperluas dari prototipe mobile menjadi produk dengan tiga platform (mobile, website, backend terpusat) agar siap dipamerkan lebih luas dan dikembangkan lanjut.

## 3. Masalah yang Dipecahkan

UMKM coffee shop kecil biasanya:
- Mencatat stok dan keuangan secara manual (buku/Excel) — rawan lupa dan tidak real-time.
- Tidak punya waktu/keahlian untuk membaca laporan bisnis dalam bentuk grafik.
- Kesulitan konsisten membuat konten promosi karena keterbatasan waktu dan skill copywriting.

## 4. Tujuan Produk

1. Mencatat transaksi, stok, dan keuangan dalam satu sistem terpusat, real-time di semua platform.
2. Memberi pemilik usaha insight bisnis (grafik penjualan, stok menipis, pengeluaran) tanpa perlu baca laporan mentah.
3. Memungkinkan pemilik usaha berinteraksi dengan datanya lewat bahasa natural (chat) — baik untuk bertanya maupun melakukan aksi.
4. Membantu pemilik usaha mempromosikan produknya tanpa perlu menyewa jasa content creator.

### Success Metrics (indikatif — sesuaikan setelah user testing)
- Waktu pencatatan transaksi < 15 detik per transaksi di kasir.
- AI Agent menjawab pertanyaan data bisnis dengan akurasi 100% (karena bersumber langsung dari database, bukan halusinasi).
- 0 insiden modifikasi data tanpa konfirmasi eksplisit dari pengguna.
- Pemilik usaha bisa dapat ≥3 ide caption yang layak pakai dalam satu permintaan chat.

## 5. Target Pengguna

| Persona | Kebutuhan Utama |
|---|---|
| **Pemilik UMKM (Owner)** | Lihat kondisi bisnis cepat, tanya AI soal omzet/stok, minta ide promosi, approve aksi AI, kelola anggota tim per bisnis |
| **Kasir** | Input transaksi secepat mungkin, lihat stok saat melayani pelanggan |

Catatan: satu akun (`User`) bisa menjadi anggota (`BusinessMember`) di lebih dari satu `Business`, dengan role berbeda di masing-masing — misal jadi Owner di satu kedai dan Kasir bantu-bantu di kedai temannya.

## 6. Cakupan Platform

Satu backend (Express + PostgreSQL/Prisma) menjadi **single source of truth**, dikonsumsi oleh dua client:

- **Mobile app (Flutter)** — alat kerja utama kasir: POS/transaksi, cek stok cepat, chat AI di lapangan.
- **Website** — dashboard untuk owner: grafik bisnis yang lebih luas, riwayat lengkap, chat AI dari layar besar, generate konten promosi.

Detail arsitektur dan kontrak API ada di `02-ARCHITECTURE.md` dan `04-API-CONTRACT.md` — **kedua client wajib mengikuti kontrak yang sama**, jangan ada logika bisnis yang beda antara mobile dan web (validasi, perhitungan total, aturan AI Agent semua ada di backend, bukan di client).

## 7. Fitur Utama

### 7.1 POS & Transaksi
- Input transaksi (Dine In/Take Away), multi-item, hitung subtotal/pajak/total otomatis.
- Deduksi stok otomatis berdasarkan resep produk (`product_recipes`) saat transaksi dibuat.
- Pencatatan `finance_transactions` (INCOME) otomatis dari setiap transaksi sukses.

### 7.2 Manajemen Stok
- CRUD stok bahan baku, ambang batas stok minimum (`min_stock`) untuk notifikasi/alert.
- Riwayat pergerakan stok (`stock_logs`) — sumbernya bisa MANUAL, ORDER_DEDUCTION, RESTOCK, atau AI_AGENT.

### 7.3 Pencatatan Keuangan
- Income (otomatis dari POS) dan Expense (manual atau lewat AI Agent).
- Kategori transaksi untuk pelaporan.

### 7.4 Dashboard & Grafik Bisnis
- Tren penjualan harian/mingguan/bulanan.
- Breakdown pendapatan per kategori produk.
- Ringkasan pengeluaran per kategori.
- Daftar stok yang mendekati/melewati `min_stock`.

### 7.5 AI Business Assistant (chat)
Tiga kemampuan inti — detail lengkap di `05-AI-AGENT.md`:
1. **Baca data** — jawab pertanyaan seperti "berapa omzet minggu ini?" langsung dari database (function calling, bukan tebakan model), dibatasi ke bisnis yang sedang aktif.
2. **Aksi modifikasi** — misal "tambah stok gula 5kg" → AI usulkan aksi terstruktur → **wajib dikonfirmasi user** sebelum benar-benar tersimpan.
3. **Generate & simpan ide konten promosi/caption** — user minta "buatkan caption promo buat menu baru", AI hasilkan beberapa variasi caption + saran hashtag. Menghasilkan konten sendiri tidak butuh konfirmasi (tidak mengubah data lain), tapi user bisa memilih **menyimpan** hasil yang disukai ke pustaka konten bisnis untuk dipakai/dilihat lagi nanti.

### 7.6 Manajemen Bisnis & Tim
- Owner bisa membuat `Business` baru dan mengundang/menambah anggota (`BusinessMember`) dengan role Owner atau Kasir.
- Pengguna dengan lebih dari satu bisnis bisa berpindah konteks bisnis aktif (business switcher) — semua data yang ditampilkan (stok, transaksi, chat AI) selalu mengikuti bisnis yang sedang aktif.

## 8. Alur Pengguna Utama (contoh)

1. **Kasir mencatat transaksi** → stok berkurang otomatis → owner lihat perubahan real-time di dashboard website.
2. **Owner tanya AI**: "produk apa yang paling laku minggu ini?" → AI query data, jawab dengan angka nyata.
3. **Owner minta AI catat pengeluaran**: "catat beli galon air 20rb" → AI usulkan aksi `add_expense` → muncul dialog konfirmasi → owner tekan "Ya" → tersimpan.
4. **Owner minta ide promosi**: "bikinin caption buat promo diskon kopi susu hari senin" → AI kasih 3 variasi caption siap pakai → owner tekan "Simpan" pada salah satunya → tersimpan di pustaka konten bisnis.
5. **Owner mengelola dua kedai**: buka business switcher, pindah dari "Kedai A" ke "Kedai B" → semua data (stok, transaksi, chat AI) yang tampil otomatis mengikuti kedai yang sedang aktif.

## 9. Di Luar Cakupan (Non-Goals) — versi ini

- Integrasi payment gateway langsung (QRIS otomatis reconcile, dsb) — pencatatan metode pembayaran masih manual.
- Generate gambar/visual promosi (baru mencakup teks caption + ide, bukan gambar).
- Reservasi meja / sistem antrian.
- Undangan anggota tim lewat email/link (untuk versi ini anggota ditambahkan manual oleh Owner, bukan alur undangan otomatis).

> Catatan revisi: multi-cabang/multi-tenant **sudah tidak lagi di luar cakupan** — struktur data (`Business` + `BusinessMember`) sudah dibangun untuk mendukung ini sejak awal.

## 10. Tech Stack Ringkas

Lihat `02-ARCHITECTURE.md` untuk detail. Ringkasnya: Flutter (mobile), backend Express + PostgreSQL via Prisma, AI menggunakan Gemini (dipanggil langsung dari Express dengan `@google/genai`, bukan lewat Firebase AI Logic — karena backend custom sudah ada).

## 11. Roadmap Singkat

| Fase | Fokus |
|---|---|
| Sekarang | Migrasi database ke Prisma+PostgreSQL, backend Express solid, kontrak API dikunci |
| Berikutnya | Website admin dashboard jalan penuh, AI Agent aksi tervalidasi ketat |
| Setelah itu | Fitur generate konten promosi diperluas (multi-platform tone: IG/WA/Flyer) |

## 12. Tim Proyek

Andika Palian, Taqil Sarwat Fayyadh, Muhammad Ilhamsyah Mokhram — Juara 1 & Best Presentation, CREATHON 2026 (HMIF-FT UNISMUH).
