# Agent A — Serah Terima Database

**Selesai** 29 Agustus 2026 · **Project** `vhauffhtjckzmqomcgrl` (Lestar, ap-southeast-1, Postgres 17.6)

Schema sudah jalan penuh di project sungguhan. B, C, D, E, F boleh mulai.

---

## 1. Daftar tabel dan nama kolom persis — untuk Agent B

13 tabel di schema `public`. Tanda `!` berarti `NOT NULL`. Semua `id` bertipe
`uuid` dengan default `gen_random_uuid()`, kecuali `profiles`, `merchants`,
`partners` yang id-nya mengikuti `auth.users(id)`.

Semua kolom waktu bertipe `timestamptz` — di Dart pakai `DateTime.parse(...)`
lalu `.toLocal()`, jangan `Timestamp` warisan Firebase.

### profiles
```
id uuid!  name text!  email text!  phone text  address text
role user_role!  eco_points int!  avatar_url text  created_at timestamptz!
```
`id` = `auth.users.id` = `auth.uid()`. Baris dibuat otomatis oleh trigger
`on_auth_user_created` dari `raw_user_meta_data` (`name`, `role`, `phone`,
`avatar_url`). Aplikasi **tidak perlu** insert ke sini saat registrasi.

### merchants
```
id uuid!  store_name text!  store_address text!  lat float8!  lng float8!
store_image text  category text  operating_hours text  cutoff_time time!
rating numeric!  total_earnings numeric!  total_waste_saved_kg numeric!  level int!
```
`merchants.id` = `profiles.id` = `auth.uid()`. Tidak ada kolom `merchant_id`
terpisah di mana pun — `listings.merchant_id` langsung dibandingkan dengan
`auth.uid()`.

### partners
```
id uuid!  org_name text!  partner_type text  waste_preference waste_type[]!
vehicle_type text  license_plate text  service_radius_km numeric!
base_lat float8!  base_lng float8!  total_pickups int!  subscription_expiry timestamptz
```
`waste_preference` adalah **array enum**: `{wet}`, `{dry}`, `{wet,dry}`.
Di Dart petakan ke `List<WasteType>`.

### listings
```
id uuid!  merchant_id uuid!  name text!  description text  category text!
image_url text  qty_total int!  qty_remaining int!  original_price numeric!
price numeric!  cooked_at timestamptz!  expires_at timestamptz!
triage_score smallint  triage_reason text  physical_validated bool!
physical_validated_at timestamptz  status listing_status!  created_at timestamptz!
```

### orders
```
id uuid!  consumer_id uuid!  merchant_id uuid!  subtotal numeric!
green_fee numeric!  total numeric!  status order_status!  qr_token text (unique)
qr_expires_at timestamptz  payment_method text  ordered_at timestamptz!
paid_at timestamptz  claimed_at timestamptz
```

### order_items
```
id uuid!  order_id uuid!  listing_id uuid  name_snapshot text!  qty int!  unit_price numeric!
```

### waste_batches
```
id uuid!  source_merchant_id uuid!  source_listing_id uuid  waste_type waste_type!
description text  weight_kg numeric!  price numeric!  pickup_address text!
lat float8!  lng float8!  pickup_window_start timestamptz  pickup_window_end timestamptz
image_url text  status waste_status!  matched_partner_id uuid
created_at timestamptz!  completed_at timestamptz
```

### partner_subscriptions
```
id uuid!  partner_id uuid!  plan text!  price numeric!  starts_at timestamptz!
expires_at timestamptz  status text!  paid_at timestamptz
```

### sales_history
```
id uuid!  merchant_id uuid!  date date!  portions_sold int!  revenue numeric!
day_of_week smallint!  is_holiday bool!  weather_code smallint  surplus_kg numeric!
```

### forecasts
```
id uuid!  merchant_id uuid!  forecast_date date!  demand_x numeric!
surplus_probability_y numeric!  surplus_volume_est_kg numeric
recommended_production int!  confidence numeric  narrative text
source forecast_source!  created_at timestamptz!
```

### esg_events
```
id uuid!  merchant_id uuid!  event_type esg_event_type!  ref_id uuid!
weight_kg numeric!  co2_saved_kg numeric!  revenue_recovered numeric!  occurred_at timestamptz!
```
**Jangan ditulis dari aplikasi.** Baris di sini lahir sendiri dari trigger saat
`orders.status` jadi `claimed` dan `waste_batches.status` jadi `completed`.
Menulis manual akan ditolak `unique (event_type, ref_id)`.

### esg_reports
```
id uuid!  merchant_id uuid!  period_start date!  period_end date!
total_weight_kg numeric!  total_co2_kg numeric!  total_revenue_recovered numeric!
meals_rescued int!  narrative text  pdf_url text  created_at timestamptz!
```

### notifications
```
id uuid!  user_id uuid!  title text!  body text  type text  read bool!  created_at timestamptz!
```

### Tujuh enum
```
user_role       consumer | merchant | partner
listing_status  draft | live | sold_out | expired | cascaded
waste_type      wet | dry
waste_status    available | matched | picked_up | completed | cancelled
order_status    pending | paid | ready | claimed | cancelled | expired
forecast_source lstm_gemini | lstm_only | heuristic
esg_event_type  b2c_rescued | b2b_diverted
```

### Nilai `listings.category` yang dikenali sistem
```
gorengan | nasi_lauk | roti | kue | minuman | lainnya
```
Persis string ini, huruf kecil, `nasi_lauk` pakai garis bawah. Fungsi SQL
`berat_porsi_kg(category)` memetakannya ke 0.15 / 0.35 / 0.08 / 0.05 / 0.30 / 0.20 kg.
Kategori di luar daftar jatuh ke 0.20 kg. `seafood` dan `santan_susu` hanya punya
shelf_life di konstanta, tidak punya berat porsi sendiri — pakai `lainnya`.

---

## 2. Tanda tangan dua RPC geo — untuk Agent E dan F

Keduanya `SECURITY INVOKER`, jadi RLS tetap berlaku. Panggil lewat
`supabase.rpc('...', params: {...})`. Hasil selalu terurut `jarak_km` menaik.
`jarak_km` bertipe `double precision`, satuan kilometer.

### `nearby_waste(p_lat, p_lng, p_radius_km)` — radar pengepul (Agent F)
Default radius 10 km. Hanya batch `status = 'available'`.
```
id uuid, source_merchant_id uuid, store_name text, source_listing_id uuid,
waste_type waste_type, description text, weight_kg numeric, price numeric,
pickup_address text, lat float8, lng float8,
pickup_window_start timestamptz, pickup_window_end timestamptz,
image_url text, status waste_status, created_at timestamptz, jarak_km float8
```
```dart
final rows = await supabase.rpc('nearby_waste', params: {
  'p_lat': partner.baseLat, 'p_lng': partner.baseLng,
  'p_radius_km': partner.serviceRadiusKm,
});
```
`source_listing_id` tidak null = batch ini lahir dari kaskade B2C. Itu yang
ditampilkan sebagai jejak "tidak terklaim → dialihkan".

### `nearby_listings(p_lat, p_lng, p_radius_km)` — radar konsumen (Agent E)
Default radius 5 km. Hanya `status = 'live'`, `qty_remaining > 0`, dan
`expires_at > now()`. Koordinat yang dipakai adalah koordinat **toko**.
```
id uuid, merchant_id uuid, store_name text, store_address text, store_image text,
name text, description text, category text, image_url text, qty_remaining int,
original_price numeric, price numeric, cooked_at timestamptz, expires_at timestamptz,
triage_score smallint, triage_reason text, lat float8, lng float8, jarak_km float8
```

Terverifikasi: dari titik Amira (pusat kota, radius 5 km) mengembalikan 12 baris
mulai 1,06 km; dari basis Pak Budi (radius 2 km) mengembalikan 2 batch,
0,765 km dan 1,403 km.

---

## 3. Format `sales_history` — untuk Agent C

Kontrak kolom generator sintetis:

| Kolom | Tipe | Aturan |
|---|---|---|
| `merchant_id` | uuid | harus ada di `merchants` |
| `date` | date | satu baris per merchant per tanggal, `unique (merchant_id, date)` |
| `portions_sold` | int | >= 0 |
| `revenue` | numeric | >= 0, rupiah penuh, bukan ribuan |
| `day_of_week` | smallint | **0 = Senin**, 6 = Minggu. Di Postgres `extract(isodow) - 1` |
| `is_holiday` | boolean | default false |
| `weather_code` | smallint | 0 cerah, 1 berawan, 2 mendung, 3 hujan |
| `surplus_kg` | numeric | default 0 |

Yang sudah terisi sekarang: **2700 baris** (30 merchant x 90 hari,
`2026-05-31` sampai `2026-08-28`), dibuat Agent A karena Agent C belum jalan
dan Gerbang 4 menuntut angkanya ada. Sifatnya deterministik: nilai diturunkan
dari `hashtext(merchant_id || tanggal)`, jadi menjalankan ulang seed
menghasilkan angka yang sama dan hasil forecast tidak berubah antar gladi.

Pola yang disimulasikan: basis 40–99 porsi per merchant, akhir pekan +25%,
hujan −15%, 17 Agustus +40%, derau ±10%.

**Agent C boleh menimpanya.** Cara aman: `delete from sales_history;` lalu
insert ulang, atau `on conflict (merchant_id, date) do update`. Jangan ubah
arti `day_of_week` — 0 tetap Senin, ini dipakai di seluruh sistem.

---

## 4. Kredensial akun demo

Password sama untuk 43 akun: **`lestar2026`**. Semua sudah `email_confirm`,
semuanya terverifikasi bisa login (43/43) dan mendarat di role yang benar.

| Email | Role | Nama | Catatan |
|---|---|---|---|
| `merchant@lestar.id` | merchant | Verde Kitchen | sengaja tanpa listing aktif |
| `amira@lestar.id` | consumer | Amira Rahmadani | 1240 eco point |
| `budi@lestar.id` | partner | Pak Budi | maggot, 1,2 km dari Verde Kitchen |

Sisanya: `merchant02..merchant30@lestar.id`, `konsumen02..konsumen05@lestar.id`,
`mitra02..mitra08@lestar.id`.

Kunci API tetap di `docs/CREDENTIALS-NEEDED.md` (tidak ter-commit).
Skrip seed membaca `SUPABASE_SERVICE_ROLE_KEY` dari environment, tidak ada
kunci yang tertulis di berkas mana pun di `supabase/`.

---

## 5. Keadaan data sekarang

| Yang dihitung | Nilai |
|---|---|
| Akun | 43 (30 merchant, 5 konsumen, 8 mitra) |
| `sales_history` | 2700 |
| Listing `live` | 12, diskon 40–68%, semuanya bukan Verde Kitchen |
| Listing `sold_out` | 24 (riwayat penjualan) |
| `waste_batches` `available` | 2, total **tepat 16,6 kg** (9,2 + 7,4) |
| `waste_batches` `completed` | 16 (riwayat) |
| `esg_events` | 40 (24 `b2c_rescued`, 16 `b2b_diverted`) |
| Bucket storage | 4 |

Saat demo, kaskade Verde Kitchen menambah 8,4 kg sehingga radar Pak Budi
menampilkan **25 KG**, sesuai mockup.

---

## 6. Keputusan yang diambil sendiri karena tidak tertulis di dokumen

1. **Ekstensi dipasang di schema `extensions`, bukan `public`.** Menghindari
   peringatan `extension_in_public` dari security advisor. Konsekuensinya semua
   pemanggilan geo di-qualify (`extensions.ll_to_earth`, `OPERATOR(extensions.@>)`).
   Tidak berdampak ke klien — Flutter cuma memanggil RPC.

2. **`sync_qty_remaining` dipasang di `orders`, bukan `order_items`.** Brief
   menyebut `order_items`, tapi peristiwa pemicunya adalah perubahan
   `orders.status` menjadi `claimed`; baris `order_items` sendiri tidak berubah
   saat itu. Trigger membaca `order_items` milik order tersebut lalu mengurangi
   stok, dan menandai `sold_out` kalau habis.

3. **Stok berkurang saat `claimed`, bukan saat `paid`.** Mengikuti
   `01-architecture.md` §3.2 apa adanya. Risikonya: dua konsumen bisa membeli
   porsi yang sama sebelum salah satunya datang mengambil. Untuk demo tidak
   masalah; kalau mau diperbaiki, tempatnya di trigger yang sama dengan syarat
   `new.status = 'paid'`.

4. **`write_esg_event` dipecah dua fungsi** (`_order` dan `_waste`) dan
   ditaruh di `0005`, bukan `0003`/`0004`, karena tabel `esg_events` baru lahir
   di `0005`. Keduanya idempoten lewat `unique (event_type, ref_id)`.

5. **Konstanta bersama diberi versi SQL**: `berat_porsi_kg(text)` dan
   `faktor_co2_per_kg()`. Nilainya wajib sama dengan `lib/core/constants.dart`
   dan `api/constants.py`. Kalau Agent B atau C mengubah angkanya, ubah di sini
   juga — trigger ESG dan auto-cascade memakai versi SQL ini.

6. **Dua RPC geo ditaruh di `0004_b2b.sql`.** Daftar migration di brief
   menyebut 11 berkas dan tidak menyediakan tempat untuk RPC geo; `0004` dipilih
   karena di situlah `02-data-model.md` §4 membahas query radius. Jumlah berkas
   tetap 11.

7. **`run_auto_cascade()` adalah satu-satunya tempat logika kaskade hidup.**
   Edge Function `auto_cascade` hanya membungkusnya lewat HTTP. Akibatnya cron
   dan pemicu manual menjalankan kode yang benar-benar sama, dan cron memanggil
   fungsi langsung di dalam database — **tidak perlu service role key di dalam
   SQL, jadi Supabase Vault tidak dipakai sama sekali.**

8. **`run_auto_cascade` punya dua parameter demo**: `p_force` (lewati jam
   cutoff) dan `p_merchant_id` (batasi ke satu merchant). Keduanya diperlukan
   karena demo berlangsung pagi hari sementara cutoff jam 22.00 —
   `05-demo-script.md` menit 4:30 memang meminta "lewati jam cutoff (pakai
   pemicu manual)". Tanpa `p_merchant_id`, kaskade paksa akan menyeret 12
   listing panggung merchant lain dan mengosongkan radar konsumen. Seleksi
   baris, konversi berat, dan isi `waste_batch` identik di kedua jalur.

9. **Job cron dibuat lalu dimatikan.** Lihat bagian 8 di bawah.

10. **RLS tanpa fungsi bantu pembaca role.** Karena `merchants.id` dan
    `partners.id` sama dengan `auth.uid()`, kepemilikan cukup dinyatakan lewat
    perbandingan id langsung. Satu-satunya pengecualian: policy UPDATE
    `waste_batches` memakai `exists (select 1 from partners where id = auth.uid())`
    supaya pengepul bisa menekan JEMPUT pada batch yang belum ada pemiliknya.

11. **Batch `available` terlihat semua yang login**, bukan hanya role partner.
    Menyaring per role butuh lookup role di setiap baris; konsumen juga tidak
    punya layar yang menampilkannya. Lebih sederhana dan lebih cepat.

12. **Konvensi path storage `<uid>/<namaberkas>`**, ditegakkan policy. Agent
    D/E/F harus mengunggah ke path itu, kalau tidak akan ditolak.

13. **`orders.status` boleh diubah pembeli maupun penjualnya.** Policy tidak
    membatasi transisi mana yang boleh oleh siapa — itu urusan lapisan aplikasi.

14. **Pemisah `reset_demo.sql` adalah umur 36 jam**, bukan tabel penanda atau
    tanggal yang diketik manual. Seluruh data seed berumur minimal 2 hari, jadi
    apa pun yang lebih baru pasti sisa gladi atau demo. Efek sampingnya bagus:
    sisa gladi bersih Selasa malam ikut tersapu saat reset Rabu pagi.

---

## 7. Gerbang dan definisi selesai

| Gerbang | Hasil |
|---|---|
| 1 · trigger `on_auth_user_created` ada dan `security definer` | lolos, plus akun uji benar-benar mendarat di `profiles` |
| 2 · `status='live'` tanpa `physical_validated` ditolak | lolos — *listing tidak boleh live tanpa validasi fisik merchant* |
| 2 · `status='live'` dengan `triage_score=45` ditolak | lolos — *listing dengan skor triage < 70 harus dialihkan ke jalur B2B* |
| 2b · `draft → live` lewat UPDATE juga ditolak | lolos (diuji terpisah, bukan cuma jalur INSERT) |
| 3 · merchant A membaca draft merchant B | 0 baris; listing `live` milik B tetap terlihat |
| 4 · `merchants` = 30, `sales_history` = 2700, `sum(weight_kg)` = 16.6 | lolos, ketiganya tepat |

Definisi selesai lainnya:

- 11 berkas migration, jalan berurutan di project kosong tanpa error
- RLS aktif di **13 dari 13** tabel, tidak ada yang tanpa policy
- Realtime aktif di `listings`, `waste_batches`, `orders` (`replica identity full`)
- 4 bucket ada; 3 publik, `esg-reports` privat
- `cube` + `earthdistance` terpasang, index GiST `ll_to_earth` ada di
  `waste_batches` (partial, `available`), `merchants`, dan `partners`
- Dua RPC geo mengembalikan `jarak_km` terurut menaik
- `auto_cascade` dipanggil manual lewat HTTP dengan JWT merchant mengembalikan
  `{"cascaded":1,"waste_batches_created":1,"total_kg":0.4}` dan `waste_batch`-nya
  punya `source_listing_id` terisi, listing sumbernya jadi `cascaded`
- 43 akun bisa login dan mendarat di role yang benar
- `reset_demo.sql` jalan jauh di bawah 5 detik (tabel terbesar yang disentuh 40 baris)
- Security advisor bersih dari temuan buatan Agent A

---

## 8. Yang gagal, dilewati, atau perlu perhatian

### 8.1 Job cron dimatikan — disengaja
`cron.schedule('lestar-auto-cascade', '*/5 * * * *', ...)` dibuat lalu langsung
di-`alter_job(active := false)`.

Alasannya terbukti saat pengujian: begitu jam melewati `cutoff_time` merchant,
satu putaran cron mengubah **6 dari 12 listing panggung** menjadi `cascaded` dan
radar konsumen ikut kosong. Kaskade yang dipakai di depan juri adalah pemicu
manual, jadi cron tidak menambah apa pun selain risiko data panggung berubah
tanpa ada yang menekan tombol.

Menyalakannya kembali di luar masa demo:
```sql
select cron.alter_job((select jobid from cron.job
                        where jobname = 'lestar-auto-cascade'), active := true);
```

### 8.2 Foto belum ada — perlu tindakan pemilik proyek
`supabase/seed/upload_photos.py` sudah jadi dan teruji secara logika, tapi
**belum dijalankan karena belum ada fotonya**. Sumber gratis tanpa API key
sudah dicoba dan ditolak: `source.unsplash.com` mati (HTTP 503), `loremflickr`
mengembalikan foto Flickr acak berwatermark yang sering bukan foto makanan.
Menempel foto asal-asalan di jalur demo melanggar aturan "tidak ada data palsu
di jalur demo".

**Akibatnya `listings.image_url` masih null untuk semua listing.** Agent D dan E
harus menyiapkan placeholder yang rapi untuk `image_url == null` — ini bukan
kondisi darurat, ini kondisi sekarang.

Cara menutupnya: taruh ~40 foto di `supabase/seed/photos/`, lalu
`py supabase/seed/upload_photos.py` (ada `--dry-run`).

### 8.3 Supabase Vault tidak dipakai
Bukan karena gagal, tapi karena tidak diperlukan lagi setelah cron memanggil
fungsi SQL langsung alih-alih lewat HTTP. Tidak ada rahasia di dalam SQL.

### 8.4 `sales_history` dibuat Agent A, bukan Agent C
Brief meminta koordinasi dengan Agent C, tapi Gerbang 4 menuntut 2700 baris ada
sebelum sesi ini ditutup. Lihat bagian 3 — Agent C boleh menimpanya.

### 8.5 Dua peringatan advisor yang tersisa, keduanya bukan buatan Agent A
- `public.rls_auto_enable()` — event trigger bawaan platform Supabase yang
  otomatis menyalakan RLS di tabel baru. Sudah ada sebelum migration pertama.
- *Leaked Password Protection Disabled* — sengaja dibiarkan mati. Kalau
  dinyalakan, password demo `lestar2026` bisa ditolak saat pendaftaran.

### 8.6 Pengepul tidak bisa membatalkan JEMPUT dengan mengosongkan pemilik
Policy `WITH CHECK` pada `waste_batches` mengharuskan baris hasil update tetap
milik pemanggil, jadi `matched_partner_id = null` ditolak. Jalur pembatalan yang
benar adalah `status = 'cancelled'` sambil `matched_partner_id` tetap terisi —
Agent F harap memakai itu, bukan mengosongkan kolomnya.

### 8.7 Kaskade lewat tengah malam
`(now() at time zone 'Asia/Jakarta')::time > cutoff_time` tidak akan menyala
antara 00.00 dan jam cutoff. Ini mengikuti `02-data-model.md` §9 apa adanya.
Praktisnya tidak berpengaruh: cron dimatikan dan demo memakai pemicu manual.

---

## 9. Berkas yang dibuat

```
supabase/migrations/0000_extensions.sql      cube, earthdistance, pg_net, pg_cron
supabase/migrations/0001_enums.sql           7 enum
supabase/migrations/0002_identity.sql        profiles, merchants, partners, on_auth_user_created
supabase/migrations/0003_b2c.sql             listings, orders, order_items, gerbang fisik, sync_qty_remaining
supabase/migrations/0004_b2b.sql             waste_batches, partner_subscriptions, 2 RPC geo
supabase/migrations/0005_intelligence.sql    sales_history, forecasts, esg_events, esg_reports, konstanta, write_esg_event
supabase/migrations/0006_notifications.sql   notifications
supabase/migrations/0007_rls.sql             RLS 13 tabel + cabut EXECUTE fungsi trigger
supabase/migrations/0008_realtime.sql        publication 3 tabel
supabase/migrations/0009_storage.sql         4 bucket + policy
supabase/migrations/0010_cron.sql            run_auto_cascade + job cron (nonaktif)
supabase/functions/auto_cascade/index.ts     pembungkus HTTP
supabase/seed/create_accounts.py             43 akun lewat Admin API
supabase/seed/seed.sql                       seluruh data demo
supabase/seed/upload_photos.py               unggah foto (belum dijalankan)
supabase/seed/photos/README.md               instruksi foto
supabase/seed/reset_demo.sql                 kembalikan panggung
docs/06-agent-briefs/A-HANDOFF.md            berkas ini
```

Tidak ada berkas di luar `supabase/` dan `docs/06-agent-briefs/` yang disentuh.

---

## 10. Urutan menjalankan ulang dari project kosong

```
1. migration 0000 sampai 0010, berurutan
2. set SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY di environment
3. py supabase/seed/create_accounts.py
4. jalankan supabase/seed/seed.sql
5. (opsional) isi supabase/seed/photos/ lalu py supabase/seed/upload_photos.py
```
Sebelum tampil di depan juri: jalankan `supabase/seed/reset_demo.sql`.
Hasil verifikasi yang harus muncul di akhir skrip:
`listing_live 12 · radar_kg 16.6 · listing_verde_aktif 0 · esg_events 40`.
