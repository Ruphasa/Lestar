# Agent E — UI Konsumen (Light Glass)

**Jadwal** Senin 31 Agustus · **Bergantung pada** B · **Acuan visual** `mockup.png` panel kiri

---

## Milik kamu

```
lib/features/consumer/
lib/core/theme/light_glass.dart
```

## Baca dulu

1. `docs/03-design-system.md` §3 — spesifikasi Light Glass lengkap
2. `mockup.png` panel kiri
3. `docs/05-demo-script.md` menit 2:30–3:30 — layarmu ada di jalur demo

## Prinsip

Konsumen memakai app ini sore–malam, di jalan, sambil berburu diskon. Rasa yang dituju: **ringan, cepat, menyenangkan**. Berburu, bukan berbelanja.

## Lima tab

```
ConsumerShell
  ├── Radar    peta + daftar terdekat        ← layar utama
  ├── Feed     grid flash deals
  ├── [QR]     FAB tengah — QR aktif milikku
  ├── Orders   riwayat pesanan
  └── Profil
```

## Tugas

### 1. Tema — `lib/core/theme/light_glass.dart`

Token lengkap ada di `03-design-system.md` §6. Isi kerangka dari Agent B.

Komponen varian terang: `GlassCard` · `DiscountPill` · `PriceText` · `CountdownChip` · `StatTile` · `EmptyState`

`GlassCard` adalah pembungkus dasar seluruh UI konsumen — buat ini dulu, semua layar bergantung padanya.

### ⚠ 1b. Panelmu paling berubah dari mockup — baca ini

Mockup memakai emerald untuk **segalanya**: pill diskon, harga, FAB, nav aktif, badge AI. Akibatnya tidak ada hierarki — mata tidak tahu harus ke mana dulu.

Design system v3.0 memisahkannya jadi dua keluarga warna. **Ikuti pembagian ini, jangan tiru warna mockup mentah-mentah.**

| Elemen | Warna | Kenapa |
|---|---|---|
| Sapaan, judul layar | `forest #265938` | brand, tenang, kontras 8:1 |
| Nav aktif, ikon sistem | `emerald #00BC7D` | status, bukan aksi |
| Badge `AI −64%` | `emerald` isian, teks putih | label sistem, bukan harga |
| **Pill diskon di peta** | **`orange #F38222`, teks `#0A0A0A`** | urgensi. kontras 7,2:1 |
| **Harga baru** | **`orangeText #C2540E`** | uang. kontras 4,6:1 |
| Harga coret | `muted #737373` dicoret | |
| **Tombol Pesan** | **`orange #F38222`, teks `#0A0A0A`** | CTA komersial |
| **Hitung mundur** | **`orange #F38222`** | waktu menipis |
| FAB QR | `emeraldDeep #009966`, ikon putih | alat, bukan penjualan |
| Chip "Terselamatkan" | `emeraldTint` + teks `forest` | dampak lingkungan |

Prinsipnya: **oranye = uang dan waktu. hijau = sistem dan dampak.**

**Dua aturan keras:**
- Isian oranye **selalu** memakai teks gelap `#0A0A0A`, tidak pernah putih (putih di atas oranye hanya 2,6:1)
- `#00BC7D` **tidak pernah** jadi latar teks — hanya ikon, garis, indikator

### 2. Radar — layar utama

```
Good evening, Amira                    [📍 Menteng]
Live Flash Radar

[ 🔍 Cari makanan terselamatkan...        ]   ← glass input

┌─────────────────────────────────────────┐
│  PETA (flutter_map + OSM)               │
│    ·−52%      ·−64%     ← pill ORANYE, teks hitam
│         ·−61%                           │
│  ┌───────────────────────────────────┐  │
│  │ [img] Assorted Butter Croissant   │  │ ← GlassCard melayang
│  │       Rue Bakehouse · 0.4 km      │  │
│  │       R̶p̶ ̶8̶8̶.̶0̶0̶0̶   Rp 32.000      │  │ ← harga ORANYE
│  │       ⏱ 47 menit lagi              │  │ ← ORANYE
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

Flash deals · segera berakhir           Lihat semua
┌──────────────┐  ┌──────────────┐
│ [AI −64%]    │  │ [AI −52%]    │  ← badge AI HIJAU
│    foto      │  │    foto      │
│ Croissant    │  │ Salmon Sushi │
│ Rp 32.000    │  │ Rp 69.000    │  ← ORANYE
└──────────────┘  └──────────────┘
```

**`DiscountPill`** — isian `orange #F38222`, teks `#0A0A0A`. Ukuran mengikuti besar diskon: makin besar diskon, makin besar pill. Mata langsung tertarik ke penawaran terbaik tanpa harus membaca.

**Badge `AI −64%`** tetap **hijau** — ini label sistem, bukan harga. Fungsinya memberi tahu konsumen bahwa harga ditentukan sistem, bukan tawar-menawar. Membangun kepercayaan.

Perhatikan bedanya: pill diskon di peta itu **penawaran** (oranye), badge AI di kartu itu **penjelasan** (hijau). Dua hal berbeda, dua warna berbeda.

**Peta** memakai `flutter_map` + tile OpenStreetMap.

**Jarak dihitung di database, bukan di Dart.** Agent A menyediakan fungsi RPC yang memakai ekstensi `earthdistance` + index GiST:
```dart
supabase.rpc('nearby_listings', params: {
  'p_lat': posisi.latitude, 'p_lng': posisi.longitude, 'p_radius_km': 5,
});   // listing + store_name/address/image + jarak_km, sudah terurut
```
Awalan `p_` wajib — itu nama parameter sebenarnya di database. Kembaliannya sudah menyertakan data merchant, jadi tidak perlu query kedua untuk nama toko.
Jangan hitung haversine manual lalu saring di klien — lebih lambat, dan menarik seluruh tabel ke perangkat.

### 3. Realtime — ini yang didemokan

```dart
listingRepository.liveListingsStream()
```

**Listing baru harus muncul tanpa refresh, dalam < 2 detik.** Ini yang ditunjukkan di menit 2:30 demo: merchant menekan validasi, dan kartunya langsung muncul di layar konsumen.

Kartu baru masuk dengan animasi fade + slide-up 12 px, 320 ms, `easeOutCubic`. Pakai skill `flutter-animations`.

Tetap sediakan tarik-untuk-refresh sebagai cadangan kalau jaringan venue bermasalah.

### 4. Detail listing

Foto besar · nama · merchant · jarak · harga coret + harga baru · sisa stok · waktu tersisa (hitung mundur) · tombol **Pesan**.

Hitung mundur ke `expires_at` membangun urgensi. Kalau habis, kartu berubah jadi non-aktif, bukan hilang tiba-tiba.

### 5. Booking & pembayaran

Warisi `user_payment_screen.dart` dari Ecobite (365 baris), ganti sumber data.

**Rincian harga wajib memisahkan green fee:**
```
Subtotal            Rp 32.000
Green Fee           Rp  1.000
─────────────────────────────
Total               Rp 33.000

Green Fee mendukung mesin kalkulasi
emisi dan infrastruktur realtime Lestar.
```

Ini disebut di menit 2:30 demo. Harus terlihat jelas.

Pembayaran **simulasi** — pilih metode, tunggu 1,5 detik, berhasil. Payment gateway sungguhan ada di non-goals (`00-PRD.md` §5.3).

Setelah bayar: `orders.status = 'paid'`, `qr_token` terbit, langsung tampilkan QR.

### 6. QR

Warisi `user_claim_order_screen.dart` dari Ecobite (430 baris). `qr_flutter` sudah terpasang.

Tampilkan: QR besar · nama merchant · alamat · hitung mundur masa berlaku (2 jam) · daftar item.

Kecerahan layar dinaikkan otomatis saat QR ditampilkan — supaya mudah dipindai merchant.

FAB QR di tengah bottom nav langsung membuka QR aktif kalau ada, atau `EmptyState` kalau tidak ada.

### 7. Orders & Profil

Riwayat pesanan dengan status. Profil sederhana: nama, foto, eco points, alamat, keluar.

Kedua layar ini boleh minimalis — tidak ada di jalur demo.

## Definisi selesai

- [ ] Radar tidak bisa dibedakan dari mockup panel kiri
- [ ] Peta memuat, pin merchant nyata dari Supabase, jarak dihitung benar
- [ ] `DiscountPill` ukurannya mengikuti besar diskon
- [ ] Listing baru muncul realtime < 2 detik tanpa refresh — **diuji dengan dua perangkat**
- [ ] Alur pesan jalan penuh: detail → bayar → QR terbit
- [ ] Green fee terpisah dan terlihat jelas di rincian
- [ ] QR bisa dipindai merchant dan mengubah status jadi `claimed`
- [ ] Kecerahan naik otomatis saat QR tampil
- [ ] Hitung mundur berjalan dan akurat
- [ ] Nol `RenderFlex overflowed` — pakai skill `flutter-fix-layout-issues`
- [ ] `EmptyState` ada di setiap daftar yang bisa kosong
