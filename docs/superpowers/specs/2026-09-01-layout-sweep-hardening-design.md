# Layout Sweep Hardening Design

**Tanggal:** 1 September 2026  
**Scope:** `lib/features/merchant/`, `lib/features/partner/`, `test/`, dan handoff Agent H

## Tujuan

Menemukan dan menutup seluruh exception tata letak pada surface merchant dan
pengepul untuk viewport 320, 360, dan 412 dp dengan skala teks 1.0 dan 1.3,
tanpa mengubah fitur, logika, atau keputusan visual.

## Batas Perubahan

- Test penyapu baru berada di `test/layout_sweep_test.dart`.
- Perbaikan source hanya boleh berada di `lib/features/merchant/` dan
  `lib/features/partner/`.
- `lib/features/consumer/`, `lib/core/`, dan `lib/shared/` tidak boleh diubah.
- Temuan yang berasal dari `core` atau `shared` dicatat dalam
  `docs/06-agent-briefs/H-HANDOFF.md`, bukan diperbaiki.
- Ukuran font, warna, tinggi tombol, dan keputusan desain lain tetap.
- Tidak ada dependensi baru dan tidak ada perubahan kontrak data.

## Pendekatan

Test memakai matriks table-driven yang menjalankan setiap surface pada enam
kondisi: tiga lebar dikalikan dua skala teks. Setiap case mengatur
`tester.view.physicalSize`, `tester.view.devicePixelRatio`, dan `MediaQuery`
secara eksplisit, kemudian memastikan tidak ada exception Flutter setelah
layout selesai.

Surface publik yang dapat diberi data langsung dirender memakai fixture lokal
deterministik. Layar berbasis Riverpod dirender dengan provider override agar
state isi, kosong, error, dan state interaktif penting tidak tertutup oleh
loading atau akses jaringan. Komponen yang bergantung pada plugin perangkat
seperti pemindai QR diuji melalui state UI yang dapat dirender tanpa membuka
kamera sungguhan.

## Struktur Test

`test/layout_sweep_test.dart` memiliki empat bagian:

1. Fixture model merchant, listing, ESG, forecast, waste, partner, dan riwayat.
2. Harness tema Dark Glass dan Plain yang membungkus surface dalam
   `MaterialApp`, `Scaffold`, `MediaQuery`, dan bila perlu `ProviderScope`.
3. Helper matriks yang menghasilkan case bernama untuk setiap kombinasi lebar
   dan skala teks, serta mereset konfigurasi view melalui `addTearDown`.
4. Grup coverage untuk seluruh layar dan widget publik merchant/partner,
   termasuk state alternatif yang memiliki susunan layout berbeda.

`setUpAll` selalu memanggil `initializeDateFormatting('id_ID')`. Harness tidak
memakai `binding.setSurfaceSize`.

## Strategi Perbaikan

Setiap kegagalan direproduksi lewat satu case matriks yang spesifik. Perbaikan
diterapkan dengan urutan berikut:

1. Memberi constraint pada teks atau child `Row` memakai `Expanded` atau
   `Flexible`.
2. Membatasi label memakai `maxLines` dan `TextOverflow.ellipsis`.
3. Membungkus angka besar yang harus tetap utuh memakai
   `FittedBox(fit: BoxFit.scaleDown)`.
4. Menambah scroll vertikal hanya ketika tinggi konten memang melebihi layar.

Padding boleh dikurangi hanya jika constraint child tidak cukup. Ukuran 90 sp
untuk angka utama pengepul dan tinggi 140 dp untuk tombol utama dipertahankan.

## Error Handling dan Isolasi

Setiap case hanya memuat satu surface agar exception dapat dikaitkan dengan
nama surface, lebar, dan skala teks secara langsung. Callback memakai fungsi
lokal tanpa efek samping. Data dan provider palsu tidak melakukan jaringan,
database, kamera, atau operasi file.

Exception diambil setelah frame yang diperlukan selesai. Kegagalan tidak
disembunyikan melalui override global `FlutterError`; pesan asli tetap muncul
di output test sehingga jumlah piksel dan arah overflow dapat dicatat.

## Verifikasi

Urutan verifikasi akhir:

1. Jalankan test penyapu dan pastikan seluruh matriks lulus tanpa exception.
2. Format hanya file Dart yang disentuh.
3. Jalankan `flutter analyze` dan pastikan bersih.
4. Jalankan seluruh `flutter test` dan pastikan jumlah test tidak kurang dari
   baseline 74.
5. Audit diff agar tidak ada perubahan di folder terlarang.
6. Tulis `H-HANDOFF.md` berisi lokasi dan ukuran setiap overflow, cara
   perbaikan, temuan lintas-scope, kondisi terburuk yang lulus, serta risiko
   yang masih memerlukan pemeriksaan perangkat nyata.

## Kriteria Selesai

- Seluruh surface merchant dan partner tercantum eksplisit di test penyapu.
- Enam kombinasi layout per surface lulus tanpa exception.
- Ukuran dan keputusan desain yang diwajibkan tetap utuh.
- Analyze bersih dan seluruh suite memiliki sedikitnya 74 test lulus.
- Handoff membedakan perbaikan lokal, temuan `core`/`shared`, dan risiko fisik.
