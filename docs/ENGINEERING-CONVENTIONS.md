# Engineering Conventions — AIsistenku

Dokumen ini menyatukan konvensi lintas tiga codebase (backend, website, mobile) supaya siapapun/agen manapun yang mengerjakan salah satu bagian tidak perlu menebak-nebak konvensi bagian lain.

## 1. Struktur Repo (disarankan)

```
backend/        # Express + Prisma
  prisma/
    migrations/
      schema.prisma
  src/
    config/
    errors/
    http/
    middlewares/
    modules/
      auth/
        dto/
          auth.response.dto.ts
          auth.request.dto.ts
        auth.controller.ts
        auth.repository.ts
        auth.service.ts
        auth.validation.ts
      user/
      business/
      finance/
      order/
      ai/
      product/
    types/
    utils/
    app.ts
    server.ts
website/         # frontend web
mobile/          # Flutter
docs/            # dokumen ini — 01-PRD.md, 02-ARCHITECTURE.md, dst
```

## 2. Environment Variables

### Backend
| Variable | Keterangan |
|---|---|
| `DATABASE_URL` | Connection string PostgreSQL |
| `JWT_ACCESS_SECRET` | Secret sign/verify access token |
| `JWT_REFRESH_SECRET` | Secret sign/verify refresh token |
| `GEMINI_API_KEY` | API key Gemini (server-side only) |
| `PORT` | Port Express |

### Website & Mobile
| Variable | Keterangan |
|---|---|
| `API_BASE_URL` | URL backend, mis. `https://api.aisistenku.app/api/v1` |

**Jangan** pernah taruh `GEMINI_API_KEY` atau `JWT_SECRET` di kode/env client (website/mobile) — hanya boleh ada di backend.

## 3. Penamaan

- **JSON API (request/response)**: camelCase — sesuai `04-API-CONTRACT.md`.
- **Kolom database**: camelCase, sama persis dengan nama field Prisma (tidak di-map ke snake_case). **Nama tabel** tetap snake_case lewat `@@map` (mis. `stock_items`) — lihat `03-DATA-MODEL.md` §1.
- **Komponen frontend** (React/Flutter widget): PascalCase.
- **File/folder**: kebab-case untuk website, snake_case untuk file Dart (konvensi standar Flutter).
- **Header multi-tenant**: `X-Business-Id` (PascalCase-hyphenated, standar HTTP header) — wajib di semua request domain, lihat `04-API-CONTRACT.md` §1.

## 4. Versi API

Semua endpoint di bawah prefix `/api/v1`. Kalau ada breaking change di masa depan, naikkan ke `/api/v2` — jangan ubah `/v1` secara breaking selagi masih dipakai client lama.

## 5. Alur Kerja Git (ringkas)

- Branch: `feature/<nama-fitur>`, `fix/<nama-bug>`.
- Commit message: `<tipe>: <deskripsi singkat>` (mis. `feat: tambah endpoint ai/content-ideas`).
- Setiap PR yang mengubah kontrak API **wajib** ikut mengubah `04-API-CONTRACT.md` di PR yang sama.

## 6. Checklist Konsistensi Sebelum Merge

- [ ] Endpoint baru sudah tercermin di `API-CONTRACT.md`.
- [ ] Perubahan skema sudah tercermin di `schema.prisma` dan `DATA-MODEL.md`.
- [ ] Kalau ada tool/intent AI baru, sudah ditambahkan di `AI-AGENT.md`.
- [ ] Token desain baru (warna/komponen) sudah ditambahkan di `DESIGN-SYSTEM.md`, diterapkan di kedua platform.
- [ ] Endpoint/model baru yang menyentuh data domain sudah difilter `businessId` (lihat `DATA-MODEL.md` §3.1) — tidak ada query yang bisa bocor lintas bisnis.
