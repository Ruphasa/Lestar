Kamu **Agent F (UI Pengepul — Plain)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

**Layarmu adalah puncak demo.** Menit 5:00–6:00, saat presenter berhenti dan menjelaskan kenapa antarmuka ini sengaja dibuat berbeda. Ini pembeda terkuat produk di depan juri, dan lingkupmu paling kecil — jadi kerjakan dengan teliti.

## Baca dulu

```
docs/README.md
docs/00-PRD.md                          §3.3 aktor pengepul, §6 aturan bisnis
docs/03-design-system.md                §3 token, §4 font, §8 Plain
docs/05-demo-script.md                  menit 5:00–6:00
docs/06-agent-briefs/F-ui-partner.md    tugasmu
docs/06-agent-briefs/A-HANDOFF.md       tanda tangan RPC nearby_waste
docs/06-agent-briefs/B-HANDOFF.md       nama model, repository, widget
mockup.png                              panel KANAN — acuan yang ditiru
```

Muat skill: `flutter-expert`, `flutter-fix-layout-issues`.

## Milikmu

```
lib/features/partner/
lib/core/theme/plain.dart
```

## Prinsip — baca ini dua kali sebelum menulis kode

**Ini bukan versi "belum jadi" dari dua UI lain. Ini keputusan desain yang disengaja.**

Pak Budi berusia 52 tahun. HP-nya entry-level. Dia membaca layar ini di luar ruangan, di bawah matahari, sambil membawa ember, kadang bersarung tangan, kadang sambil menyetir motor.

Glassmorphism di tangannya bukan keindahan — itu penghalang. Blur menurunkan kontras. Transparansi membuat teks bertabrakan dengan latar. Radius besar dan bayangan halus tidak terlihat di layar murah.

Yang dia butuhkan: **kontras maksimum, tipografi raksasa, satu tombol.**

**Kalau kamu tergoda menambahkan gradasi, bayangan halus, atau kartu melayang di sini — jangan.** Setiap efek yang kamu tambahkan menghapus alasan keberadaan UI ini.

## Warna

```dart
bg             #FFFFFF        // 51,9% piksel panel mockup
bgAlt          #F5F5F5
textPrimary    #0A0A0A        // 19:1
textSecondary  #737373
textTertiary   #A1A1A1
bigNumber      #009966        // angka 25 KG
buttonFill     #009966        // BUKAN #00BC7D — lihat catatan
buttonText     #FFFFFF
accentIcon     #00BC7D        // ikon, garis — tidak pernah latar teks
urgent         #F38222        // HANYA "SEGERA DIJEMPUT" dan sisa waktu

// Efek: NOL
// tanpa BackdropFilter, tanpa gradient, tanpa BoxShadow
// (kecuali glow tombol utama), tanpa opacity di teks
```

**Jangan pakai `#00BC7D` sebagai isian tombol.** Mockup memakainya, tapi teks putih di atasnya cuma **2,5:1** — gagal WCAG bahkan untuk teks besar. Isian tombol memakai `#009966` (**3,65:1**, lolos AA teks besar). Bedanya nyaris tak terlihat di layar, tapi nyata di bawah matahari — persis konteks pemakaian Pak Budi.

**Soal oranye:** panelmu tetap hijau. Pengepul bukan sedang berbelanja — dia sedang bekerja, dan tenang itu benar. **Tombol JEMPUT SEKARANG tetap hijau.**

## Aturan keras

| Aturan | Alasan |
|---|---|
| **Satu layar, satu aksi utama** | Dipakai sambil membawa barang atau menyetir |
| Tombol utama tinggi **minimal 120 dp** | Ditekan tanpa melihat, dengan sarung tangan |
| Angka utama **minimal 72 sp** | Terbaca di bawah matahari, mata 40+ |
| Semua label **HURUF BESAR** | Terbaca sekilas |
| **Tanpa istilah Inggris** | "JEMPUT SEKARANG", bukan "Pick Up Now" |
| Tanpa scroll horizontal | Gestur rumit gagal dengan tangan kotor |
| Tanpa modal, tanpa bottom sheet | Gestur tutup tidak jelas |
| Maksimal **3 item** bottom nav | Target sentuh besar |
| **Tanpa animasi masuk** | Animasi memperlambat pemahaman |

Satu-satunya bayangan yang diizinkan: glow emerald di bawah tombol utama — penanda bahwa elemen ini bisa ditekan.

## Tiga tab

```
PartnerShell
  ├── BERANDA     limbah terdekat + tombol jemput
  ├── RIWAYAT     penjemputan selesai
  └── LANGGANAN   status berlangganan
```

## Lingkup

**1. BERANDA — puncak demo**

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

Sumber data — RPC dari Agent A. Tanda tangan persis, perhatikan awalan `p_`:
```dart
final rows = await supabase.rpc('nearby_waste', params: {
  'p_lat': partner.baseLat,
  'p_lng': partner.baseLng,
  'p_radius_km': partner.serviceRadiusKm,
});
```
Kembaliannya **sudah termasuk `store_name` merchant asal** dan `jarak_km`, terurut menaik. Tidak perlu query kedua untuk nama toko — kamu butuh itu di layar "SEDANG MENUJU".

Saring lagi ke `waste_preference` partner (`wet` / `dry`).

**Tampilkan jarak yang terdekat, dan jumlahkan seluruh beratnya jadi satu angka besar.** Itulah `25 KG` di mockup. **Jangan tampilkan daftar.**

Realtime dipakai untuk memicu pemuatan ulang RPC saat batch baru masuk, bukan untuk menghitung jarak sendiri di Dart.

Tekan JEMPUT → `status='matched'`, `matched_partner_id` terisi → merchant dapat notifikasi realtime.

Setelah ditekan, layar jadi mode perjalanan:
```
      SEDANG MENUJU

    Verde Kitchen
    Jl. Soekarno Hatta 12

      1,2 KM

  [ BUKA PETA ]        ← outline
  [ SUDAH SAMPAI ]     ← tombol utama
```
**SUDAH SAMPAI** → `picked_up` → tombol jadi **SELESAI** → `completed` → `esg_events` tertulis.

**2. Kalau tidak ada limbah**

Jangan tampilkan daftar kosong.
```
        BELUM ADA
        SAMPAH HARI INI

     Kami kabari kalau ada

   [ LIHAT PETA SEKITAR ]     ← outline
```

**3. Peta sekitar**

`flutter_map` + OSM. **Pin besar, label berat langsung di atas pin** (`25 KG`), bukan di popup. Saturasi lebih rendah dari peta konsumen, tanpa kartu melayang.

Ketuk pin → langsung ke BERANDA untuk batch itu. Tanpa perantara.

**4. RIWAYAT**

Kartu besar, satu per baris. Di atasnya tiga `StatTile` polos: total kg bulan ini · jumlah penjemputan · perkiraan hemat biaya.

**5. LANGGANAN**

Warisi `partner_subscription_screen.dart` dari Ecobite (189 baris), **sederhanakan drastis** mengikuti aturan di atas. Status + tanggal berakhir + satu tombol perpanjang. Pembayaran simulasi.

**Ini item pertama yang dikorbankan kalau waktu habis.** Kalau terpaksa: cukup tampilkan status berlangganan tanpa alur pembayaran.

## Cara kerja

- Commit setiap layar yang jalan.
- Pesan commit Bahasa Indonesia.
- Butuh perubahan di berkas Agent B: tulis permintaan di handoff, jangan edit langsung.

## Selesai berarti

- BERANDA tidak bisa dibedakan dari mockup panel kanan
- **Angka berat terbaca dari jarak 1,5 meter** — uji langsung, jangan diperkirakan
- **Kontras diverifikasi dengan alat ukur:** teks isi ≥ 7:1, teks besar ≥ 3:1
- Tombol utama tinggi ≥ 120 dp
- **Nol efek kaca, nol gradasi, nol bayangan** kecuali glow tombol
- Semua teks Bahasa Indonesia, **nol istilah Inggris**
- Batch baru muncul realtime saat merchant melakukan kaskade
- Alur jemput jalan penuh: `available` → `matched` → `picked_up` → `completed`
- Merchant menerima notifikasi saat partner menekan JEMPUT
- `esg_events` tertulis saat `completed`
- Nol `RenderFlex overflowed`

## Sebelum menutup sesi

Tulis ringkasan di `docs/06-agent-briefs/F-HANDOFF.md`: layar yang selesai, yang belum, keputusan yang kamu ambil sendiri, dan permintaan perubahan ke Agent B kalau ada.

---

## Catatan dari Agent B (baca sebelum mulai)

**1. Layar milikmu sudah ada sebagai stub.** `partner_home_screen.dart`, `partner_riwayat_screen.dart`, `partner_langganan_screen.dart` sudah ada di `lib/features/partner/presentation/` — isinya kosong. **Ganti isinya**, jangan buat berkas baru.

**2. `flutter_map` versi 8, bukan 7.** API berubah: `MapOptions(center:, zoom:)` jadi `MapOptions(initialCenter:, initialZoom:)`. `LestarMap` sudah memakai v8.

**3. Model `partner_subscriptions` belum ada.** Agent B sengaja melewatkannya karena layar langganan ada di urutan pertama daftar korban. **Kalau kamu jadi membangun layar LANGGANAN, minta modelnya dulu** — Agent B memperkirakan sepuluh menit. Kalau waktu mepet, cukup tampilkan status berlangganan dari `partners.subscription_expiry` tanpa alur pembayaran.

**4. Tanda tangan widget bersama dikunci.** `B-HANDOFF.md` §3.

**5. Shell dan `NavigationBar` bukan milikmu.** Ada di `lib/core/routing/shells.dart`. Bentuknya jangan diubah, isinya bebas.

**6. Keputusanmu tidak memakai `BackdropFilter` sudah tepat** — Agent B mencatat blur adalah hal yang paling mungkin lambat di HP entry-level seperti milik Pak Budi.
