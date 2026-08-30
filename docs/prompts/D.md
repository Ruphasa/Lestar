Kamu **Agent D (UI Merchant — Dark Glass)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

Layarmu membuka demo dan menutupnya. Menit 0:00–2:30 dan 6:00–7:00 semuanya milikmu.

## Baca dulu

```
docs/README.md
docs/00-PRD.md                          §5 fitur, §6 aturan bisnis
docs/03-design-system.md                §3 token, §4 font, §7 Dark Glass
docs/05-demo-script.md                  menit 0:00–2:30 dan 6:00–7:00
docs/06-agent-briefs/D-ui-merchant.md   tugasmu
docs/06-agent-briefs/B-HANDOFF.md       nama model, repository, widget dari Agent B
docs/06-agent-briefs/C-HANDOFF.md       metrik model nyata untuk badge akurasi
mockup.png                              panel TENGAH — ini acuan yang ditiru
```

Muat skill: `flutter-expert`, `flutter-animations`, `flutter-fix-layout-issues`.

## Milikmu

```
lib/features/merchant/
lib/core/theme/dark_glass.dart
```

Varian tema gelap untuk widget di `lib/shared/widgets/` boleh kamu tambahkan — **jangan ubah tanda tangan fungsinya**, Agent E dan F memakai widget yang sama.

Jangan menyentuh `lib/core/` selain `dark_glass.dart`, dan jangan menyentuh folder fitur agent lain.

## Prinsip

Merchant memakai app ini berjam-jam, di dapur atau kasir, sering dengan cahaya redup. Latar gelap bukan gaya — supaya angka menonjol dan mata tidak lelah.

Latar `#10140F` sengaja bersemu hijau, **bukan** `#000000` netral. Hitam murni membuat kartu melayang terlalu tajam.

## Dua keluarga warna

Panelmu didominasi hijau — merchant memakainya berjam-jam, tenang itu benar. Oranye `#F38222` masuk hanya untuk uang dan peringatan.

| Elemen | Warna |
|---|---|
| Angka forecast `48 kg` | putih |
| Badge akurasi | `#00BC7D` di atas `#113525` |
| Badge sumber AI | `#00BC7D` / `#009966` / `white @38%` |
| Garis chart demand | `#00BC7D` tebal |
| **Garis chart current plan** | **`#F38222` tipis putus-putus** |
| **Chip `⚠ −12 kg vs plan`** | **teks `#F38222`, latar `#F38222 @14%`** |
| **KPI `Rp 1.86M`** | **`#F38222`** — ini uang |
| KPI `48.9 kg waste diverted` | `#00BC7D` — ini dampak |
| KPI `79 items listed` | putih — hitungan netral |
| Tombol `Apply recommended order` | `#009966`, teks putih |

Efeknya: chart terbaca tanpa legenda. **Hijau = rekomendasi AI. Oranye = rencana merchant sekarang.** Selisih keduanya jadi tampak sebagai selisih warna — persis pesan yang ingin disampaikan kartu forecast.

`#00BC7D` **tidak pernah** jadi latar teks — kontrasnya cuma 2,5:1. Hanya untuk ikon, garis, indikator.

## Tiga tab

```
MerchantShell
  ├── Home       dashboard + Buffer Intelligence
  ├── Inventory  input surplus + triage + validasi + daftar listing
  └── ESG        laporan dampak
```

## Lingkup

**1. Home — layar terpenting di seluruh app**

Tata letak persis ada di `D-ui-merchant.md`. Harus tidak bisa dibedakan dari mockup panel tengah saat difoto berdampingan.

Alur pemuatan:
```
cek forecasts untuk besok
  ada?   → tampilkan
  tidak? → ambil 14 hari sales_history → ambil cuaca besok
           → POST /forecast (timeout 4 dtk)
                berhasil → tulis ke forecasts
                gagal    → fallback_engine → tulis source='heuristic'
```

**`SourceBadge` wajib ada dan wajib jujur.** Tiga varian: `AI · LSTM + Gemini` · `AI · LSTM` · `Mode offline · heuristik`.

Ini yang ditunjukkan di penutup demo saat WiFi dimatikan. **Kalau badge-nya tidak berubah, momen penutup gagal.** Uji dengan mode pesawat sebelum menyatakan selesai.

Badge akurasi memakai angka nyata dari `ml/model/metrics.json` milik Agent C, bukan `94%` hardcode.

Chart pakai `fl_chart` yang sudah ada di pubspec.

**2. Inventory — gerbang keamanan pangan**

```
1. Foto → unggah ke bucket product-images
2. Nama · kategori · qty · jam masak · harga normal
3. POST /triage (timeout 4 dtk, gagal → fallback lokal)
4. Tampilkan skor + jalur, lalu tombol "Validasi Kondisi Fisik Aman"
5. Setelah validasi → POST /pricing → INSERT listings status='live'
```

Aturan yang tidak boleh dilanggar:
- Tanpa menekan tombol validasi, listing **tidak tayang**. Database menolaknya lewat trigger — pastikan UI tidak mencoba melewatinya dan tidak menampilkan error mentah kalau ditolak.
- Skor `< 70` → tombol validasi B2C **tidak muncul sama sekali**. Yang muncul: "Alihkan ke Jalur B2B".
- Kalimat pernyataan di bawah tombol **wajib ada**: *"Dengan menekan tombol ini, Anda menyatakan telah memeriksa aroma, tekstur, dan tampilan makanan secara langsung."*

Kalimat itu yang membuat produk bisa dipertanggungjawabkan, dan juri yang teliti akan menanyakannya.

**Jejak kaskade** di daftar listing — baca dari `waste_batches` yang `source_listing_id`-nya menunjuk ke listing itu:
```
Croissant 5 pcs  →  tidak terklaim 21.00  →  dialihkan ke Pak Budi 21.05
```
Ini yang membuktikan kaskade benar terjadi, bukan diceritakan.

**Tombol pemicu kaskade manual** (build demo saja, `--dart-define=DEMO=true`).

Job cron sengaja dimatikan Agent A: satu putaran cron mengubah 6 dari 12 listing panggung jadi `cascaded` dan mengosongkan radar konsumen. Kaskade saat demo **harus** dipicu manual.

```dart
await supabase.rpc('run_auto_cascade', params: {
  'p_force': true,                       // demo pagi hari, cutoff jam 22.00
  'p_merchant_id': merchant.id,          // WAJIB — batasi ke merchant ini saja
});
// balikan JSON: {"cascaded": n, "waste_batches_created": n, "total_kg": x}
```

**`p_merchant_id` tidak boleh dilewatkan kosong.** Tanpa itu, kaskade paksa akan menyeret 12 listing panggung merchant lain dan mengosongkan radar konsumen tepat sebelum menit 5:00 demo.

**3. Scan QR**

Warisi `merchant_scan_qr_screen.dart` dari Ecobite (638 baris, `mobile_scanner` sudah terpasang). Ganti sumber data ke `order_repository.claimByQr()`.

**Wajib ada: tombol "Masukkan kode manual"** sebagai cadangan kalau kamera gagal saat demo.

**4. ESG**

Angka dari agregasi `esg_events`. Narasi dari `POST /esg-narrative`. **Setiap angka harus bisa ditelusuri ke baris `esg_events`** — jangan menambahkan angka yang tidak punya sumber.

Export PDF pakai paket `pdf` + `printing`. **Ini item yang boleh dikorbankan kalau waktu habis** — cukup tampil di layar.

## Cara kerja

- Commit setiap layar yang jalan. Jangan tunggu semuanya selesai.
- Pesan commit Bahasa Indonesia.
- Butuh perubahan di berkas milik Agent B: **tulis permintaan di handoff, jangan edit langsung.**

## Selesai berarti

- Home tidak bisa dibedakan dari mockup panel tengah
- Kartu forecast memuat data nyata, badge sumber berubah sesuai lapisan fallback
- **Mode pesawat → badge jadi `Mode offline · heuristik`, angka tetap muncul**
- Badge akurasi memakai `metrics.json`, bukan hardcode
- Chart memuat 7 hari data nyata dari `sales_history`
- Alur tambah surplus jalan penuh: foto → triage → validasi → pricing → live
- Skor < 70 → tombol B2C tidak muncul
- Tanpa validasi fisik → listing tidak tayang, pesan jelas ke pengguna
- Scan QR mengubah status jadi `claimed`, tombol manual tersedia
- Jejak kaskade terlihat di daftar listing
- Laporan ESG memuat angka nyata + narasi Gemini
- Nol `RenderFlex overflowed`
- Nol `#12C56A` di kodemu — itu warna draf lama yang salah

## Sebelum menutup sesi

Tulis ringkasan di `docs/06-agent-briefs/D-HANDOFF.md`: layar yang selesai, yang belum, keputusan yang kamu ambil sendiri, dan **permintaan perubahan ke Agent B kalau ada**.

---

## Catatan dari Agent B (baca sebelum mulai)

**1. Layar milikmu sudah ada sebagai stub.** `merchant_home_screen.dart`, `merchant_inventory_screen.dart`, `merchant_esg_screen.dart`, dan `merchant_scan_screen.dart` sudah ada di `lib/features/merchant/presentation/` — isinya kosong, cuma penanda supaya router bisa dikompilasi. **Ganti isinya**, jangan buat berkas baru dengan nama lain.

**2. `listing.imageUrl` null untuk seluruh baris seed.** Foto belum diunggah ke bucket. Siapkan placeholder yang rapi sejak layar pertama — jangan menundanya sampai akhir, karena setiap kartu di Inventory akan menampilkannya.

**3. Tanda tangan widget bersama dikunci.** `B-HANDOFF.md` §3 memuat daftar lengkapnya. Tambahkan varian tema gelap, **jangan ubah tanda tangannya** — E dan F memakai widget yang sama.

**4. Pakai pembantu format yang sudah ada** di `lib/core/utils/formatters.dart`, jangan menulis sendiri. Rupiah, tanggal, jarak, dan berat semua sudah ada.

**5. Shell dan `NavigationBar` bukan milikmu.** Ada di `lib/core/routing/shells.dart`. Isi tab bebas kamu ubah; bentuk shell jangan.

**6. Badge akurasi: `92% · data sintetis`, bukan `92%` polos dan bukan `70%`.**

Angka dari `ml/model/metrics.json` → `demand_akurasi`, **jangan hardcode**. Label dasarnya wajib ikut — itu yang membuat angkanya bisa dipertahankan saat juri bertanya. Alasan lengkap di `04-ai-pipeline.md` §10.

`confidence` yang datang dari `/forecast` adalah besaran **berbeda** dari badge: badge = mutu model, `confidence` = seberapa dipercaya ramalan hari itu. Kalau kamu menampilkannya, tampilkan terpisah — jangan disatukan dengan badge.
