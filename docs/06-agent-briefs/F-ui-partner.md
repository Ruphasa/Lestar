# Agent F — UI Pengepul (Plain / "UI Bodoh")

**Jadwal** Senin 31 Agustus · **Bergantung pada** B · **Acuan visual** `mockup.png` panel kanan

---

## Milik kamu

```
lib/features/partner/
lib/core/theme/plain.dart
```

## Baca dulu

1. `docs/03-design-system.md` §5 — spesifikasi Plain lengkap
2. `mockup.png` panel kanan
3. `docs/05-demo-script.md` menit 5:00–6:00 — **layarmu adalah puncak demo**

## Prinsip — baca ini dua kali

**Ini bukan versi "belum jadi" dari dua UI lain. Ini keputusan desain yang disengaja, dan ini pembeda terkuat produk di depan juri.**

Pak Budi berusia 52 tahun. HP-nya entry-level. Dia membaca layar ini di luar ruangan, di bawah matahari, sambil membawa ember, kadang bersarung tangan, kadang sambil menyetir motor.

Glassmorphism di tangannya bukan keindahan — itu penghalang. Blur menurunkan kontras. Transparansi membuat teks bertabrakan dengan latar. Radius besar dan bayangan halus tidak terlihat di layar murah.

Yang dia butuhkan: **kontras maksimum, tipografi raksasa, satu tombol.**

Kalau kamu tergoda menambahkan gradasi, bayangan halus, atau kartu melayang di sini — jangan. Setiap efek yang kamu tambahkan menghapus alasan keberadaan UI ini.

## Aturan keras

| Aturan | Alasan |
|---|---|
| **Satu layar, satu aksi utama** | Dipakai sambil membawa barang atau menyetir |
| Tombol utama tinggi **minimal 120 dp** | Bisa ditekan tanpa melihat, dengan sarung tangan |
| Angka utama **minimal 72 sp** | Terbaca di bawah matahari, mata 40+ |
| Semua label **HURUF BESAR** | Terbaca sekilas |
| **Tanpa istilah Inggris** | "JEMPUT SEKARANG", bukan "Pick Up Now" |
| Tanpa scroll horizontal | Gestur rumit gagal dengan tangan kotor |
| Tanpa modal, tanpa bottom sheet | Butuh gestur tutup yang tidak jelas |
| Maksimal **3 item** bottom nav | Target sentuh besar |
| Kontras minimum **7:1** | WCAG AAA — syarat keterbacaan di luar ruangan |
| **Tanpa animasi masuk** | Animasi memperlambat pemahaman bagi yang butuh informasi seketika |

Satu-satunya bayangan yang diizinkan: glow emerald di bawah tombol utama. Itu bukan hiasan — itu penanda bahwa elemen ini bisa ditekan.

## Tiga tab

```
PartnerShell
  ├── BERANDA     limbah terdekat + tombol jemput
  ├── RIWAYAT     penjemputan selesai
  └── LANGGANAN   status berlangganan
```

## Tugas

### 1. Tema — `lib/core/theme/plain.dart`

```dart
bg             #FFFFFF        // 51,9% piksel panel mockup
bgAlt          #F5F5F5
textPrimary    #0A0A0A        // neutral-950
textSecondary  #737373        // neutral-500
textTertiary   #A1A1A1        // neutral-400
bigNumber      #009966        // emerald-600 — angka 25 KG
buttonFill     #009966        // emerald-600 — lihat catatan kontras
buttonText     #FFFFFF
accentIcon     #00BC7D        // emerald-500 — ikon, garis, non-kritis
urgent         #F38222        // oranye — HANYA untuk "SEGERA DIJEMPUT", sisa waktu

// Efek: NOL
// tanpa BackdropFilter
// tanpa gradient
// tanpa BoxShadow (kecuali glow tombol utama)
// tanpa opacity di teks
```

**Catatan kontras — jangan pakai `#00BC7D` untuk isian tombol.** Mockup memakainya, tapi teks putih di atas `#00BC7D` hanya mencapai **2,5 : 1** — gagal WCAG bahkan untuk teks besar. Isian tombol memakai `#009966` (3,65 : 1, lolos AA teks besar). Bedanya nyaris tak terlihat di layar, tapi nyata di bawah matahari — dan itu persis konteks pemakaian Pak Budi. Detail: `03-design-system.md` §7.

**Font:** display **Plus Jakarta Sans** (angka besar, label HURUF BESAR), body **Inter**. Keduanya **dibundel** di `assets/fonts/` sebagai variable font — atur bobot lewat `fontVariations`, bukan `fontWeight`. Jangan pakai paket `google_fonts`.

**Soal oranye:** panelmu tetap hijau. Pengepul bukan sedang berbelanja — dia sedang bekerja, dan tenang itu benar. Oranye `#F38222` hanya muncul untuk hal yang benar-benar mendesak: status "SEGERA DIJEMPUT" dan sisa waktu penjemputan. **Tombol JEMPUT SEKARANG tetap hijau `#009966`.**

Komponen: `PlainCard` (border 2 px, tanpa bayangan) · `BigButton` (tinggi 120–140) · `StatTile` varian polos · `EmptyState` varian polos.

### 2. BERANDA — puncak demo

```
Halo, Pak Budi

      [📍 Desa Sukamaju]

     ADA SAMPAH                 ← 40 sp, abu-abu, tengah
      ORGANIK

    TERSEDIA                    ← 44 sp, hitam, bold
     25 KG                      ← 90 sp, emerald, extra bold

  Jarak 1,2 KM dari rumah       ← 24 sp, abu-abu

┌──────────────────────────────┐
│                              │
│    🚚  JEMPUT                │   ← tinggi 140 dp
│        SEKARANG              │      emerald, glow
│                              │
└──────────────────────────────┘

──────────────────────────────────
[🏠 BERANDA] [✓ RIWAYAT] [💳 LANGGANAN]
```

**Sumber data:** fungsi RPC `nearby_waste(lat, lng, radius_km)` dari Agent A — memakai ekstensi `earthdistance` + index GiST, jadi jarak dihitung dan diurutkan di database.

```dart
supabase.rpc('nearby_waste', params: {
  'lat': partner.baseLat, 'lng': partner.baseLng,
  'radius_km': partner.serviceRadiusKm,
});   // mengembalikan waste_batches + jarak_km, terurut terdekat
```

Saring lagi ke `waste_preference` partner (`wet` / `dry`). Kalau ada beberapa batch, tampilkan **jarak yang terdekat** dan **jumlahkan seluruh beratnya** jadi satu angka besar — itulah `25 KG` di mockup. Jangan tampilkan daftar.

Langganan realtime tetap dipakai untuk memicu pemuatan ulang RPC saat ada batch baru masuk, bukan untuk menghitung jarak sendiri di Dart.

Jangan menampilkan daftar. Satu angka, satu jarak, satu tombol.

**Tekan JEMPUT SEKARANG** → `waste_batches.status = 'matched'`, `matched_partner_id` terisi → merchant menerima notifikasi realtime.

Setelah ditekan, layar berubah jadi mode perjalanan:
```
      SEDANG MENUJU

    Verde Kitchen
    Jl. Soekarno Hatta 12

      1,2 KM

  [ BUKA PETA ]        ← tombol sekunder, outline

  [ SUDAH SAMPAI ]     ← tombol utama, besar
```

**SUDAH SAMPAI** → `picked_up` → tombol berubah jadi **SELESAI** → `completed` → `esg_events` tertulis.

### 3. Kalau tidak ada limbah

Jangan tampilkan daftar kosong.

```
        BELUM ADA
        SAMPAH HARI INI

     Kami kabari kalau ada

   [ LIHAT PETA SEKITAR ]     ← tombol sekunder, outline
```

### 4. Peta sekitar

`flutter_map` + OSM. Pin besar, label berat langsung di atas pin (`25 KG`), bukan di popup.

Gaya peta berbeda dari milik konsumen: saturasi lebih rendah, pin lebih besar, tanpa kartu melayang.

Ketuk pin → langsung ke layar BERANDA untuk batch itu. Tanpa perantara.

### 5. RIWAYAT

Daftar penjemputan selesai. Kartu besar, satu per baris:
```
┌──────────────────────────────┐
│  VERDE KITCHEN               │
│  25 KG                       │
│  Kemarin, 21.30              │
└──────────────────────────────┘
```

Di atas daftar, tiga `StatTile` polos: total kg bulan ini · jumlah penjemputan · perkiraan hemat biaya.

### 6. LANGGANAN

Warisi `partner_subscription_screen.dart` dari Ecobite (189 baris), sederhanakan drastis mengikuti aturan di atas.

Status berlangganan + tanggal berakhir + satu tombol perpanjang. Pembayaran simulasi.

**Ini item pertama yang dikorbankan kalau waktu habis.** Kalau terpaksa: cukup tampilkan status berlangganan tanpa alur pembayaran.

## Definisi selesai

- [ ] BERANDA tidak bisa dibedakan dari mockup panel kanan
- [ ] Angka berat **terbaca dari jarak 1,5 meter** — uji langsung, jangan diperkirakan
- [ ] Kontras lolos **7:1** — verifikasi dengan alat pengukur kontras
- [ ] Tombol utama tinggi ≥ 120 dp
- [ ] Nol efek kaca, nol gradasi, nol bayangan kecuali glow tombol
- [ ] Semua teks Bahasa Indonesia, **nol istilah Inggris**
- [ ] Batch baru muncul realtime saat merchant melakukan kaskade
- [ ] Alur jemput jalan penuh: `available` → `matched` → `picked_up` → `completed`
- [ ] Merchant menerima notifikasi saat partner menekan JEMPUT
- [ ] `esg_events` tertulis saat `completed`
- [ ] Nol `RenderFlex overflowed` — pakai skill `flutter-fix-layout-issues`
