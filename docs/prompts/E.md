Kamu **Agent E (UI Konsumen — Light Glass)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

Layarmu membuktikan realtime bekerja. Menit 2:30–3:30 demo adalah milikmu, dan itu momen yang paling mudah gagal.

## Baca dulu

```
docs/README.md
docs/00-PRD.md                          §5 fitur, §6 aturan bisnis
docs/03-design-system.md                §3 token, §4 font, §6 Light Glass
docs/05-demo-script.md                  menit 2:30–3:30
docs/06-agent-briefs/E-ui-consumer.md   tugasmu
docs/06-agent-briefs/A-HANDOFF.md       tanda tangan RPC nearby_listings
docs/06-agent-briefs/B-HANDOFF.md       nama model, repository, widget
mockup.png                              panel KIRI — acuan yang ditiru
```

Muat skill: `flutter-expert`, `flutter-animations`, `flutter-fix-layout-issues`.

## Milikmu

```
lib/features/consumer/
lib/core/theme/light_glass.dart
```

Varian tema terang untuk widget bersama boleh ditambah — **jangan ubah tanda tangan fungsinya**, D dan F memakai widget yang sama.

## Prinsip

Konsumen memakai app ini sore–malam, di jalan, sambil berburu diskon. Rasa yang dituju: **ringan, cepat, menyenangkan.** Berburu, bukan berbelanja.

## ⚠ Panelmu paling berubah dari mockup — baca ini dua kali

Mockup memakai emerald untuk **segalanya**: pill diskon, harga, FAB, nav aktif, badge AI. Akibatnya tidak ada hierarki — mata tidak tahu harus ke mana dulu.

Design system v3.0 memisahkannya jadi dua keluarga warna. **Ikuti pembagian ini, jangan tiru warna mockup mentah-mentah.**

| Elemen | Warna | Kenapa |
|---|---|---|
| Sapaan, judul layar | `#265938` forest | brand, tenang, kontras 8:1 |
| Nav aktif, ikon sistem | `#00BC7D` | status, bukan aksi |
| Badge `AI −64%` | `#00BC7D` isian, teks putih | label sistem, bukan harga |
| **Pill diskon di peta** | **`#F38222`, teks `#0A0A0A`** | urgensi. kontras 7,2:1 |
| **Harga baru** | **`#C2540E`** | uang. kontras 4,6:1 |
| Harga coret | `#737373` dicoret | |
| **Tombol Pesan** | **`#F38222`, teks `#0A0A0A`** | CTA komersial |
| **Hitung mundur** | **`#F38222`** | waktu menipis |
| FAB QR | `#009966`, ikon putih | alat, bukan penjualan |
| Chip "Terselamatkan" | `#ECFAEF` + teks `#265938` | dampak lingkungan |

Prinsipnya: **oranye = uang dan waktu. hijau = sistem dan dampak.**

Dua aturan keras:
- Isian oranye **selalu** dengan teks gelap `#0A0A0A`. Putih di atas oranye cuma 2,6:1.
- `#00BC7D` **tidak pernah** jadi latar teks — kontrasnya 2,5:1. Hanya ikon dan garis.

Perhatikan bedanya: pill diskon di peta itu **penawaran** (oranye), badge AI di kartu itu **penjelasan** (hijau). Dua hal berbeda, dua warna berbeda.

## Lima tab

```
ConsumerShell
  ├── Radar    peta + daftar terdekat        ← layar utama
  ├── Feed     grid flash deals
  ├── [QR]     FAB tengah — QR aktif milikku
  ├── Orders   riwayat pesanan
  └── Profil
```

## Lingkup

**1. Radar — layar utama**

Tata letak persis di `E-ui-consumer.md`. `flutter_map` + tile OpenStreetMap.

**Jarak dihitung di database, bukan di Dart.** Tanda tangan persis dari Agent A — perhatikan awalan `p_`:
```dart
final rows = await supabase.rpc('nearby_listings', params: {
  'p_lat': posisi.latitude,
  'p_lng': posisi.longitude,
  'p_radius_km': 5,
});
```
Kembaliannya **sudah termasuk data merchant** — `store_name`, `store_address`, `store_image` — plus `jarak_km`, terurut menaik. Tidak perlu query kedua untuk nama toko.

Jangan hitung haversine manual lalu saring di klien — lebih lambat, dan menarik seluruh tabel ke perangkat.

**Catatan keterbatasan yang sudah diketahui:** stok berkurang saat status `claimed`, bukan saat `paid`. Artinya dua konsumen bisa memesan porsi yang sama sebelum salah satunya datang mengambil. Untuk demo tidak masalah — jangan diperbaiki, dan jangan menambah pengecekan stok di klien yang bisa membuat alur pesan gagal saat demo.

**`DiscountPill`** — isian oranye, teks hitam. Ukuran mengikuti besar diskon: makin besar diskon, makin besar pill. Mata langsung tertarik ke penawaran terbaik tanpa membaca.

**2. Realtime — ini yang didemokan, dan paling mudah gagal**

```dart
listingRepository.liveListingsStream()
```

**Listing baru harus muncul tanpa refresh, dalam < 2 detik.** Menit 2:30 demo: merchant menekan validasi, kartunya langsung muncul di layar konsumen.

**Uji dengan dua perangkat sungguhan**, bukan hot reload. Ini satu-satunya cara membuktikannya bekerja.

Kartu baru masuk dengan fade + slide-up 12 px, 320 ms, `easeOutCubic`.

Tetap sediakan tarik-untuk-refresh sebagai cadangan kalau jaringan venue bermasalah.

**3. Detail listing**

Foto besar · nama · merchant · jarak · harga coret + harga oranye · sisa stok · **hitung mundur ke `expires_at`** · tombol Pesan.

Hitung mundur membangun urgensi. Kalau habis, kartu jadi non-aktif — bukan hilang tiba-tiba.

**4. Booking & pembayaran**

Warisi `user_payment_screen.dart` dari Ecobite (365 baris), ganti sumber data.

**Rincian harga wajib memisahkan green fee:**
```
Subtotal            Rp 32.000
Green Fee           Rp  1.000
─────────────────────────────
Total               Rp 33.000

Green Fee mendukung mesin kalkulasi emisi
dan infrastruktur realtime Lestar.
```
Ini disebut di menit 2:30 demo. Harus terlihat jelas.

Pembayaran **simulasi** — pilih metode, tunggu 1,5 detik, berhasil. Payment gateway sungguhan ada di non-goals.

Setelah bayar: `status='paid'`, `qr_token` terbit, langsung tampilkan QR.

**5. QR**

Warisi `user_claim_order_screen.dart` dari Ecobite (430 baris). `qr_flutter` sudah terpasang.

QR besar · nama merchant · alamat · hitung mundur 2 jam · daftar item.

**Kecerahan layar dinaikkan otomatis saat QR ditampilkan** — supaya mudah dipindai merchant. Ini detail kecil yang menyelamatkan demo.

FAB QR di tengah nav langsung membuka QR aktif kalau ada, atau `EmptyState` kalau tidak.

**6. Orders & Profil**

Boleh minimalis — tidak ada di jalur demo.

## Cara kerja

- Commit setiap layar yang jalan.
- Pesan commit Bahasa Indonesia.
- Butuh perubahan di berkas Agent B: tulis permintaan di handoff, jangan edit langsung.

## Selesai berarti

- Radar tidak bisa dibedakan dari mockup panel kiri
- Peta memuat, pin merchant nyata, jarak dari RPC benar
- `DiscountPill` ukurannya mengikuti besar diskon
- **Listing baru muncul realtime < 2 detik — diuji dengan dua perangkat**
- Alur pesan jalan penuh: detail → bayar → QR terbit
- Green fee terpisah dan terlihat jelas
- QR bisa dipindai merchant dan mengubah status jadi `claimed`
- Kecerahan naik otomatis saat QR tampil
- Hitung mundur berjalan dan akurat
- `EmptyState` ada di setiap daftar yang bisa kosong
- Nol `RenderFlex overflowed`
- Nol `#12C56A` di kodemu

## Sebelum menutup sesi

Tulis ringkasan di `docs/06-agent-briefs/E-HANDOFF.md`: layar yang selesai, yang belum, keputusan yang kamu ambil sendiri, dan permintaan perubahan ke Agent B kalau ada.

---

## Catatan dari Agent B (baca sebelum mulai)

**1. Layar milikmu sudah ada sebagai stub.** `radar_screen.dart`, `feed_screen.dart`, `qr_screen.dart`, `orders_screen.dart`, `profile_screen.dart` sudah ada di `lib/features/consumer/presentation/` — isinya kosong. **Ganti isinya**, jangan buat berkas baru.

**2. `listing.imageUrl` null untuk seluruh baris seed.** Foto belum diunggah ke bucket. Radar dan Feed-mu penuh kartu bergambar — siapkan placeholder yang rapi sejak awal, jangan ditunda.

**3. `flutter_map` versi 8, bukan 7.** API berubah: `MapOptions(center:, zoom:)` jadi `MapOptions(initialCenter:, initialZoom:)`. `LestarMap` di `lib/shared/widgets/lestar_map.dart` sudah memakai v8. Kalau mencari contoh di internet, pastikan contohnya untuk v8.

**4. Tanda tangan widget bersama dikunci.** `B-HANDOFF.md` §3. Tambahkan varian tema terang, jangan ubah tanda tangannya.

**5. Pakai `lib/core/utils/formatters.dart`** untuk rupiah, jarak, dan waktu — jangan menulis sendiri.

**6. Shell dan `NavigationBar` bukan milikmu.** Ada di `lib/core/routing/shells.dart`.
