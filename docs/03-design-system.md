# Lestar — Design System

**Versi** 3.0 · 29 Agustus 2026
**Sumber nilai** ekstraksi piksel dari `assets/logo.png` (600×600) dan `mockup.png` (2476×1778)

> **Riwayat revisi**
> v1.0 — warna tebakan (`#12C56A`). Salah, jangan dipakai.
> v2.0 — warna diekstrak dari mockup. Emerald saja, tanpa aksen.
> **v3.0 — dua keluarga warna dari logo.** Hijau = sistem & keberlanjutan. Oranye = selera & urgensi. Ini versi yang berlaku.

---

## 1. Prinsip

### 1.1 Tiga sistem desain, bukan satu

Lestar tidak memakai satu design system untuk tiga aktor. Mereka hidup di dunia yang berbeda.

| Aktor | Konteks pakai | Sistem |
|---|---|---|
| Konsumen | Sore–malam, di jalan, berburu diskon, HP modern | **Light Glass** |
| Merchant | Berjam-jam, di dapur/kasir, membaca angka, cahaya redup | **Dark Glass** |
| Pengepul | Luar ruangan, matahari terik, sarung tangan, HP entry-level, usia 40+ | **Plain** |

Ini keputusan aksesibilitas, bukan estetika. Glassmorphism di bawah matahari terik pada layar murah adalah antarmuka yang tidak terbaca.

### 1.2 Dua keluarga warna, dua makna

Lestar mengalirkan dua jenis nilai yang berbeda. Kalau keduanya berwarna sama, pengguna tidak bisa membedakannya.

| Hijau | Oranye |
|---|---|
| keberlanjutan, ESG, CO₂ | selera, harga, diskon |
| jalur B2B, limbah organik | flash sale, urgensi, hitung mundur |
| sistem, AI, kepercayaan, sukses | komersial, uang, "beli sekarang" |

Ini arsitektur informasi, bukan dekorasi. Warna mengerjakan sebagian dari tugas menjelaskan.

Oranye adalah warna selera — alasan yang sama kenapa hampir semua merek makanan memakainya. Hijau berkata *"tenang, berkelanjutan"*; flash sale butuh *"cepat, sebentar lagi habis"*. Hijau tidak bisa memberikannya.

## 2. Sumber palet: logo

Warna brand diambil dari `assets/logo.png`, bukan dari mockup. Logo adalah brand; mockup adalah draf.

| Elemen logo | Hex terukur |
|---|---|
| Sulur & daun | `#265938` |
| Buah | `#F38222` |
| Latar | `#EDE5D8` (tidak dipakai di app) |

Emerald cerah dari mockup dipertahankan sebagai anggota keluarga hijau yang lebih terang — cocok dengan token `emerald-500/600` Tailwind v4, jadi palet punya rujukan yang bisa diverifikasi.

## 3. Token

```dart
// lib/core/theme/tokens.dart
class LestarTokens {
  // ── HIJAU — sistem, keberlanjutan, kepercayaan
  static const forest       = Color(0xFF265938);  // logo. teks pekat, permukaan brand
  static const emeraldDeep  = Color(0xFF009966);  // emerald-600. tombol aksi
  static const emerald      = Color(0xFF00BC7D);  // emerald-500. status aktif, ikon, badge AI
  static const emeraldTint  = Color(0xFFECFAEF);  // latar chip hijau

  // ── ORANYE — selera, urgensi, uang
  static const orange       = Color(0xFFF38222);  // logo. pill diskon, CTA beli, hitung mundur
  static const orangeText   = Color(0xFFC2540E);  // teks oranye di atas latar terang
  static const orangeTint   = Color(0xFFFFF1E4);  // latar chip oranye

  // ── Netral (Tailwind v4)
  static const ink          = Color(0xFF0A0A0A);  // neutral-950
  static const inkSoft      = Color(0xFF171717);  // neutral-900
  static const muted        = Color(0xFF737373);  // neutral-500
  static const mutedSoft    = Color(0xFFA1A1A1);  // neutral-400
  static const surfaceGrey  = Color(0xFFF5F5F5);  // neutral-100

  static const danger       = Color(0xFFE5484D);
}
```

### Kontras terukur — pakai tabel ini, jangan menebak

| Kombinasi | Rasio | Status | Pakai untuk |
|---|---|---|---|
| `ink` di atas putih | 19,0 : 1 | AAA | teks isi |
| `forest` di atas putih | 8,1 : 1 | AAA | judul, teks penting |
| putih di atas `forest` | 8,1 : 1 | AAA | tombol gelap |
| **`ink` di atas `orange`** | **7,2 : 1** | **AAA** | **pill diskon, chip harga** |
| `orangeText` di atas putih | 4,6 : 1 | AA | teks harga |
| putih di atas `emeraldDeep` | 3,65 : 1 | AA besar | tombol utama (teks ≥ 18 sp bold) |
| `emeraldDeep` di atas putih | 3,65 : 1 | AA besar | angka raksasa |
| ~~putih di atas `emerald`~~ | 2,5 : 1 | ❌ gagal | **jangan dipakai untuk teks** |

**Aturan:** `#00BC7D` hanya untuk ikon, garis, dan indikator — **tidak pernah** sebagai latar teks.
**Aturan:** isian oranye selalu memakai teks gelap `#0A0A0A`, tidak pernah putih.

## 4. Tipografi

| Peran | Font | Untuk |
|---|---|---|
| **Display** | **Plus Jakarta Sans** | judul, angka besar, tombol, label HURUF BESAR |
| **Body** | **Inter** | teks isi, deskripsi, label kecil, input, nav |

**Plus Jakarta Sans** cocok dengan bentuk huruf di mockup — `a` dua tingkat tanpa ekor, `g` satu tingkat berekor terbuka, terminal dipotong horizontal, x-height tinggi. Dibuat Tokotype untuk Pemprov DKI Jakarta: cerita brand yang relevan untuk produk Indonesia.

**Inter** untuk body karena Plus Jakarta Sans melemah di ukuran kecil. Inter dirancang untuk teks UI kecil dan punya angka tabular yang rapi — penting untuk dashboard merchant.

### ⚠ Font wajib dibundel

Berkas sudah tersedia di `assets/fonts/`:
```
PlusJakartaSans[wght].ttf     176 KB   variable, wght 200–800
Inter[opsz,wght].ttf          877 KB   variable, wght 100–900
```

```yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans[wght].ttf
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter[opsz,wght].ttf
```

Karena ini **variable font**, satu berkas melayani semua bobot. Bobot diatur lewat `fontVariations`, bukan `fontWeight`:

```dart
TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontVariations: [const FontVariation('wght', 800)],
  fontSize: 90,
)
```

**Jangan pakai paket `google_fonts` untuk kedua font ini.** Paket itu mengambil font lewat jaringan. Saat WiFi dimatikan di penutup demo, teks jatuh ke fallback sistem dan merusak momen yang justru ingin ditonjolkan. Uji dengan mode pesawat sebelum menyatakan selesai.

### Skala

| Peran | Font | Ukuran | wght |
|---|---|---|---|
| Angka raksasa pengepul | Plus Jakarta Sans | 90 | 800 |
| Judul pengepul | Plus Jakarta Sans | 44 | 700 |
| Angka besar merchant | Plus Jakarta Sans | 48 | 700 |
| Judul layar | Plus Jakarta Sans | 32 | 700 |
| Judul kartu | Plus Jakarta Sans | 20 | 600 |
| Body | Inter | 15 | 400 |
| Label | Inter | 13 | 500 |
| Caption | Inter | 11 | 400 |

## 5. Logo

`assets/logo.png` — lemniskat ∞ yang dibentuk dari sulur, daun, dan buah. Konsepnya tepat: ekonomi sirkular yang hidup.

**Warnanya tidak diubah.** Logo adalah sumber kebenaran palet.

Yang perlu dikerjakan hanya dua hal teknis:

| Varian | Kebutuhan | Dipakai di |
|---|---|---|
| `logo-full.png` | latar krem dibuang jadi transparan, bayangan dihapus | landing page, deck, layar splash |
| `logo-glyph.png` | disederhanakan — lemniskat + 2–3 daun saja, tanpa sulur rinci | app bar 40 dp, ikon peluncur, favicon |
| `logo-wordmark` | teks "Lestar" Plus Jakarta Sans 700 + glyph di kiri | header landing page |

Logo saat ini 600×600 opaque (`Format24bppRgb`) dengan tekstur kertas dan bayangan ikut terbawa. **Tidak bisa dipakai apa adanya di atas permukaan berwarna** — di layar merchant `#10140F` kotak krem akan menyala seperti stiker.

Detail sulur juga terlalu rapat untuk 40 dp ke bawah. Karena itu varian glyph wajib ada.

## 6. Sistem 1 — Light Glass (Konsumen)

`lib/core/theme/light_glass.dart`

Di sinilah dua keluarga warna paling terasa. Mockup asli memakai emerald untuk segalanya — pill diskon, harga, FAB, nav aktif — sehingga tidak ada hierarki. Versi ini memisahkannya.

```dart
// Latar
bgGradient   LinearGradient(#ECFAEF → #F9FDFA, topCenter → bottomCenter)
surface      #FFFFFF
surfaceAlt   #F9FDFA

// Peta
mapSurface   #E4F0E2
mapRoad      #FFFFFF
mapPark      #CFE6C9

// Kaca
glassFill    Color(0xFFF2F9FA).withOpacity(0.55)
glassBlur    BackdropFilter(sigmaX: 20, sigmaY: 20)
glassBorder  Colors.white.withOpacity(0.60), width 1
glassShadow  BoxShadow(Colors.black.withOpacity(0.06), blur 24, offset (0,8))

inputFill    #F2FCF6

// Teks
textPrimary    #171717
textSecondary  #737373
greeting       #265938      // forest — sapaan, judul layar
```

### Pembagian warna

| Elemen | Warna | Alasan |
|---|---|---|
| Sapaan, judul layar | `forest #265938` | brand, tenang, kontras 8:1 |
| Nav aktif, ikon sistem | `emerald #00BC7D` | status, bukan aksi |
| Badge `AI −64%` | `emerald #00BC7D` isian, teks putih | ini label sistem, bukan harga |
| **Pill diskon di peta** | **`orange #F38222` isian, teks `#0A0A0A`** | urgensi. kontras 7,2:1 |
| **Harga baru** | **`orangeText #C2540E`** | uang. kontras 4,6:1 |
| Harga coret | `muted #737373` dicoret | |
| **Tombol Pesan** | **`orange #F38222`, teks `#0A0A0A`** | CTA komersial |
| **Hitung mundur** | **`orange #F38222`** | waktu menipis |
| FAB QR | `emeraldDeep #009966`, ikon putih | ini alat, bukan penjualan |
| Chip "Terselamatkan" | `emeraldTint` + teks `forest` | dampak lingkungan |

Sekarang mata punya arah: **oranye = uang dan waktu, hijau = sistem dan dampak.**

### Layar utama — Live Flash Radar

```
Selamat malam, Amira                   [📍 Menteng]     ← forest
Live Flash Radar                                        ← forest, 32/700

[ 🔍 Cari makanan terselamatkan...        ]

┌─────────────────────────────────────────┐
│  PETA (flutter_map)                     │
│    ·−52%      ·−64%     ← pill ORANYE, teks hitam
│         ·−61%                           │
│  ┌───────────────────────────────────┐  │
│  │ [img] Assorted Butter Croissant   │  │ ← GlassCard
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

**Bottom nav** — glass `#F9FDFA`, 5 item: Radar · Feed · **[FAB QR]** · Orders · Profil. Aktif `emerald`, non-aktif `muted`.

**`DiscountPill`** — isian `orange`, teks `ink`. Ukuran mengikuti besar diskon: makin besar diskon, makin besar pill. Mata langsung tertarik ke penawaran terbaik tanpa membaca.

## 7. Sistem 2 — Dark Glass (Merchant)

`lib/core/theme/dark_glass.dart`

Kokpit operasi. Hijau tetap dominan — merchant memakainya berjam-jam, tenang itu benar. Oranye masuk hanya untuk uang dan peringatan.

```dart
bg           #10140F      // 30,4% piksel panel — latar utama
surfaceDeep  #0D120C
card         #151A13      // kartu forecast
cardAlt      #141912
tile         #1C201B      // KPI tile

narrativeBg  #11291B      // kartu narasi Gemini — tint hijau
badgeBg      #113525      // badge akurasi

glassFill    Colors.white.withOpacity(0.04)
glassBlur    BackdropFilter(sigmaX: 16, sigmaY: 16)
glassBorder  Colors.white.withOpacity(0.06), width 1

textPrimary    #FFFFFF
textSecondary  Colors.white.withOpacity(0.60)
textTertiary   Colors.white.withOpacity(0.38)

accent       #00BC7D                              // AI, sistem, sukses
money        #F38222                              // pendapatan, uang
warnFg       #F38222
warnBg       Color(0xFFF38222).withOpacity(0.14)  // chip peringatan
```

Latar `#10140F` bersemu hijau, **bukan** `#000000` netral. Hitam murni membuat kartu melayang terlalu tajam dan melelahkan mata saat dipakai berjam-jam.

### Pembagian warna

| Elemen | Warna |
|---|---|
| Angka forecast `48 kg` | putih |
| Badge akurasi `94%` | `emerald` di atas `#113525` |
| Badge sumber AI | `emerald` / `emeraldDeep` / `white @38%` |
| Garis chart demand | `emerald #00BC7D` tebal |
| **Garis chart current plan** | **`orange #F38222` tipis putus-putus** |
| **Chip `⚠ −12 kg vs plan`** | **teks `orange`, latar `orange @14%`** |
| **KPI `Rp 1.86M`** | **`orange`** |
| KPI `48.9 kg waste diverted` | `emerald` |
| KPI `79 items listed` | putih |
| Tombol `Apply recommended order` | `emeraldDeep`, teks putih |

Sekarang chart terbaca tanpa legenda: **hijau = yang direkomendasikan AI, oranye = rencanamu sekarang.** Selisihnya jadi tampak sebagai selisih warna.

### Layar utama

```
[logo] Verde Kitchen                            [🔔•]
       Merchant Console

Dashboard
Live operations · 7 Jul 2026

┌────────────────────────────────────────────┐
│ 📈 Stock Forecast · Tomorrow  [94% accuracy]│ ← badge hijau
│                                            │
│ Prep for Friday (predicted demand)         │
│ 48 kg                    [⚠ −12 kg vs plan]│ ← chip ORANYE
│                                            │
│      ╭──────╮                              │
│  ────╯      ╰───                           │
│  Tue Wed Thu Fri Sat Sun                   │
│  ── demand (hijau)   ┄┄ current plan (oranye)│
│                                            │
│ ┌────────────────────────────────────────┐ │
│ │ Kurangi produksi 20% besok untuk       │ │  bg #11291B
│ │ mencegah ~12 kg surplus.               │ │
│ └────────────────────────────────────────┘ │
│                                            │
│ [    Apply recommended order         ↗ ]   │
│                          AI · LSTM + Gemini│
└────────────────────────────────────────────┘

[Rp 1.86M]  [48.9 kg]  [79 items]
  ORANYE      hijau      putih
```

**`SourceBadge`** — tiga varian jujur: `AI · LSTM + Gemini` (`emerald`) · `AI · LSTM` (`emeraldDeep`) · `Mode offline · heuristik` (`white @38%`).

## 8. Sistem 3 — Plain (Pengepul)

`lib/core/theme/plain.dart`

**Ini bukan versi "belum jadi" dari dua sistem lain. Ini keputusan yang disengaja.**

Pengepul bukan sedang berbelanja — dia sedang bekerja. Karena itu panel ini tetap hijau. Oranye hanya muncul untuk hal yang benar-benar mendesak.

```dart
bg             #FFFFFF        // 51,9% piksel panel
bgAlt          #F5F5F5
textPrimary    #0A0A0A        // 19:1
textSecondary  #737373
textTertiary   #A1A1A1
bigNumber      #009966        // angka 25 KG — 3,65:1, lolos AA teks besar
buttonFill     #009966
buttonText     #FFFFFF
accentIcon     #00BC7D        // ikon, garis — tidak pernah latar teks
urgent         #F38222        // "SEGERA DIJEMPUT", sisa waktu

// Efek: NOL
// tanpa BackdropFilter, tanpa gradient, tanpa BoxShadow
// (kecuali glow tombol utama), tanpa opacity di teks
```

**Jangan pakai `#00BC7D` sebagai isian tombol.** Mockup memakainya, tapi teks putih di atasnya hanya 2,5:1 — gagal WCAG bahkan untuk teks besar. Isian tombol memakai `#009966` (3,65:1). Bedanya nyaris tak terlihat di layar, tapi nyata di bawah matahari — persis konteks pemakaian Pak Budi.

*Kalau uji lapangan menunjukkan masih kurang terbaca, naikkan ke `forest #265938` — kontras 8,1:1, tapi tombolnya jadi gelap dan kehilangan kesan "jalan".*

### Aturan keras

| Aturan | Alasan |
|---|---|
| **Satu layar, satu aksi utama** | Dipakai sambil membawa barang atau menyetir |
| Tombol utama tinggi **minimal 120 dp** | Bisa ditekan tanpa melihat, dengan sarung tangan |
| Angka utama **minimal 72 sp** | Terbaca di bawah matahari, mata 40+ |
| Semua label **HURUF BESAR** | Terbaca sekilas |
| **Tanpa istilah Inggris** | "JEMPUT SEKARANG", bukan "Pick Up Now" |
| Tanpa scroll horizontal | Gestur rumit gagal dengan tangan kotor |
| Tanpa modal, tanpa bottom sheet | Gestur tutup tidak jelas |
| Maksimal **3 item** bottom nav | Target sentuh besar |
| Teks isi kontras ≥ **7:1** | Tercapai: 19:1 |
| Teks besar kontras ≥ **3:1** | Tercapai: 3,65:1 |
| **Tanpa animasi masuk** | Animasi memperlambat pemahaman |

Satu-satunya bayangan yang diizinkan: glow emerald di bawah tombol utama — penanda bahwa elemen ini bisa ditekan.

### Layar utama

```
Halo, Pak Budi

      [📍 Desa Sukamaju]

     ADA SAMPAH                 ← 40 sp, #737373
      ORGANIK

    TERSEDIA                    ← 44 sp, #0A0A0A, 700
     25 KG                      ← 90 sp, #009966, 800

  Jarak 1,2 KM dari rumah       ← 24 sp, #737373

┌──────────────────────────────┐
│    🚚  JEMPUT                │   ← tinggi 140 dp
│        SEKARANG              │      #009966, teks putih
└──────────────────────────────┘

──────────────────────────────────
[🏠 BERANDA] [✓ RIWAYAT] [💳 LANGGANAN]
```

### Kalau tidak ada limbah

```
        BELUM ADA
        SAMPAH HARI INI

     Kami kabari kalau ada

   [ LIHAT PETA SEKITAR ]     ← outline
```

## 9. Komponen bersama

`lib/shared/widgets/` — gaya diatur lewat `Theme.of(context)`.

| Widget | Dipakai di |
|---|---|
| `GlassCard` | konsumen |
| `DarkGlassCard` | merchant |
| `PlainCard` | pengepul — border 2 px, tanpa bayangan |
| `BigButton` | pengepul — tinggi 120–140 |
| `StatTile` | merchant, pengepul |
| `SourceBadge` | merchant |
| `DiscountPill` | konsumen — **oranye** |
| `PriceText` | konsumen — harga coret + harga oranye |
| `CountdownChip` | konsumen — **oranye** |
| `LestarMap` | konsumen, pengepul |
| `QrDisplay` / `QrScanner` | konsumen, merchant |
| `EmptyState` | semua |
| `OfflineBanner` | semua |

## 10. Gerak

Pakai skill `flutter-animations` di `.agents/skills/`.

| Konteks | Gerak | Durasi |
|---|---|---|
| Kartu baru masuk radar (realtime) | fade + slide-up 12 px | 320 ms `easeOutCubic` |
| Angka forecast berubah | `AnimatedSwitcher` + counter naik | 600 ms |
| Tekan validasi fisik | denyut sekali lalu centang | 400 ms |
| Status kaskade berpindah | garis penghubung tergambar | 500 ms |
| Hitung mundur < 15 menit | pill oranye berdenyut halus | 1200 ms berulang |
| Layar pengepul | **tanpa animasi masuk** | 0 ms |

## 11. Aset

| Aset | Status |
|---|---|
| `assets/fonts/PlusJakartaSans[wght].ttf` | ✅ terunduh |
| `assets/fonts/Inter[opsz,wght].ttf` | ✅ terunduh |
| `assets/logo.png` | ✅ ada — butuh 3 varian, lihat §5 |
| Foto makanan | Unsplash/Pexels, ~40 foto Indonesia, bucket `product-images` |
| Ikon | Material Icons bawaan Flutter |

**Tidak memakai AI image generation untuk foto makanan.** Hasil generate sering janggal pada tekstur dan bayangan, dan itu terbaca di layar besar saat presentasi.

## 12. Daftar periksa sebelum demo

- [ ] Nol `#12C56A` di kode mana pun — itu warna v1.0 yang salah
- [ ] Nol pemakaian `#00BC7D` sebagai latar teks — hanya ikon dan garis
- [ ] Semua isian oranye memakai teks `#0A0A0A`, bukan putih
- [ ] Font **dibundel**, bukan `google_fonts` — uji dengan mode pesawat
- [ ] `fontVariations` dipakai untuk bobot, bukan `fontWeight`
- [ ] Tiga tema jelas berbeda saat disandingkan
- [ ] Panel konsumen: oranye dan hijau terbagi sesuai §6
- [ ] Chart merchant terbaca tanpa legenda (hijau vs oranye)
- [ ] Nol `RenderFlex overflowed` (skill `flutter-fix-layout-issues`)
- [ ] Layar pengepul terbaca dari jarak 1,5 meter
- [ ] Kontras diverifikasi dengan alat ukur, cocok dengan tabel §3
- [ ] Logo punya varian transparan + glyph
- [ ] Semua teks Bahasa Indonesia, kecuali istilah di mockup merchant
- [ ] Semua harga `Rp 32.000`, bukan `32000.0`
