# Agent A — Database

**Jadwal** Sabtu 29 Agustus, pagi · **Memblokir** B, C, D, E, F · **Prioritas tertinggi hari itu**

---

## Milik kamu

```
supabase/migrations/
supabase/functions/
supabase/seed/
```

Tidak menyentuh apa pun di `lib/`.

## Baca dulu

1. `docs/02-data-model.md` — ini spesifikasi lengkapmu
2. `docs/00-PRD.md` §6 — aturan bisnis
3. Skill `supabase-postgres-best-practices` — **wajib dimuat sebelum menulis SQL apa pun**

## Tugas

### 1. Migration berurutan

**Project sudah terverifikasi siap:**
```
ref       vhauffhtjckzmqomcgrl
nama      Lestar
region    ap-southeast-1 (Singapura — latensi terbaik untuk Indonesia)
Postgres  17.6.1.166
status    ACTIVE_HEALTHY
tabel     kosong — belum ada apa pun di schema public
```

Ekstensi yang **tersedia dan dibutuhkan** (semua belum terpasang, kamu yang pasang):
`pg_cron` 1.6.4 · `pg_net` 0.20.4 · `cube` 1.5 · `earthdistance` 1.2
Sudah terpasang: `pgcrypto`, `uuid-ossp`, `plpgsql`

MCP Supabase sudah tersambung — kamu bisa `apply_migration` dan `execute_sql` langsung.

```
supabase/migrations/
  0000_extensions.sql          cube, earthdistance, pg_cron, pg_net
  0001_enums.sql
  0002_identity.sql            profiles, merchants, partners + trigger on_auth_user_created
  0003_b2c.sql                 listings, orders, order_items + trigger validasi fisik
  0004_b2b.sql                 waste_batches, partner_subscriptions
  0005_intelligence.sql        sales_history, forecasts, esg_events, esg_reports
  0006_notifications.sql
  0007_rls.sql                 seluruh policy
  0008_realtime.sql            publication untuk 3 tabel
  0009_storage.sql             4 bucket + policy
  0010_cron.sql                pg_cron untuk auto_cascade
```

Satu migration satu tujuan. Jangan gabung semua jadi satu file — kalau ada yang salah, sulit dibatalkan.

### 2. Trigger yang wajib ada

**`enforce_physical_validation`** pada `listings` — lihat `02-data-model.md` §3. Ini bukan opsional. Aturan keamanan pangan harus ditegakkan di database, bukan hanya di Flutter.

**`on_auth_user_created`** pada `auth.users` — membuat baris `profiles` otomatis dengan `role` dari `raw_user_meta_data`.

**`sync_qty_remaining`** — saat order berubah `claimed`, kurangi `listings.qty_remaining`. Kalau jadi 0, ubah status jadi `sold_out`.

> **Terbangun di `orders`, bukan `order_items`.** Instruksi awal di sini keliru: pemicunya adalah perubahan `orders.status`, sementara baris `order_items` sendiri tidak berubah saat itu. Trigger membaca `order_items` milik order tersebut lalu mengurangi stok.

**`write_esg_event`** pada `orders` dan `waste_batches` — saat status jadi `claimed` / `completed`, tulis baris `esg_events` dengan `co2_saved_kg = weight_kg * 0.25`.

### 3. Edge Function `auto_cascade`

`supabase/functions/auto_cascade/index.ts`

Logika ada di `02-data-model.md` §9. Dua syarat:
- Bisa dipanggil oleh `pg_cron` (tiap 5 menit)
- Bisa dipanggil manual lewat HTTP dengan anon key — untuk pemicu demo. **Logikanya sama persis**, hanya pemicunya berbeda.

Kembalikan JSON: `{"cascaded": 3, "waste_batches_created": 3, "total_kg": 25.4}`

### 4. Seed data

`supabase/seed/seed.sql` + `supabase/seed/upload_photos.py`

| Yang di-seed | Jumlah | Catatan |
|---|---|---|
| Merchant | 30 | Malang Raya, koordinat nyata tersebar 1–8 km, kategori bervariasi |
| Konsumen | 5 | termasuk **Amira** di pusat kota |
| Partner | 8 | termasuk **Pak Budi** (maggot, wet), 1,2 km dari Verde Kitchen |
| `sales_history` | 30 × 90 hari | **dari Agent C** — koordinasi, jangan buat sendiri |
| Listing aktif | 8–12 | dari merchant selain Verde Kitchen, diskon bervariasi 40–68% |
| `waste_batches` | 2 available | dari merchant lain dalam radius 2 km dari Pak Budi. **Total harus tepat 16,6 kg** (mis. 9,2 + 7,4). Alasan: saat demo, kaskade Verde Kitchen menambah 8,4 kg sehingga radar menampilkan **25 KG** persis seperti mockup. |
| `esg_events` | ~40 | riwayat, supaya laporan ESG punya angka |

**Verde Kitchen sengaja tidak punya listing aktif.** Dibuat langsung saat demo.

Akun demo — password sama semua, `lestar2026`:
```
merchant@lestar.id   → Verde Kitchen
amira@lestar.id      → konsumen
budi@lestar.id       → pengepul maggot
```

Foto: ~40 foto makanan Indonesia dari Unsplash/Pexels, unggah ke bucket `product-images`. Skrip unggah pakai service_role key dari environment, **jangan hardcode**.

### 5. Skrip reset demo

`supabase/seed/reset_demo.sql` — mengembalikan state ke kondisi awal demo dalam < 5 detik:
- Hapus listing dan waste_batches Verde Kitchen
- Hapus orders demo
- Hapus `esg_events` yang dibuat saat demo (`occurred_at > tanggal demo`)
- Sisanya dibiarkan utuh

Ini dipakai di antara gladi bersih dan sebelum tampil.

## Koordinasi

- **Ke Agent B:** kirim daftar nama tabel + kolom persis begitu `0005` selesai, supaya B bisa mulai menulis model tanpa menunggu seluruh migration.
- **Ke Agent C:** minta format keluaran `sales_history` dari generator sintetis, supaya seed dan generator cocok.

## Definisi selesai

- [ ] 10 migration jalan berurutan di project kosong tanpa error
- [ ] RLS aktif di **semua** tabel, tidak ada yang terlewat
- [ ] Uji RLS: login sebagai merchant A **tidak bisa** membaca listing draft merchant B
- [ ] Uji trigger: `INSERT listings (status='live', physical_validated=false)` **ditolak**
- [ ] Uji trigger: `INSERT listings (status='live', triage_score=45)` **ditolak**
- [ ] Realtime aktif dan terverifikasi di `listings`, `waste_batches`, `orders`
- [ ] 4 bucket storage ada dengan policy yang benar
- [ ] `cube` + `earthdistance` terpasang, index GiST `ll_to_earth` ada di `waste_batches` dan `merchants`
- [ ] Dua fungsi RPC jalan dan mengembalikan `jarak_km` terurut menaik:
      `nearby_waste(lat, lng, radius_km)` untuk radar pengepul (Agent F),
      `nearby_listings(lat, lng, radius_km)` untuk radar konsumen (Agent E) — hanya `status='live'`
- [ ] `auto_cascade` bisa dipanggil manual dan menghasilkan `waste_batch` dengan `source_listing_id` terisi
- [ ] Seed jalan, 30 merchant + 90 hari riwayat masuk
- [ ] 3 akun demo bisa login dan mendarat di role yang benar
- [ ] `reset_demo.sql` jalan < 5 detik
