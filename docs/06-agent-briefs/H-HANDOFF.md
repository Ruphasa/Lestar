# Agent H — Handoff Pengerasan Tata Letak

**Tanggal:** 1 September 2026  
**Scope source:** `lib/features/merchant/` dan `lib/features/partner/`  
**Matriks:** 320/360/412 dp × skala teks 1.0/1.3 × 31 surface/state

## 1. Luberan yang ditemukan

Nomor baris di bawah menunjuk lokasi sebelum perbaikan.

| Surface | Sumber | Kondisi | Luberan |
|---|---|---|---|
| Form Inventory merchant | `merchant_inventory_screen.dart:306`, `DropdownButtonFormField` | 320 dp, teks 1.0 | 0,350 px ke kanan |
| Form Inventory merchant | `merchant_inventory_screen.dart:306`, `DropdownButtonFormField` | 320 dp, teks 1.3 | 46 px ke kanan |
| Form Inventory merchant | `merchant_inventory_screen.dart:306`, `DropdownButtonFormField` | 360 dp, teks 1.3 | 6,3 px ke kanan |
| Kartu forecast merchant | `merchant_forecast_card.dart:56`, baris angka dan selisih rencana | 320 dp, teks 1.3 | 40 px ke kanan |
| Kartu forecast merchant | `merchant_forecast_card.dart:56`, baris angka dan selisih rencana | 360 dp, teks 1.3 | 0,450 px ke kanan |
| Badge sumber di kartu forecast | `shared/widgets/badges.dart:57`, `SourceBadge` | 320 dp, teks 1.3 | 68 px ke kanan |
| Badge sumber di kartu forecast | `shared/widgets/badges.dart:57`, `SourceBadge` | 360 dp, teks 1.3 | 28 px ke kanan |
| Pill lokasi Beranda pengepul | `partner_home_screen.dart:209`, `Row` lokasi | 320 dp, teks 1.0 | 69 px ke kanan |
| Pill lokasi Beranda pengepul | `partner_home_screen.dart:209`, `Row` lokasi | 320 dp, teks 1.3 | 147 px ke kanan |
| Pill lokasi Beranda pengepul | `partner_home_screen.dart:209`, `Row` lokasi | 360 dp, teks 1.0 | 29 px ke kanan |
| Pill lokasi Beranda pengepul | `partner_home_screen.dart:209`, `Row` lokasi | 360 dp, teks 1.3 | 107 px ke kanan |
| Pill lokasi Beranda pengepul | `partner_home_screen.dart:209`, `Row` lokasi | 412 dp, teks 1.3 | 55 px ke kanan |
| Label marker peta pengepul | `partner_home_screen.dart:436`, `Column` marker 92 dp | 320/360/412 dp, teks 1.0 | 16 px ke bawah |
| Label marker peta pengepul | `partner_home_screen.dart:436`, `Column` marker 92 dp | 320/360/412 dp, teks 1.3 | 60 px ke bawah |

Tidak ada overflow lain dari surface merchant atau pengepul pada matriks yang
diwajibkan. Angka besar pengepul tidak melempar exception, tetapi nilai panjang
dapat kehilangan jaminan satu baris; hal itu ikut dikeraskan karena Prompt H
secara khusus mewajibkan angka 90 sp tetap utuh pada 320 dp dan skala 1.3.

## 2. Perbaikan yang dilakukan

- `merchant_inventory_screen.dart`: dropdown kategori sekarang
  `isExpanded: true`; label item dibatasi satu baris dengan ellipsis. Tidak ada
  perubahan nilai, pilihan, validasi, atau logika form.
- `merchant_forecast_card.dart`: angka permintaan tetap memakai style angka
  besar tetapi berada dalam `FittedBox(scaleDown)`; chip selisih diberi
  `Flexible` dan `FittedBox`; pemakaian `SourceBadge` dibatasi dari sisi kartu
  dengan `FittedBox`. Font dan isi tidak diubah.
- `partner_home_screen.dart`: teks lokasi diberi `Flexible`, satu baris, dan
  ellipsis; angka berat 90 sp dan jarak besar dibungkus
  `FittedBox(scaleDown)`; label berat marker diberi lebar 92 dp dan
  `FittedBox(scaleDown)` agar ukuran marker yang ditetapkan tetap.
- `test/layout_sweep_test.dart`: menambahkan 186 widget test table-driven.
  Test menginisialisasi locale `id_ID`, memakai `tester.view.physicalSize`,
  DPR 1, dan `MediaQuery` dengan `TextScaler.linear(1.0/1.3)`. Tidak ada
  `binding.setSurfaceSize`.

Test mencakup empat layar merchant, tiga layar pengepul, semua widget/view
publik pada kedua feature, form Inventory, dialog kode QR manual, state B2C dan
B2B, listing isi/kosong, laporan tersimpan/belum tersimpan, perjalanan matched
dan picked-up, riwayat isi/kosong, serta langganan aktif/tidak aktif.

## 3. Temuan `core`/`shared` yang tidak disentuh

- `SourceBadge` di `lib/shared/widgets/badges.dart:57` memiliki `Row` intrinsik
  yang meluber 68 px pada 320 dp/skala 1.3 dan 28 px pada 360 dp/skala 1.3 saat
  diberi label merchant. Sesuai batas Prompt H, file shared tidak diubah.
  `MerchantForecastCard` sekarang memberi constraint `FittedBox` pada titik
  pemakaian sehingga seluruh surface merchant lulus.
- `LestarMap` di shared memulai pemuatan tile HTTP dan menampilkan peringatan
  kebijakan OpenStreetMap di widget test. Permintaan di test dikembalikan
  sebagai HTTP 400 oleh binding, tetapi tidak menghasilkan exception layout.
  Tidak ada file shared yang diubah.
- Tidak ditemukan overflow yang bersumber dari `lib/core/`.

## 4. Kondisi terburuk yang lulus

Semua 31 surface/state aman pada **320 dp × 800 dp, DPR 1, skala teks 1.3**.
Kondisi itu mencakup fixture ekstrem: nama merchant panjang, angka Rupiah besar,
angka berat `125,4 KG`, jarak `123,4 KM`, narasi panjang, serta label status
panjang. Assertion tambahan memastikan style sumber angka berat tetap **90 sp**
dan tinggi `PartnerPrimaryButton` tetap **140 dp**.

Bukti otomatis final:

- `flutter analyze --no-pub` — **No issues found**.
- `flutter test --no-pub test/layout_sweep_test.dart` — **186 test lulus**.
- `flutter test --no-pub` — **272 test lulus**; jauh di atas syarat minimal 74
  dan baseline aktual sesi ini 86.
- `git diff --check` — bersih.
- Tidak ada perubahan source di `lib/features/consumer/`, `lib/core/`, atau
  `lib/shared/`.

## 5. Risiko yang tetap perlu dilihat di perangkat nyata

Agent tidak memiliki perangkat fisik, sehingga pemeriksaan mata manusia masih
wajib untuk hal berikut:

1. Preview kamera `mobile_scanner`, termasuk izin kamera, rasio preview, dan
   perpindahan ke dialog kode manual pada HP 320 dp.
2. Peta dengan tile jaringan sungguhan, posisi marker terhadap safe area, dan
   keterbacaan label marker di luar ruangan.
3. Insets status/navigation bar vendor Android, notch, serta keyboard sistem
   ketika form Inventory dan kode QR manual dibuka.
4. Rasterisasi variable font Plus Jakarta Sans/Inter pada GPU dan versi Android
   berbeda; test menegakkan constraint dan ukuran style, bukan ketajaman piksel.
5. Uji baca UI Plain dari jarak 1,5 meter, di bawah matahari, dan dengan sarung
   tangan. Kontrak 90 sp/140 dp tetap, tetapi keterbacaan fisik tidak dapat
   disimpulkan dari widget test.
6. Orientasi landscape dan skala teks di atas 1.3 tidak termasuk matriks Prompt
   H. Jangan menganggap keduanya terverifikasi dari hasil ini.
