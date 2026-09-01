# Agent D — Serah Terima UI Merchant (Dark Glass)

**Selesai** 1 September 2026 · **Tema** Dark Glass · **Status commit:** belum
dapat dibuat karena `.git/index.lock` tidak dapat ditulis oleh sandbox sesi ini.

## 1. Layar yang selesai

- **Home** — dashboard Dark Glass `#10140F`, identitas merchant, kartu Buffer
  Intelligence cache-first, badge akurasi `92% · data sintetis`, tiga badge
  sumber yang jujur, chart tujuh hari dari `sales_history`, KPI dari data nyata,
  serta fallback heuristik dari riwayat yang sudah berada di memori saat aplikasi
  kembali dari pengaturan WiFi.
- **Inventory** — foto kamera/galeri ke bucket `product-images`, form surplus,
  triage API/fallback, gerbang validasi fisik, pricing, draft lalu listing live,
  jalur B2B eksklusif untuk skor di bawah 70, placeholder gambar, stream listing,
  dan jejak kaskade dari `waste_batches.source_listing_id`.
- **Scan QR** — pemindai layar penuh memakai `QrScanner`, klaim melalui
  `OrderRepository.claimByQr()`, tampilan sukses/error, dan tombol
  `Masukkan kode manual`.
- **ESG** — agregasi hanya dari `esg_events`, cache-first melalui `esg_reports`,
  narasi `/esg-narrative`, penanda jumlah baris sumber, serta export PDF lokal
  memakai `pdf` dan `printing`.

Komponen pendukung berada di `lib/features/merchant/application/` dan
`lib/features/merchant/presentation/widgets/`. Stub empat layar milik Agent B
sudah diganti tanpa mengubah router atau shell.

## 2. Perubahan lintas-folder yang diizinkan brief

- `lib/core/constants.dart`: menambahkan `modelAkurasi = 0.9227` dan
  `modelDasarUji = 'data sintetis'`, bersumber dari
  `api/model/metrics.json → demand_akurasi`.
- `lib/shared/widgets/badges.dart`: tampilan gelap `SourceBadge` memakai label
  merchant yang diwajibkan; tema terang tetap mempertahankan label lama.
- `lib/shared/widgets/cards.dart`: memperkaya tampilan `DarkGlassCard` tanpa
  mengubah tanda tangan widget.

## 3. Keputusan implementasi

1. **Cache selalu menang.** Forecast yang sudah tersimpan tidak disegarkan dari
   jaringan. Laporan ESG yang sudah tersimpan juga tidak memanggil Gemini lagi.
2. **Periode ESG adalah bulan kalender terakhir yang selesai.** Pada tanggal
   demo 1 September, laporan dan KPI membaca 1–31 Agustus agar angka audit tidak
   berubah menjadi nol saat bulan baru dimulai.
3. **Kaskade manual memakai Edge Function `auto_cascade`, bukan RPC langsung.**
   Migration `0010_cron.sql` mencabut hak EXECUTE `run_auto_cascade` dari role
   `authenticated`. Edge Function adalah kontrak aktual yang meneruskan
   `force: true` dan `merchant_id` menjadi `p_force` dan `p_merchant_id` lewat
   service role. UI juga menolak merchant id kosong dan tombol hanya ada pada
   build `--dart-define=DEMO=true`.
4. **Apply forecast disimpan sebagai state sesi.** Database saat ini belum
   memiliki tabel/kolom rencana produksi terapan; UI tidak mengarang tempat
   penyimpanan baru atau menyalahgunakan `sales_history`.
5. **Cuaca forecast sementara memakai observasi terakhir.** Tanda tangan API
   Flutter saat ini mewajibkan `weatherCode: int`; koordinat merchant tetap
   dikirim di `merchant_context`.
6. Animasi menghormati `MediaQuery.disableAnimations`. Susunan angka panjang
   memakai `FittedBox`, konten utama memakai `ListView`, dan baris fleksibel
   memakai `Expanded`/`Wrap` untuk menghindari overflow.

## 4. Verifikasi yang dilakukan

- `dart format` berhasil untuk 16 berkas Dart yang disentuh/ditambahkan.
- Parser formatter menerima seluruh sumber tanpa error sintaks.
- `git diff --check` bersih.
- Audit statis: tidak ada `#12C56A`, tidak ada stub Agent B yang tersisa,
  bucket foto benar, merchant id wajib dikirim ke kaskade, dan semua string
  wajib tersedia.
- Test widget ditambahkan di `test/merchant_dark_glass_test.dart` dan
  `test/merchant_ui_test.dart` untuk token tema, tiga badge sumber, akurasi,
  gerbang skor `< 70`, pernyataan validasi, layout forecast, dan angka ESG.

`flutter analyze`, `flutter test`, build APK, uji kamera, serta uji mode pesawat
di perangkat **belum dapat dijalankan dalam sandbox ini**. Flutter/Dart mencoba
membaca paket dari `C:\Users\ASUS\AppData\Local\Pub\Cache`, yang tidak dapat
diakses; bila cache diarahkan ke workspace, dependensinya tidak tersedia.
Jalankan dari host yang memiliki akses cache:

```powershell
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=<url> --dart-define=DEMO=true
```

Pada perangkat, buka Home saat online, buka pengaturan WiFi, matikan WiFi,
kembali ke aplikasi, lalu pastikan badge berubah menjadi
`Mode offline · heuristik` tanpa angka menghilang.

## 5. Permintaan perubahan kontrak

### Ke Agent B

1. Tambahkan penyimpanan rencana produksi terapan (repository + tabel/kolom
   yang disepakati), misalnya tanggal, merchant id, jumlah, dan waktu apply.
   Setelah kontraknya ada, state `_applied` di `merchant_home_screen.dart`
   perlu diganti dengan baca/tulis repository tersebut.
2. Ubah `LestarApi.forecast()` agar `weatherCode` opsional. Saat nilainya null,
   jangan kirim `weather_forecast`, sehingga server dapat mengambil cuaca besok
   berdasarkan `merchant_context.lat/lng`. Kontrak sekarang memaksa klien
   mengirim observasi historis sebagai pengganti.

### Ke Agent A

Validasi JWT pemanggil di Edge Function `auto_cascade` dan pastikan
`merchant_id` pada body sama dengan `auth.uid()` untuk panggilan manual.
Pembatasan UI sudah benar, tetapi service-role function sebaiknya tidak
mempercayai body klien sebagai batas otorisasi.

## 6. Yang belum

- Persistensi tombol Apply menunggu kontrak Agent B.
- Pengambilan cuaca besok menunggu perubahan tanda tangan Agent B.
- Verifikasi runtime/perangkat menunggu lingkungan Flutter host yang dapat
  membaca Pub Cache dan kamera/jaringan perangkat.

