# Agent F — Handoff UI Pengepul Plain

**Tanggal:** 1 September 2026

## Layar yang selesai di source

- **BERANDA:** memuat `nearby_waste` lewat `WasteRepository.nearbyWaste`, menyaring `waste_preference`, menjumlahkan berat, dan menampilkan jarak terdekat.
- **Realtime:** setiap snapshot `WasteRepository.availableStream()` memicu pemuatan ulang RPC; jarak tetap dihitung database.
- **Keadaan kosong:** menampilkan `BELUM ADA SAMPAH HARI INI`, bukan daftar kosong.
- **Peta sekitar:** memakai `LestarMap`/flutter_map 8, marker 92 dp, label berat langsung di atas pin, dan ketuk pin kembali ke Beranda untuk batch itu.
- **Alur jemput:** satu tekanan mencocokkan semua batch yang membentuk total perjalanan; tiap tujuan berjalan `matched -> picked_up -> completed`. Trigger database yang sudah ada menulis `esg_events` saat `completed`.
- **RIWAYAT:** hanya batch `completed`, nama merchant diambil lewat `ProfileRepository.getMerchant`, tiga statistik bulan berjalan, dan kartu satu per baris.
- **LANGGANAN:** versi minimal dari `partners.subscription_expiry`; status, tanggal berakhir, dan satu tombol simulasi perpanjangan 30 hari. Tidak membutuhkan model `partner_subscriptions` baru.
- **Tema Plain:** latar putih, radius kecil, border tegas, label nav hitam, tanpa kaca/gradasi/animasi masuk. Satu-satunya `BoxShadow` adalah glow tombol utama.

## Ukuran dan kontras

- Angka berat: 90 sp, bobot variable-font 800.
- Tombol utama: 140 dp, isian `#009966`, teks putih 32 sp/bobot 800.
- Pengukuran WCAG dari nilai sRGB token:
  - `#0A0A0A` / putih: **19,80:1**.
  - `#265938` / putih: **8,18:1**.
  - `#737373` / putih: **4,74:1**, hanya dipakai pada teks besar.
  - putih / `#009966`: **3,65:1**, hanya dipakai pada teks besar tombol.
- Test widget dengan viewport 390×900 lulus untuk Beranda, tombol, Riwayat, dan Langganan.

## Bukti verifikasi otomatis

- `dart format lib/features/partner lib/core/theme/plain.dart test/features/partner` — 10 berkas terformat.
- `flutter analyze --no-pub` — **No issues found**.
- `flutter test --no-pub test/features/partner` — **5 test lulus**.
- `flutter test --no-pub` — **71 test seluruh repo lulus**.
- Pencarian efek terlarang hanya menemukan satu `BoxShadow`, yaitu glow tombol utama yang memang diizinkan.

## Yang belum dapat dinyatakan lulus

1. **Uji baca 1,5 meter belum dilakukan.** Tidak ada perangkat Android fisik yang terhubung. Ukuran 90 sp sudah ditegakkan di source dan test, tetapi gerbang fisik tetap harus dilakukan di perangkat.
2. **Notifikasi merchant saat JEMPUT belum tuntas lintas-agent.** Update `waste_batches` sudah realtime dan status menjadi `matched`, tetapi tabel `notifications` menolak partner menulis untuk merchant karena policy insert hanya menerima `user_id = auth.uid()`. Tabel itu juga belum masuk publication realtime.

## Permintaan lintas-agent

- **Agent A:** tambahkan trigger `SECURITY DEFINER` pada transisi `waste_batches.available -> matched` yang menulis notifikasi ke `source_merchant_id`, lalu masukkan `notifications` ke publication realtime. Ini menjaga notifikasi server-side dan tidak memperlebar policy insert klien.
- **Agent D:** setelah trigger Agent A ada, tampilkan toast/in-app notification pada layar merchant; alternatif minimal adalah mendeteksi perubahan `merchantWaste` menjadi `matched`.
- **Agent B:** tidak ada perubahan model/repository/widget bersama yang dibutuhkan. Tanda tangan widget bersama tetap tidak disentuh.

## Keputusan yang diambil

1. Total radar dianggap satu rute multi-titik. Tombol `JEMPUT SEKARANG` mencocokkan seluruh batch yang dijumlahkan, lalu layar perjalanan memproses tujuan berurutan.
2. Peta dibuat sebagai keadaan layar penuh di dalam tab Beranda agar tidak mengubah router/shell Agent B dan tidak memakai modal.
3. Ketuk pin memfokuskan satu batch di Beranda; angka dan tombol berikutnya hanya berlaku pada pin pilihan itu.
4. Riwayat memakai `price` batch sebagai dasar `PERKIRAAN HEMAT BIAYA`; tidak ada angka biaya hardcode.
5. Komponen statistik Plain dibuat lokal karena `StatTile` bersama memakai alpha pada teks redup, bertentangan dengan aturan F tentang teks tanpa opacity dan kontras isi minimal 7:1.
