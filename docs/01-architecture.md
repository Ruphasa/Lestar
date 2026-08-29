# Lestar — Arsitektur Sistem

**Versi** 1.0 · 29 Agustus 2026

---

## 1. Empat komponen

```
┌──────────────────────────────────────────────────────────┐
│  Flutter APK (satu aplikasi, tiga wajah)                 │
│  Riverpod · GoRouter · flutter_map · fallback_engine     │
└───────────┬──────────────────────────┬───────────────────┘
            │ Supabase SDK             │ REST (http)
            │ (baca + tulis)           │ (hitung saja)
            ↓                          ↓
┌───────────────────────┐   ┌──────────────────────────────┐
│  Supabase             │   │  FastAPI @ Railway           │
│  Postgres + RLS       │   │  LSTM · triage · pricing     │
│  Realtime · Auth      │   │  → Gemini 2.5 Flash          │
│  Storage · pg_cron    │   │  → OpenWeatherMap            │
│  Edge Function        │   │  STATELESS, tanpa DB         │
└───────────────────────┘   └──────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  Landing page @ Vercel — statis, tombol unduh APK        │
└──────────────────────────────────────────────────────────┘
```

### Keputusan: FastAPI tidak menyentuh database

FastAPI menerima payload, menghitung, mengembalikan angka. Flutter yang menulis hasilnya ke Supabase.

**Alasan:**
1. **Satu jalur tulis.** Tidak ada dua sistem yang bisa menulis baris yang sama dan berkonflik saat demo.
2. **FastAPI boleh mati.** Kalau Railway tumbang, tidak ada data yang rusak — app jatuh ke heuristik lokal dan tetap menulis ke Supabase.
3. **Tanpa kredensial ganda.** FastAPI tidak perlu memegang service role key, jadi tidak ada permukaan serangan tambahan.
4. **Lebih cepat dibangun.** Tidak perlu klien Postgres, connection pool, atau penanganan migrasi di sisi Python.

**Konsekuensi:** Flutter memanggil `/forecast` lalu menulis sendiri ke tabel `forecasts`. Ini disengaja.

### Keputusan: satu APK, bukan tiga

```
LestarApp
 └── AuthGate — baca profiles.role
      ├── MerchantShell  (Home · Inventory · ESG)
      ├── ConsumerShell  (Radar · Feed · [QR] · Orders · Profil)
      └── PartnerShell   (BERANDA · RIWAYAT · LANGGANAN)
```

Satu codebase, satu build, satu instalasi. Saat demo, juri melihat kaskade utuh dari satu perangkat.

## 2. Struktur folder

```
lestar/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── supabase/          client, session, guard
│   │   ├── routing/           router.dart (warisan Ecobite, guard diganti)
│   │   ├── theme/
│   │   │   ├── tokens.dart         warna & tipografi bersama
│   │   │   ├── light_glass.dart    tema konsumen
│   │   │   ├── dark_glass.dart     tema merchant
│   │   │   └── plain.dart          tema pengepul
│   │   ├── api/               klien FastAPI + timeout + retry
│   │   ├── fallback_engine.dart    heuristik Dart, lapis 3
│   │   ├── constants.dart          shelf_life, berat porsi, faktor CO2
│   │   └── utils/             error_handler, formatter rupiah/tanggal
│   ├── shared/
│   │   ├── models/            7 model
│   │   ├── repositories/      7 repository
│   │   └── widgets/           GlassCard, DarkGlassCard, BigButton, StatTile
│   └── features/
│       ├── auth/
│       ├── merchant/          presentation/ + providers/
│       ├── consumer/          presentation/ + providers/
│       └── partner/           presentation/ + providers/
├── supabase/
│   ├── migrations/            SQL berurutan
│   ├── functions/             Edge Function auto-cascade
│   └── seed/                  seed.sql + skrip unggah foto
├── ml/
│   ├── generate_synthetic.py  30 merchant × 120 hari
│   ├── train_lstm.py
│   └── model/lestar_lstm.keras
├── api/
│   ├── main.py                4 endpoint
│   ├── forecast.py triage.py pricing.py esg.py
│   ├── gemini.py weather.py
│   ├── Dockerfile
│   └── requirements.txt
├── landing/                   Next.js statis
└── docs/
```

Struktur ini mengikuti pola berlapis (UI · Logic · Data) yang direkomendasikan tim Flutter, dan mempertahankan pemisahan `core/` vs `features/` yang sudah ada di Ecobite.

## 3. Aliran data — tiga jalur utama

### 3.1 Buffer Intelligence (pagi hari, merchant)

```
MerchantHome dibuka
  → cek forecasts WHERE merchant_id AND forecast_date = besok
     ada? → tampilkan, selesai
     tidak ada?
       → ambil 14 baris terakhir sales_history
       → ambil cuaca besok (OpenWeatherMap)
       → POST /forecast (timeout 4 detik)
            berhasil → tulis ke forecasts (source dari respons)
            gagal    → fallback_engine.dart → tulis dengan source='heuristic'
  → render kartu: X, Y, rekomendasi produksi, narasi, badge sumber
```

### 3.2 Kaskade B2C (malam hari)

```
Merchant isi form surplus
  → POST /triage  (timeout 4 detik, gagal → rumus lokal identik)
  → tampilkan skor + jalur yang direkomendasikan
  → merchant tekan "Validasi Kondisi Fisik Aman"
  → POST /pricing
  → INSERT listings (status='live', physical_validated=true)
       ↓ Supabase Realtime
  → Radar konsumen menerima event, kartu baru muncul tanpa refresh
  → konsumen booking → INSERT orders (status='pending') + order_items
  → bayar (simulasi) → status='paid', qr_token dibuat
  → merchant scan QR → status='claimed', qty_remaining berkurang
  → INSERT esg_events (b2c_rescued)
```

### 3.3 Kaskade B2B (setelah cutoff)

```
pg_cron tiap 5 menit memanggil Edge Function auto_cascade()
  → SELECT listings WHERE status='live'
       AND now() > cutoff_time
       AND qty_remaining > 0
  → UPDATE status='cascaded'
  → INSERT waste_batches (
        source_listing_id = listing.id,
        weight_kg = qty_remaining × berat_porsi[kategori],
        waste_type = 'wet',
        lat/lng = koordinat merchant )
       ↓ Supabase Realtime
  → Radar pengepul menyala
  → partner tekan JEMPUT → status='matched', matched_partner_id terisi
       ↓ Realtime
  → merchant lihat notifikasi
  → partner tiba → 'picked_up' → 'completed'
  → INSERT esg_events (b2b_diverted)
```

## 4. State machine

### 4.1 `listings.status`

```
draft ──(validasi fisik + pricing)──▶ live
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
              sold_out            expired            cascaded
         qty_remaining=0     lewat expires_at    lewat cutoff, sisa>0
                                                        │
                                                        ▼
                                              lahir waste_batch
```

`draft → live` **hanya** boleh terjadi kalau `physical_validated = true`. Ditegakkan lewat trigger database, bukan sekadar kode Flutter.

### 4.2 `orders.status`

```
pending ──bayar──▶ paid ──merchant siapkan──▶ ready ──scan QR──▶ claimed
   │                 │                           │
   └── cancelled ────┴──── expired (lewat qr_expires_at) ◀──────┘
```

`claimed` adalah satu-satunya status terminal yang menulis `esg_events`.

### 4.3 `waste_batches.status`

```
available ──partner tekan JEMPUT──▶ matched ──tiba di lokasi──▶ picked_up
                                       │                            │
                                       └── cancelled                ▼
                                                                completed
                                                                    │
                                                                    ▼
                                                          tulis esg_events
```

## 5. Realtime

Realtime dinyalakan pada tiga tabel:

| Tabel | Pendengar | Untuk apa |
|---|---|---|
| `listings` | konsumen | kartu flash sale baru muncul di radar |
| `waste_batches` | partner | radar limbah menyala |
| `orders` | merchant | notifikasi ada pesanan masuk / terklaim |

Semua langganan realtime **harus** difilter di sisi klien juga, bukan hanya mengandalkan RLS. Alasan: RLS menyaring baris, tapi klien tetap menerima event dan memicu rebuild yang tidak perlu.

## 6. Ketahanan — tiga lapis fallback

```
Lapis 1  LSTM + Gemini 2.5 Flash        source='lstm_gemini'
           ↓ Gemini timeout / kuota habis
Lapis 2  LSTM saja + template kalimat    source='lstm_only'
           ↓ Railway mati / timeout 4 detik
Lapis 3  Heuristik Dart di dalam app     source='heuristic'
```

Lapis 3 ada di `lib/core/fallback_engine.dart` — **di dalam APK**, bukan di server. Kalau internet mati total, app tetap memberi rekomendasi.

Setiap lapis menulis `forecasts.source` dengan jujur, dan UI menampilkan badge sesuai sumbernya. Sistem tidak pernah menyamarkan asal angkanya.

### Aturan timeout

| Panggilan | Timeout | Kalau gagal |
|---|---|---|
| `/forecast` | 4 detik | `fallback_engine.forecast()` |
| `/triage` | 4 detik | rumus triage lokal (rumusnya identik) |
| `/pricing` | 3 detik | rumus pricing lokal (rumusnya identik) |
| `/esg-narrative` | 8 detik | template paragraf statis |
| Supabase query | 10 detik | tampilkan cache terakhir + banner offline |

Rumus triage dan pricing **digandakan** di Dart dan Python dengan sengaja. Keduanya deterministik, jadi hasilnya identik. Ini yang membuat app tetap berfungsi penuh tanpa server.

## 7. Keamanan

- RLS aktif di **semua** tabel. Tidak ada tabel tanpa policy.
- `anon key` saja yang ada di APK. `service_role key` tidak pernah masuk ke aplikasi klien.
- Kunci Gemini dan OpenWeatherMap hanya ada di environment Railway, tidak pernah di APK.
- `qr_token` adalah UUID v4, kedaluwarsa 2 jam, dan hanya bisa dibaca oleh pemilik order dan merchant terkait.
- Storage bucket `product-images` dan `store-logos` publik untuk dibaca; `esg-reports` privat.

## 8. Peta migrasi dari Ecobite

| Ecobite | Lestar | Kerja |
|---|---|---|
| `firebase_auth` | `supabase_flutter` | tulis ulang `auth_repository` |
| `cloud_firestore` | Postgres via SDK | 5 repository, `.snapshots()` → `.stream()` |
| `firebase_storage` | Supabase Storage | ganti pemanggilan unggah |
| `Timestamp` | `DateTime` ISO 8601 | seluruh model |
| `UserModel` | `profiles` + `merchants` + `partners` | pecah tiga |
| `FoodModel` | `listings` | + 6 kolom triage/pricing |
| `WasteModel` | `waste_batches` | + lat/lng, + `source_listing_id` |
| `OrderModel` + `OrderItem` | `orders` + `order_items` | pecah dua tabel, + qr, + green_fee |
| `router.dart` | dipertahankan | ganti guard, tambah shell konsumen |
| `EcoBiteTheme` | 3 tema baru | tulis ulang total |
| `main_layout.dart` | 3 shell | tulis ulang total |

**Dependency yang dicabut:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
**Dependency yang ditambah:** `supabase_flutter`, `flutter_map`, `latlong2`, `geolocator`, `pdf`, `printing`, `intl`
**Dependency yang dipertahankan:** `flutter_riverpod`, `go_router`, `google_fonts`, `qr_flutter`, `mobile_scanner`, `fl_chart`, `image_picker`, `uuid`, `http`
