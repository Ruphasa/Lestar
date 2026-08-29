# Agent D — UI Merchant (Dark Glass)

**Jadwal** Minggu 30 Agustus · **Bergantung pada** B · **Acuan visual** `mockup.png` panel tengah

---

## Milik kamu

```
lib/features/merchant/
lib/core/theme/dark_glass.dart
```

Varian tema gelap untuk widget di `lib/shared/widgets/` — tambahkan, jangan ubah tanda tangan fungsinya.

## Baca dulu

1. `docs/03-design-system.md` §4 — spesifikasi Dark Glass lengkap
2. `mockup.png` panel tengah — ini acuan yang harus ditiru, bukan diinterpretasi ulang
3. `docs/05-demo-script.md` menit 0:00–2:30 dan 6:00–6:45 — layar-layar milikmu ada di jalur demo

## Prinsip

Merchant memakai app ini berjam-jam, di dapur atau di kasir, sering dengan cahaya redup. Latar gelap bukan gaya — supaya angka menonjol dan mata tidak lelah.

Latar `#0A0F0C` sengaja bersemu hijau, **bukan** `#000000` netral. Hitam murni membuat kartu terlihat melayang terlalu tajam.

## Tiga tab

```
MerchantShell
  ├── Home       dashboard + Buffer Intelligence
  ├── Inventory  input surplus + triage + validasi + daftar listing
  └── ESG        laporan dampak
```

## Tugas

### 1. Tema — `lib/core/theme/dark_glass.dart`

Seluruh token ada di `03-design-system.md` §7. Isi kerangka kelas yang sudah dibuat Agent B.

Komponen yang kamu buat varian gelapnya:
`DarkGlassCard` · `AccuracyBadge` · `WarnChip` · `StatTile` · `SourceBadge`

### 1b. Dua keluarga warna — hijau untuk sistem, oranye untuk uang

Panelmu tetap didominasi hijau; merchant memakainya berjam-jam, tenang itu benar. Oranye `#F38222` masuk hanya untuk uang dan peringatan.

| Elemen | Warna |
|---|---|
| Angka forecast `48 kg` | putih |
| Badge akurasi `94%` | `emerald #00BC7D` di atas `#113525` |
| Badge sumber AI | `emerald` / `emeraldDeep` / `white @38%` |
| Garis chart demand | `emerald #00BC7D` tebal |
| **Garis chart current plan** | **`orange #F38222` tipis putus-putus** |
| **Chip `⚠ −12 kg vs plan`** | **teks `orange`, latar `orange @14%`** |
| **KPI `Rp 1.86M`** | **`orange`** — ini uang |
| KPI `48.9 kg waste diverted` | `emerald` — ini dampak |
| KPI `79 items listed` | putih — ini hitungan netral |
| Tombol `Apply recommended order` | `emeraldDeep #009966`, teks putih |

Efeknya pada chart: terbaca tanpa legenda. **Hijau = yang direkomendasikan AI. Oranye = rencanamu sekarang.** Selisih keduanya jadi tampak sebagai selisih warna — dan itu persis pesan yang ingin disampaikan kartu forecast.

### 2. Home — layar paling penting di seluruh app

Ini layar pembuka demo. Harus tidak bisa dibedakan dari mockup.

```
[🏪] Verde Kitchen                              [🔔•]
     Merchant Console

Dashboard
Live operations · 7 Jul 2026

┌────────────────────────────────────────────┐
│ 📈 Stock Forecast · Tomorrow  [94% accuracy]│
│                                            │
│ Prep for Friday (predicted demand)         │
│ 48 kg                    [⚠ −12 kg vs plan]│
│                                            │
│      ╭──────╮                              │
│  ────╯      ╰───   fl_chart LineChart      │
│  Tue Wed Thu Fri Sat Sun                   │
│  ── demand    ── current plan              │
│                                            │
│ ┌────────────────────────────────────────┐ │
│ │ Order 20% less tomorrow to prevent     │ │
│ │ ~12 kg surplus before it happens.      │ │
│ └────────────────────────────────────────┘ │
│                                            │
│ [    Apply recommended order         ↗ ]   │
│                          AI · LSTM + Gemini│
└────────────────────────────────────────────┘

[Rp 1.86M] [48.9 kg] [79 items]
 Recovered  Waste      Items
 +12%       diverted   listed
            +8%        +21%
```

**Alur pemuatan** (dari `01-architecture.md` §3.1):
```
cek forecasts untuk besok
  ada?    → tampilkan
  tidak?  → ambil 14 hari sales_history
            → ambil cuaca besok
            → POST /forecast (timeout 4 dtk)
                 berhasil → tulis ke forecasts
                 gagal    → fallback_engine → tulis source='heuristic'
```

**`SourceBadge` wajib ada dan wajib jujur.** Tiga varian:
- `AI · LSTM + Gemini` — emerald
- `AI · LSTM` — emerald redup
- `Mode offline · heuristik` — abu-abu

Ini yang ditunjukkan di penutup demo saat WiFi dimatikan. Kalau badge-nya tidak berubah, momen penutup gagal.

**Badge akurasi** memakai angka nyata dari `ml/model/metrics.json` milik Agent C, bukan `94%` hardcode.

**Chart** memakai `fl_chart` yang sudah ada di pubspec. Garis demand emerald tebal, garis current plan amber tipis putus-putus, gridline `white @6%`, label sumbu `white @38%`.

**Tombol Apply** menyimpan `recommended_production` sebagai rencana produksi merchant hari itu.

### 3. Inventory — gerbang keamanan pangan

Daftar listing merchant + tombol tambah surplus.

**Alur tambah surplus:**
```
1. Foto (image_picker) → unggah ke bucket product-images
2. Nama · kategori · qty · jam masak · harga normal
3. POST /triage (timeout 4 dtk, gagal → fallback lokal)
4. Tampilkan hasil:

   ┌──────────────────────────────────┐
   │  Skor Keamanan Pangan            │
   │         80 / 100                 │
   │      ● Jalur B2C                 │
   │                                  │
   │  Dimasak 8 jam lalu, kategori    │
   │  roti tahan 24 jam. Kondisi      │
   │  suhu normal.                    │
   └──────────────────────────────────┘

   ┌──────────────────────────────────┐
   │  ✓ Validasi Kondisi Fisik Aman   │
   └──────────────────────────────────┘

   Dengan menekan tombol ini, Anda menyatakan
   telah memeriksa aroma, tekstur, dan tampilan
   makanan secara langsung.
```

**Aturan yang tidak boleh dilanggar:**
- Tanpa menekan tombol validasi, listing **tidak boleh** tayang. Database akan menolaknya lewat trigger — pastikan UI tidak mencoba melewatinya dan tidak menampilkan error mentah kalau ditolak.
- Skor `< 70` → tombol validasi B2C **tidak muncul sama sekali**. Yang muncul: "Alihkan ke Jalur B2B".
- Kalimat pernyataan di bawah tombol wajib ada. Ini yang membuat produk bisa dipertanggungjawabkan, dan juri yang teliti akan menanyakannya.

Setelah validasi: `POST /pricing` → tampilkan harga coret + harga baru + persen diskon → `INSERT listings (status='live')`.

**Jejak kaskade** di daftar listing:
```
Croissant 5 pcs  →  tidak terklaim 21.00  →  dialihkan ke Pak Budi 21.05
```
Baca dari `waste_batches` yang `source_listing_id`-nya menunjuk ke listing itu. Ini yang membuktikan kaskade benar terjadi.

### 4. Scan QR

Warisi `merchant_scan_qr_screen.dart` dari Ecobite (638 baris, `mobile_scanner` sudah terpasang). Ganti sumber datanya ke `order_repository.claimByQr()`.

**Wajib ada:** tombol "Masukkan kode manual" sebagai cadangan kalau kamera gagal saat demo.

Setelah berhasil: status → `claimed`, tampilkan konfirmasi, KPI di Home ikut naik.

### 5. ESG

```
Laporan Dampak
1 – 31 Agustus 2026

  32 kg        makanan diselamatkan
  8 kg         CO₂eq tidak dilepaskan
  Rp 384.000   nilai dipulihkan
  128 porsi    sampai ke konsumen

┌────────────────────────────────────┐
│  narasi Gemini, 2–3 paragraf       │
│  siap pakai untuk green branding   │
└────────────────────────────────────┘

[  Export PDF  ]
```

Angka dari agregasi `esg_events` lewat `esg_repository`. Narasi dari `POST /esg-narrative`.

**Setiap angka harus bisa ditelusuri ke baris `esg_events`.** Jangan menambahkan angka yang tidak punya sumber.

Export PDF pakai paket `pdf` + `printing`. Ini item yang boleh dikorbankan kalau waktu habis — cukup tampil di layar.

## Definisi selesai

- [ ] Home tidak bisa dibedakan dari mockup panel tengah saat difoto berdampingan
- [ ] Kartu forecast memuat data nyata dari FastAPI, badge sumber berubah sesuai lapisan fallback
- [ ] Matikan WiFi → badge berubah jadi `Mode offline · heuristik`, angka tetap muncul
- [ ] Badge akurasi memakai angka dari `metrics.json`, bukan hardcode
- [ ] Chart memuat 7 hari data nyata dari `sales_history`
- [ ] Alur tambah surplus jalan penuh: foto → triage → validasi → pricing → live
- [ ] Skor < 70 → tombol B2C tidak muncul
- [ ] Tanpa validasi fisik → listing tidak tayang, dan UI menampilkan pesan yang jelas
- [ ] Scan QR mengubah status order jadi `claimed`, tombol manual tersedia
- [ ] Jejak kaskade terlihat di daftar listing
- [ ] Laporan ESG memuat angka nyata + narasi Gemini
- [ ] Nol `RenderFlex overflowed` — pakai skill `flutter-fix-layout-issues`
