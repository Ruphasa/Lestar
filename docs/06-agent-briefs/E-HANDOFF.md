# Agent E — Serah Terima UI Konsumen (Light Glass)

**Selesai** 1 September 2026 · **Tema** Light Glass · **Status kode:** siap
diverifikasi di perangkat Android.

## 1. Layar yang selesai

- **Radar** — sapaan dan lokasi aktual, pencarian, peta OpenStreetMap, pin
  penawaran nyata, kartu terpilih, daftar terdekat, pull-to-refresh, serta
  empty/loading/error state. Data kartu dan jarak selalu dimuat dari RPC
  `nearby_listings`; stream listing hanya menjadi pemicu reload RPC.
- **Feed** — grid flash deal responsif dari sumber RPC yang sama, pencarian,
  pull-to-refresh, placeholder gambar, serta empty/loading/error state.
- **Detail listing** — foto, nama, merchant, alamat, jarak, harga asli dan harga
  diskon, stok, hitung mundur, deskripsi, serta CTA yang nonaktif saat stok habis
  atau listing kedaluwarsa. Listing kedaluwarsa tetap terlihat.
- **Booking dan pembayaran** — membuat order `pending`, pilihan metode,
  pemisahan Subtotal/Green Fee/Total dan penjelasannya, jeda simulasi 1,5 detik,
  lalu pembayaran menerbitkan `qr_token` dan membuka QR.
- **QR** — token pembayaran, merchant, alamat, hitung mundur dua jam, daftar
  item, empty/error state, serta override brightness Android selama layar aktif.
- **Orders** — riwayat realtime, status, total, item, dan pintasan ke QR aktif.
- **Profil** — identitas, kontak, alamat, eco points, dan keluar akun.

Fondasi state berada di `lib/features/consumer/application/`, alur checkout di
`consumer_checkout_flow.dart`, dan widget presentasi khusus konsumen di
`presentation/widgets/consumer_widgets.dart`.

## 2. Realtime dan kontrak data

1. `consumerRadarProvider` memperoleh lokasi perangkat lalu memanggil
   `ListingRepository.nearbyListings(lat, lng, radiusKm: 5)`.
2. `ListingRepository.liveListingsStream()` tidak dipakai sebagai sumber jarak
   atau merchant. Setiap snapshot hanya memicu pemanggilan RPC baru, sehingga
   `store_name`, `store_address`, koordinat, dan `jarak_km` tetap berasal dari
   database dan urutannya tetap milik RPC.
3. Tidak ada Haversine atau penyaringan radius manual di Dart.
4. Lokasi fallback dinyatakan jujur sebagai
   `Pusat Malang · lokasi cadangan`; UI tidak menyamarkannya sebagai GPS aktual.
5. Kartu masuk memakai fade dan slide-up 12 px selama 320 ms dengan
   `easeOutCubic`.

## 3. Keputusan implementasi

1. **Hierarki warna v3 dipertahankan.** Oranye dipakai untuk uang, waktu, pill
   diskon, dan CTA; forest/emerald untuk brand, sistem, dan dampak. Tidak ada
   `#12C56A`. Latar oranye memakai teks `#0A0A0A`, sedangkan `#00BC7D` tidak
   dipakai sebagai latar teks.
2. **Ukuran pill diskon berskala.** Padding dan ukuran teks bertambah mengikuti
   persentase diskon yang dijepit ke rentang 0–70%.
3. **Gambar seed yang null tetap disengaja.** Placeholder kategori memiliki
   kontras, ikon, dan semantics label; tidak ada URL gambar palsu.
4. **Brightness tanpa dependency baru.** Method channel
   `id.lestar/screen_brightness` memanggil API window Android untuk menaikkan
   brightness ke 100%, lalu mengembalikannya ke nilai sistem saat pause,
   inactive, atau layar ditutup. Kegagalan platform tidak memblokir QR.
5. **Order tidak mengurangi stok di klien.** UI mengikuti batasan demo:
   pengurangan stok dan perubahan `claimed` tetap milik repository/database.

## 4. Perubahan lintas-folder

- `lib/shared/widgets/badges.dart`: `DiscountPill` dibuat responsif terhadap
  persentase dan `PriceText` memakai `Wrap` agar aman di lebar sempit. Tanda
  tangan kedua widget tidak berubah.
- `android/app/src/main/kotlin/id/lestar/lestar/MainActivity.kt`: handler method
  channel brightness. Ini perubahan native minimum yang diperlukan oleh syarat
  QR; tidak mengubah kontrak repository, router, atau shell.
- `.gitignore`: cache SDK/Pub lokal workspace diabaikan. Cache tersebut hanya
  dipakai untuk menjalankan Flutter di sandbox dan tidak menjadi bagian produk.

Tidak ada permintaan perubahan kontrak ke Agent B.

## 5. Verifikasi otomatis

- `flutter analyze --no-fatal-infos` — **No issues found** untuk seluruh proyek.
- `flutter test` — **86/86 test lulus**, termasuk 12 test konsumen baru pada
  lebar 390 dp.
- `flutter test tool/smoke_supabase.dart` — **8/8 lulus** terhadap Supabase
  nyata: 12 listing live, RPC geo mengembalikan tiga listing terdekat, order,
  waste, forecast, dan ESG terbaca.
- `flutter test tool/smoke_realtime.dart` — **1/1 lulus**; snapshot listing
  berubah dari 3 ke 4 setelah insert dan baris uji berhasil dihapus.
- Test checkout memastikan Green Fee terlihat, simulasi berlangsung 1,5 detik,
  QR memakai token persis dari hasil `pay`, brightness dinaikkan, dan dipulihkan
  saat lifecycle pause.
- Test radar memastikan hasil RPC dirender, snapshot realtime memicu reload RPC,
  layout aman pada 390 dp, dan empty state tersedia.
- Audit statis: tidak ada `#12C56A`, tidak ada kalkulasi jarak lokal, dan
  `git diff --check` bersih.

## 6. Gerbang perangkat yang masih wajib

Sesi ini tidak melihat perangkat ADB (`adb devices -l` kosong), sehingga dua
syarat hardware tidak boleh diklaim sebagai sudah diuji:

1. merchant memvalidasi listing di perangkat pertama dan listing muncul pada
   perangkat konsumen dalam kurang dari dua detik;
2. perangkat merchant memindai QR konsumen, status berubah menjadi `claimed`,
   serta kenaikan/pemulihan brightness terlihat pada layar fisik.

Build APK juga tidak dapat dijalankan di sandbox karena Android SDK host berada
di `C:\Users\ASUS\AppData\Local\Android\sdk` dan akses ke direktori itu ditolak.
Di terminal host normal, jalankan:

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=DEMO=true
adb devices -l
```

Setelah dua perangkat terhubung, ikuti menit 2:30–3:30 pada demo script. Semua
jalur software, Supabase, RPC, realtime, token QR, dan lifecycle brightness
sudah memiliki verifikasi otomatis; bagian di atas khusus bukti hardware.

## 7. Status commit

Commit dan push belum dibuat dari sesi ini karena `.git` bersifat read-only bagi
sandbox. Seluruh perubahan berada di working tree dan siap dikelompokkan menjadi
commit Bahasa Indonesia dari terminal host.
