# UI Konsumen Light Glass — Design

**Tanggal:** 1 September 2026  
**Sumber kebenaran:** `docs/prompts/E.md`, `docs/06-agent-briefs/E-ui-consumer.md`, design system v3.0, dan handoff Agent A/B.

## Tujuan

Menyelesaikan pengalaman konsumen Lestar dari radar realtime sampai QR klaim dengan data Supabase nyata. Tampilan harus mempertahankan komposisi panel kiri mockup sambil memakai hierarki warna v3.0: oranye untuk uang/waktu dan hijau untuk sistem/dampak.

## Arsitektur

Feature konsumen memakai Riverpod sebagai batas antara UI dan repository bersama. Controller radar mengambil lokasi perangkat, memanggil `ListingRepository.nearbyListings` (RPC dengan parameter `p_lat`, `p_lng`, `p_radius_km`), lalu memuat ulang RPC setiap `liveListingsStream()` memancarkan perubahan. Dengan begitu koordinat, merchant, dan `jarak_km` selalu berasal dari database, sementara Supabase Realtime tetap menjadi pemicu kemunculan listing baru.

Alur transaksi tetap memakai kontrak Agent B: `createOrder` membuat order `pending`, pembayaran simulasi menunggu 1,5 detik lalu memanggil `pay`, dan QR hanya dirender dari order `paid` yang memiliki `qr_token`. Detail, pembayaran, dan QR dinavigasikan dengan `Navigator` di dalam feature agar rute serta shell milik Agent B tidak berubah.

## Komponen dan data flow

- Radar menampilkan header, pencarian, peta OSM, pill diskon berskala, kartu listing terpilih, dan dua flash deal terdekat. Pull-to-refresh mengulang RPC tanpa memutus stream realtime.
- Feed memakai hasil nearby yang sama agar tidak membuat query merchant kedua dan tetap punya keadaan loading/error/empty.
- Detail mempertahankan listing kedaluwarsa sebagai nonaktif. Tombol Pesan hanya aktif jika stok dan waktu masih tersedia.
- Pembayaran menampilkan subtotal, green fee Rp1.000, total, penjelasan green fee, serta pilihan metode simulasi.
- QR aktif mengambil order paid terbaru, item order, dan merchant nyata. Brightness aplikasi dinaikkan selama QR terlihat dan dikembalikan saat layar ditutup.
- Orders mengikuti stream order konsumen dan menampilkan status; Profil memakai `currentProfileProvider` serta `AuthRepository.signOut`.

## Ketahanan dan aksesibilitas

- Kegagalan lokasi tidak menghasilkan jarak palsu. UI menawarkan retry dan dapat memakai titik pusat Malang yang diberi label sebagai lokasi cadangan untuk menjaga daftar berbasis RPC tetap berguna.
- Kegagalan tile peta tidak memblokir daftar ataupun alur pesan.
- Semua daftar memiliki `EmptyState`; semua error jaringan memiliki aksi coba lagi.
- Kartu dan grid diuji pada 360–390 dp. Baris teks memakai `Expanded`/`Flexible`, gambar diberi ukuran terikat, dan daftar berada dalam constraint hingga tidak ada `RenderFlex overflowed`.
- Animasi listing baru memakai fade + slide-up 12 px, 320 ms, `Curves.easeOutCubic`; countdown menghormati keadaan habis.
- Placeholder makanan konsisten untuk `imageUrl == null` dan kegagalan gambar.

## Pengujian

- Unit/controller: RPC memakai lokasi/radius yang benar, refresh setelah stream realtime, order → pay → QR, dan pemilihan QR aktif.
- Widget 390×900: radar, feed, detail, pembayaran, QR, orders, profile, keadaan empty/error, warna CTA, green fee, serta overflow.
- Verifikasi proyek: `dart format`, `flutter analyze`, seluruh `flutter test`, smoke Supabase/realtime jika jaringan tersedia, pencarian warna terlarang, dan build APK release demo.
- Uji dua perangkat fisik tetap merupakan gerbang manual; sesi ini tidak mendeteksi perangkat ADB dan tidak akan mengklaim pengujian tersebut tanpa bukti.

## Perubahan lintas kepemilikan

Kecerahan QR diimplementasikan lewat satu `MethodChannel` Android yang sangat kecil agar tidak menambah dependency jaringan menjelang demo. Perubahan terisolasi pada `MainActivity.kt` dicatat di `E-HANDOFF.md`; tanda tangan widget, repository, dan rute bersama tidak berubah.
