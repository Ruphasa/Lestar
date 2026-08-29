# Lestar — Data Model & Schema Supabase

**Versi** 1.0 · 29 Agustus 2026 · **Pemilik dokumen** Agent A (Database)

---

## 1. Enum

```sql
create type user_role       as enum ('consumer','merchant','partner');
create type listing_status  as enum ('draft','live','sold_out','expired','cascaded');
create type waste_type      as enum ('wet','dry');
create type waste_status    as enum ('available','matched','picked_up','completed','cancelled');
create type order_status    as enum ('pending','paid','ready','claimed','cancelled','expired');
create type forecast_source as enum ('lstm_gemini','lstm_only','heuristic');
create type esg_event_type  as enum ('b2c_rescued','b2b_diverted');
```

## 2. Tabel identitas

### `profiles`
Cerminan 1:1 dari `auth.users`. Dibuat otomatis lewat trigger `on_auth_user_created`.

| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | FK → `auth.users(id)` on delete cascade |
| `name` | text not null | |
| `email` | text not null | |
| `phone` | text | |
| `address` | text | |
| `role` | user_role not null | menentukan shell mana yang dimuat |
| `eco_points` | int default 0 | hanya bermakna untuk consumer |
| `avatar_url` | text | |
| `created_at` | timestamptz default now() | |

### `merchants`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | FK → `profiles(id)` on delete cascade |
| `store_name` | text not null | |
| `store_address` | text not null | |
| `lat` | double precision not null | wajib — radar tidak bisa jalan tanpa ini |
| `lng` | double precision not null | |
| `store_image` | text | URL Supabase Storage |
| `category` | text | warung / kafe / bakery / katering |
| `operating_hours` | text | contoh `08:00-22:00` |
| `cutoff_time` | time default '22:00' | jam kaskade otomatis |
| `rating` | numeric(2,1) default 5.0 | |
| `total_earnings` | numeric default 0 | |
| `total_waste_saved_kg` | numeric default 0 | |
| `level` | int default 1 | |

### `partners`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | FK → `profiles(id)` on delete cascade |
| `org_name` | text not null | |
| `partner_type` | text | maggot / kompos / unggas |
| `waste_preference` | waste_type[] not null | `{wet}`, `{dry}`, atau `{wet,dry}` |
| `vehicle_type` | text | |
| `license_plate` | text | |
| `service_radius_km` | numeric default 10 | |
| `base_lat` | double precision not null | |
| `base_lng` | double precision not null | |
| `total_pickups` | int default 0 | |
| `subscription_expiry` | timestamptz | null = belum berlangganan |

## 3. Tabel jalur B2C

### `listings`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK default gen_random_uuid() | |
| `merchant_id` | uuid not null | FK → `merchants(id)` |
| `name` | text not null | |
| `description` | text | |
| `category` | text not null | menentukan shelf_life dan berat porsi |
| `image_url` | text | |
| `qty_total` | int not null check (> 0) | |
| `qty_remaining` | int not null check (>= 0) | |
| `original_price` | numeric not null | |
| `price` | numeric not null | hasil dynamic pricing |
| `cooked_at` | timestamptz not null | input triage |
| `expires_at` | timestamptz not null | `cooked_at` + shelf_life kategori |
| `triage_score` | smallint check (between 0 and 100) | |
| `triage_reason` | text | narasi dari Gemini atau template |
| `physical_validated` | boolean not null default false | **GERBANG** |
| `physical_validated_at` | timestamptz | |
| `status` | listing_status not null default 'draft' | |
| `created_at` | timestamptz default now() | |

**Trigger wajib** — menegakkan gerbang validasi di level database. Aturan keamanan pangan tidak boleh hanya hidup di kode Flutter. Kalau ada agent yang keliru menulis `status='live'` langsung, database yang menolak.

```sql
create or replace function enforce_physical_validation()
returns trigger language plpgsql as $fn$
begin
  if new.status = 'live' and new.physical_validated is not true then
    raise exception 'listing tidak boleh live tanpa validasi fisik merchant';
  end if;
  if new.status = 'live' and coalesce(new.triage_score, 0) < 70 then
    raise exception 'listing dengan skor triage < 70 harus dialihkan ke jalur B2B';
  end if;
  return new;
end $fn$;

create trigger trg_enforce_physical_validation
  before insert or update on listings
  for each row execute function enforce_physical_validation();
```

**Index:**
```sql
create index idx_listings_live on listings (status, expires_at) where status = 'live';
create index idx_listings_merchant on listings (merchant_id, created_at desc);
```

### `orders`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | |
| `consumer_id` | uuid not null | FK → `profiles(id)` |
| `merchant_id` | uuid not null | FK → `merchants(id)` |
| `subtotal` | numeric not null | |
| `green_fee` | numeric not null default 1000 | |
| `total` | numeric not null | `subtotal + green_fee` |
| `status` | order_status not null default 'pending' | |
| `qr_token` | text unique | UUID v4, dibuat saat `paid` |
| `qr_expires_at` | timestamptz | `paid_at` + 2 jam |
| `payment_method` | text | |
| `ordered_at` | timestamptz default now() | |
| `paid_at` | timestamptz | |
| `claimed_at` | timestamptz | |

### `order_items`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | |
| `order_id` | uuid not null | FK → `orders(id)` on delete cascade |
| `listing_id` | uuid | FK → `listings(id)` on delete set null |
| `name_snapshot` | text not null | nama saat dipesan |
| `qty` | int not null | |
| `unit_price` | numeric not null | harga saat dipesan |

Nama dan harga di-snapshot karena listing bisa berubah atau kedaluwarsa setelah order dibuat. Riwayat pesanan harus tetap terbaca benar setahun kemudian, meski listing aslinya sudah dihapus.

## 4. Tabel jalur B2B

### `waste_batches`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | |
| `source_merchant_id` | uuid not null | FK → `merchants(id)` |
| `source_listing_id` | uuid | FK → `listings(id)` — **bukti kaskade** |
| `waste_type` | waste_type not null | |
| `description` | text | |
| `weight_kg` | numeric not null check (> 0) | |
| `price` | numeric not null default 0 | |
| `pickup_address` | text not null | |
| `lat` | double precision not null | |
| `lng` | double precision not null | |
| `pickup_window_start` | timestamptz | |
| `pickup_window_end` | timestamptz | |
| `image_url` | text | |
| `status` | waste_status not null default 'available' | |
| `matched_partner_id` | uuid | FK → `partners(id)` |
| `created_at` | timestamptz default now() | |
| `completed_at` | timestamptz | |

`source_listing_id` adalah kolom paling penting di seluruh schema untuk keperluan demo. Kalau terisi, artinya batch ini lahir dari makanan yang gagal terjual di B2C. Di layar merchant, jejaknya ditampilkan sebagai:

> *Croissant 5 pcs → tidak terklaim 21.00 → dialihkan ke Pak Budi (maggot) 21.05*

Itu kaskade yang bisa dilihat, bukan diceritakan.

**Index:**
```sql
create index idx_waste_available on waste_batches (status, created_at desc)
  where status = 'available';
```

**Query radius — pakai `earthdistance`, jangan haversine manual**

Project sudah menyediakan ekstensi `cube` dan `earthdistance` (terverifikasi tersedia, belum terpasang). Pakai keduanya untuk radar pengepul dan radar konsumen. Lebih cepat, lebih benar, dan bisa diindeks — jauh lebih baik daripada menghitung haversine di Dart lalu menyaring di klien.

```sql
create extension if not exists cube;
create extension if not exists earthdistance;

create index idx_waste_geo on waste_batches
  using gist (ll_to_earth(lat, lng)) where status = 'available';

create index idx_merchants_geo on merchants
  using gist (ll_to_earth(lat, lng));
```

Contoh query radar pengepul — limbah dalam radius layanannya:
```sql
select w.*, earth_distance(ll_to_earth(w.lat, w.lng),
                           ll_to_earth($1, $2)) / 1000 as jarak_km
from waste_batches w
where w.status = 'available'
  and earth_box(ll_to_earth($1, $2), $3 * 1000) @> ll_to_earth(w.lat, w.lng)
  and earth_distance(ll_to_earth(w.lat, w.lng), ll_to_earth($1, $2)) <= $3 * 1000
order by jarak_km;
```
`$1,$2` = `base_lat`, `base_lng` mitra · `$3` = `service_radius_km`

`earth_box` memakai index GiST untuk menyaring kasar, `earth_distance` menyaring halus. Bungkus jadi fungsi Postgres `nearby_waste(lat, lng, radius_km)` supaya Flutter cukup memanggil `rpc()`.

PostGIS juga tersedia kalau nanti dibutuhkan, tapi berlebihan untuk kebutuhan ini.

### `partner_subscriptions`
`id` · `partner_id` FK → partners · `plan` text · `price` numeric · `starts_at` · `expires_at` · `status` text · `paid_at`

## 5. Tabel intelijen

### `sales_history`
Bahan bakar LSTM. Inilah yang di-seed 90 hari per merchant.

| Kolom | Tipe |
|---|---|
| `id` | uuid PK |
| `merchant_id` | uuid not null FK → merchants |
| `date` | date not null |
| `portions_sold` | int not null |
| `revenue` | numeric not null |
| `day_of_week` | smallint not null (0=Senin) |
| `is_holiday` | boolean default false |
| `weather_code` | smallint |
| `surplus_kg` | numeric default 0 |

`unique (merchant_id, date)`

### `forecasts`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | uuid PK | |
| `merchant_id` | uuid not null | FK → merchants |
| `forecast_date` | date not null | |
| `demand_x` | numeric not null | X — prediksi porsi terjual |
| `surplus_probability_y` | numeric not null check (between 0 and 1) | Y |
| `surplus_volume_est_kg` | numeric | |
| `recommended_production` | int not null | turunan X dan Y — angka yang dilihat merchant |
| `confidence` | numeric | |
| `narrative` | text | kalimat Bahasa Indonesia |
| `source` | forecast_source not null | **harus jujur** |
| `created_at` | timestamptz default now() | |

`unique (merchant_id, forecast_date)`

Kolom `source` bukan hiasan. Kalau Railway mati dan app jatuh ke heuristik lokal, baris tetap tertulis dengan `source='heuristic'` dan UI menampilkan badge *"Mode offline · heuristik"*. Sistem tidak pernah menyamarkan asal angkanya.

### `esg_events`
Buku besar dampak. Satu baris per peristiwa, tidak pernah diubah setelah ditulis.

| Kolom | Tipe |
|---|---|
| `id` | uuid PK |
| `merchant_id` | uuid not null FK → merchants |
| `event_type` | esg_event_type not null |
| `ref_id` | uuid not null (order_id atau waste_batch_id) |
| `weight_kg` | numeric not null |
| `co2_saved_kg` | numeric not null |
| `revenue_recovered` | numeric default 0 |
| `occurred_at` | timestamptz default now() |

Faktor emisi konstan: **0,25 kg CO₂eq per kg** (Tabel 2.5.1 proposal). Disimpan di `lib/core/constants.dart` dan `api/constants.py`, tidak boleh ditulis ulang berbeda di tempat lain.

### `esg_reports`
`id` · `merchant_id` · `period_start` · `period_end` · `total_weight_kg` · `total_co2_kg` · `total_revenue_recovered` · `meals_rescued` · `narrative` · `pdf_url` · `created_at`

Laporan adalah agregasi `esg_events` + narasi Gemini. **Tidak boleh memuat angka yang tidak bisa ditelusuri ke baris `esg_events`.**

### `notifications`
`id` · `user_id` FK → profiles · `title` · `body` · `type` · `read` boolean default false · `created_at`

## 6. RLS

Aktifkan di **semua** tabel. Tidak boleh ada tabel tanpa policy.

| Tabel | SELECT | INSERT / UPDATE |
|---|---|---|
| `profiles` | authenticated | `id = auth.uid()` |
| `merchants` | authenticated (konsumen perlu lihat nama toko) | `id = auth.uid()` |
| `partners` | authenticated | `id = auth.uid()` |
| `listings` | `status='live'` untuk semua authenticated; pemilik lihat semua status | merchant pemilik saja |
| `orders` | `consumer_id = auth.uid()` OR merchant pemilik | consumer insert; merchant update status |
| `order_items` | ikut kebijakan `orders` induknya | ikut `orders` |
| `waste_batches` | `status='available'` untuk role partner; merchant pemilik lihat semua | merchant pemilik insert; partner matched boleh update status |
| `partner_subscriptions` | pemilik | pemilik |
| `sales_history` | merchant pemilik | merchant pemilik |
| `forecasts` | merchant pemilik | merchant pemilik |
| `esg_events` | merchant pemilik | merchant pemilik |
| `esg_reports` | merchant pemilik | merchant pemilik |
| `notifications` | `user_id = auth.uid()` | `user_id = auth.uid()` untuk update `read` |

Contoh policy `listings`:
```sql
create policy "listing live terlihat semua" on listings
  for select to authenticated
  using (status = 'live' or merchant_id = auth.uid());

create policy "merchant kelola listing sendiri" on listings
  for all to authenticated
  using (merchant_id = auth.uid())
  with check (merchant_id = auth.uid());
```

**Keputusan penting:** `forecasts`, `sales_history`, dan `esg_events` ditulis oleh aplikasi memakai anon key (bukan service_role), karena FastAPI sengaja tidak menyentuh database. Karena itu policy INSERT-nya memakai `merchant_id = auth.uid()`, bukan dibatasi service_role. Agent A harus konsisten dengan keputusan ini di seluruh migration.

## 7. Realtime

```sql
alter publication supabase_realtime add table listings;
alter publication supabase_realtime add table waste_batches;
alter publication supabase_realtime add table orders;
```

Ketiganya penggerak Radar dan status klaim langsung. Tabel lain tidak perlu realtime.

## 8. Storage bucket

| Bucket | Publik | Isi |
|---|---|---|
| `product-images` | ya | foto makanan surplus |
| `waste-images` | ya | foto limbah organik |
| `store-logos` | ya | logo merchant |
| `esg-reports` | tidak | PDF laporan, akses lewat signed URL |

## 9. Auto-cascade

> **Terbangun — berbeda dari rancangan awal, dan lebih baik.** Bagian ini sudah diperbarui mengikuti implementasi Agent A. Lihat `06-agent-briefs/A-HANDOFF.md` untuk alasan lengkapnya.

Logika kaskade hidup di **satu tempat**: fungsi Postgres `run_auto_cascade()`.

```
run_auto_cascade(p_force boolean default false,
                 p_merchant_id uuid default null) returns json
```

- Edge Function `auto_cascade` hanya membungkusnya lewat HTTP
- `pg_cron` memanggil fungsinya langsung di dalam database

Akibatnya cron dan pemicu manual menjalankan kode yang **benar-benar sama** — bukan dua jalur yang bisa menyimpang. Dan karena cron tidak perlu memanggil HTTP keluar, **service role key tidak pernah masuk ke SQL**, sehingga Supabase Vault tidak dipakai sama sekali. Rancangan awal di dokumen ini lebih rumit tanpa alasan.

Balikan: `{"cascaded": n, "waste_batches_created": n, "total_kg": x}`

### Dua parameter demo

| Parameter | Untuk apa |
|---|---|
| `p_force` | Lewati pengecekan `cutoff_time`. Demo berlangsung pagi hari sementara cutoff jam 22.00 |
| `p_merchant_id` | Batasi ke satu merchant. **Wajib diisi saat demo** |

Tanpa `p_merchant_id`, kaskade paksa akan menyeret 12 listing panggung merchant lain dan mengosongkan radar konsumen tepat sebelum menit 5:00 demo.

### Job cron sengaja dimatikan

`cron.schedule('lestar-auto-cascade', ...)` dibuat lalu langsung di-`alter_job(active := false)`.

Alasannya terbukti saat pengujian Agent A: begitu jam melewati `cutoff_time`, satu putaran cron mengubah **6 dari 12 listing panggung** menjadi `cascaded` dan radar konsumen ikut kosong. Kaskade yang dipakai di depan juri adalah pemicu manual, jadi cron tidak menambah apa pun selain risiko data panggung berubah tanpa ada yang menekan tombol.

Nyalakan kembali hanya di luar masa demo.

### Logika yang dijalankan
```
SELECT listings l JOIN merchants m ON l.merchant_id = m.id
WHERE l.status = 'live'
  AND l.qty_remaining > 0
  AND (now() AT TIME ZONE 'Asia/Jakarta')::time > m.cutoff_time

untuk tiap baris:
  UPDATE listings SET status = 'cascaded'
  INSERT waste_batches (
    source_merchant_id = l.merchant_id,
    source_listing_id  = l.id,
    waste_type         = 'wet',
    weight_kg          = l.qty_remaining * berat_porsi[l.category],
    lat/lng            = m.lat, m.lng,
    pickup_address     = m.store_address,
    status             = 'available' )
```

Berat porsi per kategori (kg): gorengan 0,15 · nasi/lauk 0,35 · roti 0,08 · kue 0,05 · minuman 0,30 · lainnya 0,20

## 9b. Fungsi yang bisa dipanggil dari Flutter

Tanda tangan persis, diambil dari database yang sudah jadi. **Perhatikan awalan `p_` pada semua parameter.**

```
nearby_listings(p_lat float8, p_lng float8, p_radius_km float8 default 5)
  → TABLE(id, merchant_id, store_name, store_address, store_image,
          name, description, category, image_url, qty_remaining,
          original_price, price, cooked_at, expires_at,
          triage_score, triage_reason, lat, lng, jarak_km)

nearby_waste(p_lat float8, p_lng float8, p_radius_km float8 default 10)
  → TABLE(id, source_merchant_id, store_name, source_listing_id,
          waste_type, description, weight_kg, price, pickup_address,
          lat, lng, pickup_window_start, pickup_window_end,
          image_url, status, created_at, jarak_km)

run_auto_cascade(p_force bool default false, p_merchant_id uuid default null)
  → json
```

Kedua RPC geo **sudah menyertakan data merchant** (`store_name`, `store_address`, `store_image`) dan `jarak_km` terurut menaik. Tidak perlu query kedua untuk nama toko.

### Konstanta versi SQL

Agent A membuat versi SQL dari konstanta bersama, dipakai trigger ESG dan auto-cascade:

```
berat_porsi_kg(p_category text) → numeric
faktor_co2_per_kg()            → numeric
```

**Nilainya wajib sama persis dengan `lib/core/constants.dart` dan `api/constants.py`.** Kalau berbeda, laporan ESG dan berat kaskade akan berselisih tanpa ada yang menyadarinya sampai demo.

## 9c. Catatan implementasi lain dari Agent A

| Hal | Kenyataan | Dampak |
|---|---|---|
| Ekstensi geo | dipasang di schema `extensions`, bukan `public` | pemanggilan di-qualify (`extensions.ll_to_earth`). Tidak berdampak ke Flutter — hanya memanggil RPC |
| `sync_qty_remaining` | dipasang di **`orders`**, bukan `order_items` | benar: pemicunya perubahan `orders.status` jadi `claimed`; baris `order_items` tidak berubah saat itu |
| Stok berkurang | saat `claimed`, bukan `paid` | dua konsumen bisa memesan porsi yang sama sebelum salah satunya mengambil. **Diterima untuk demo**, jangan diperbaiki sekarang |
| `write_esg_event` | dipecah `_order` dan `_waste`, ditaruh di `0005` | idempoten lewat `unique (event_type, ref_id)` |
| RPC geo | ditaruh di `0004_b2b.sql` | jumlah migration tetap 11 (+ `0011` dari review) |

## 10. Konstanta bersama

Nilai-nilai ini muncul di Dart, Python, dan SQL. **Harus identik di ketiganya.**

```
FAKTOR_CO2_PER_KG        = 0.25      kg CO2eq per kg surplus
GREEN_FEE                = 1000      rupiah per transaksi B2C
AMBANG_TRIAGE_B2C        = 70        skor minimum untuk jalur B2C
DISKON_MAKSIMUM          = 0.70
DISKON_DASAR             = 0.30
QR_MASA_BERLAKU_JAM      = 2

SHELF_LIFE_JAM  gorengan 6 · nasi_lauk 8 · roti 24 · kue 72 · seafood 4 · santan_susu 5 · minuman 12
BERAT_PORSI_KG  gorengan 0.15 · nasi_lauk 0.35 · roti 0.08 · kue 0.05 · minuman 0.30 · lainnya 0.20
```

## 11. Peta migrasi Ecobite → Lestar

| Ecobite | Lestar | Kerja |
|---|---|---|
| `UserModel` | `profiles` + `merchants` + `partners` | pecah tiga, buang `Timestamp`, pakai `DateTime.parse` |
| `FoodModel` | `listings` | + `triage_score`, `triage_reason`, `physical_validated`, `physical_validated_at`, `qty_remaining`, `cooked_at` |
| `WasteModel` | `waste_batches` | + `lat`, `lng`, `source_listing_id`, `pickup_window_*`; `status` jadi enum |
| `OrderModel` + `OrderItem` | `orders` + `order_items` | pecah dua tabel, + `qr_token`, `qr_expires_at`, `green_fee` |
| — | `sales_history` | tabel baru |
| — | `forecasts` | tabel baru |
| — | `esg_events`, `esg_reports` | tabel baru |
| `auth_repository` | idem | `firebase_auth` → `supabase_flutter` |
| `food_repository` | `listing_repository` | `.snapshots()` → `.stream(primaryKey:)` |
| `waste_repository` | idem | + query geo |
| `order_repository` | idem | join `order_items` |
| `user_repository` | `profile_repository` | pecah tiga model |

## 12. Nilai default yang sempat tidak tertulis

Ditemukan saat Agent B mengimplementasikan `fallback_engine.dart`.

| Konstanta | Default | Alasan |
|---|---|---|
| `beratPorsiDefaultKg` | **0.20** | sudah tertulis di §10, sama dengan `lainnya` |
| `shelfLifeDefaultJam` | **8** | **tidak** tertulis di §10. Agent B memilih 8 jam — sama dengan `nasi_lauk`, kategori paling umum |

Keduanya wajib sama di **Dart, Python, dan SQL**. Kalau berbeda, triage untuk kategori di luar daftar akan berselisih antara aplikasi dan server.

## 13. Pembulatan lintas bahasa — jebakan nyata

`round()` bawaan Python membulatkan setengah ke genap; Dart membulatkan menjauhi nol.

```
92.5  →  Python round() = 92     Dart .round() = 93
```

Bukan masalah teoretis: input triage `lainnya · 1 jam · 28°C` menghasilkan tepat `92.5`.

Sisi Python **wajib** memakai pembulatan menjauhi nol supaya cocok dengan aplikasi:
```python
import math
def round_half_away(x: float) -> int:
    return int(math.floor(x + 0.5)) if x >= 0 else int(math.ceil(x - 0.5))
```

Berlaku untuk skor triage **dan** pembulatan harga di pricing.

Sepuluh input uji paritas ada di `06-agent-briefs/B-HANDOFF.md` §12 — angka harapannya dihitung tangan dari rumus, bukan diambil dari salah satu implementasi.
