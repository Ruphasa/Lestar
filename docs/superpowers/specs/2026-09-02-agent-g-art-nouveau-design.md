# Agent G - Landing Page dan Deck Botanical Art Nouveau

**Tanggal:** 2 September 2026  
**Status:** Disetujui secara prinsip melalui arahan pengguna "Botanical Art Nouveau"  
**Lingkup:** `landing/`, `deck/`, dan `docs/06-agent-briefs/G-HANDOFF.md`

## Tujuan

Landing page membuat juri memahami Lestar dalam 30 detik, mengunduh APK, dan menemukan akun demo. Deck mendampingi demo langsung selama tujuh menit dengan menjelaskan konteks, arsitektur, pasar, model bisnis, dan roadmap tanpa mengulang layar yang diperagakan di aplikasi.

Kalimat komunikasi utama:

> Setiap kilogram punya jalur nilai: dicegah sebelum menjadi surplus, diselamatkan lewat B2C, lalu dialihkan ke B2B bila tidak layak dikonsumsi.

## Keputusan Implementasi

Landing page dibangun sebagai HTML, CSS, dan JavaScript statis tanpa framework atau dependency runtime. Keputusan ini menjaga halaman ringan, menghilangkan risiko instalasi dependency menjelang demo, dan dapat langsung diterbitkan di Vercel.

Deck dibuat sebagai PowerPoint 16:9 yang dapat diedit, lalu diekspor menjadi PDF. Diagram kaskade, arsitektur, motif botani, dan grafik pasar memakai aset vektor yang konsisten. Landing dan deck berbagi bahasa visual, tetapi bukan satu berkas atau satu sistem layout.

APK release dari `build/app/outputs/flutter-apk/app-release.apk` disalin ke `landing/public/lestar.apk`. Ukuran unduhan ditampilkan dari ukuran berkas aktual, bukan klaim 24 MB dari brief lama.

## Arah Visual

Gaya yang digunakan adalah **Botanical Art Nouveau kontemporer**, bukan reproduksi poster vintage. Karakter Art Nouveau muncul melalui garis sulur yang terus mengalir, bingkai lengkung, komposisi asimetris, daun, dan buah oranye dari logo. Struktur informasi, tipografi, dan interaksi tetap modern.

Elemen khas halaman adalah satu **jalur nilai** berupa sulur vektor. Sulur bermula dari logo infinity di hero, bergerak melewati masalah, lalu bercabang pada diagram kaskade menuju B2C, B2B, dan laporan ESG. Bentuk ini menyatukan cerita dan menggantikan divider dekoratif.

### Palet

| Token | Nilai | Peran |
|---|---:|---|
| `paper` | `#EDE5D8` | bidang hero dan aksen hangat |
| `white` | `#FFFFFF` | permukaan utama |
| `forest` | `#265938` | judul, garis utama, teks penting |
| `emerald-deep` | `#009966` | tombol utama dan angka sistem |
| `emerald` | `#00BC7D` | ikon, node, dan garis; tidak menjadi latar teks |
| `orange` | `#F38222` | urgensi, nilai uang, buah, dan CTA sekunder |
| `orange-text` | `#C2540E` | teks oranye pada latar terang |
| `ink` | `#0A0A0A` | teks utama dan teks pada isian oranye |
| `ink-soft` | `#171717` | teks sekunder pekat |
| `muted` | `#737373` | keterangan yang tetap memenuhi kontras |
| `surface-grey` | `#F5F5F5` | bidang data sekunder |

Isian oranye selalu memakai teks `#0A0A0A`. `#00BC7D` tidak dipakai sebagai latar di belakang teks. Tidak ada warna selain token ini kecuali warna autentik pada tangkapan layar aplikasi.

### Tipografi

- Plus Jakarta Sans untuk judul, angka, CTA, dan label struktur.
- Inter untuk paragraf, sumber, instruksi instalasi, dan catatan.
- Angka memakai tabular figures agar kolom data stabil.
- Body landing minimal 16 px dengan line-height 1,5-1,7.
- Judul deck minimal 35 pt; judul utama minimal 50 pt; body minimal 16 pt.
- Tidak memakai font display historis atau ornamental karena akan mengurangi keterbacaan dan terasa seperti tema kostum.

## Kontrak Anti-AI-Slop

1. Tidak ada hero generik berupa mockup ponsel mengambang dengan gradient blob.
2. Tidak ada grid kartu bundar untuk setiap bagian. Kartu hanya dipakai ketika benar-benar mewadahi satu entitas, yaitu tiga aktor.
3. Tidak ada badge atau pill dekoratif. Pill hanya boleh muncul untuk diskon, status sumber AI, atau informasi status yang memang berbentuk ringkas.
4. Tidak ada divider `---`, garis putus-putus dekoratif, atau nomor `01/02/03` yang tidak membawa arti urutan.
5. Tidak ada emoji sebagai ikon dan tidak ada ikon yang diletakkan dalam lingkaran sekadar hiasan.
6. Tidak ada gradient mencolok, glassmorphism, glow acak, atau bayangan berbeda-beda.
7. Tidak ada kumpulan ikon generik sebagai pusat ilustrasi. Cerita utama disampaikan oleh jalur sulur khusus Lestar dan tipografi.
8. Tidak ada kalimat pemasaran generik seperti "revolutionizing sustainability" atau klaim tanpa angka proposal.
9. Satu halaman hanya memiliki satu CTA utama yang paling dominan: `Unduh APK`.
10. Ornamen Art Nouveau tidak boleh melintasi teks, diagram, angka, atau area sentuh.

## Sistem Ikon

Phosphor Outline menjadi satu-satunya keluarga ikon utilitas. Bobot garis konsisten dan setiap ikon aksi disertai label teks. Ikon yang digunakan dibatasi pada kebutuhan nyata: `DownloadSimple`, `ArrowRight`, `MapPin`, `Storefront`, `ShoppingBag`, `Truck`, `ChartLine`, `ShieldCheck`, dan `WifiSlash`.

Ikon utilitas tidak digunakan sebagai ilustrasi besar. Node kaskade dan ornamen utama memakai SVG khusus yang mengambil bentuk daun, buah, aliran, dan percabangan dari logo Lestar. Favicon memakai glyph logo transparan, bukan ikon daun stok.

## Landing Page

### Header

Header ringan dan transparan di atas hero, berisi wordmark Lestar, tautan `Cara kerja`, `Dampak`, dan tombol `Unduh APK`. Pada layar kecil, tautan sekunder disembunyikan dan CTA tetap terlihat. Semua target sentuh minimal 44 x 44 px dengan focus ring 3 px.

### Hero

Hero memakai bidang paper hangat dengan komposisi dua kolom asimetris. Teks `Lestar - Setiap kilogram punya jalur nilai` menjadi tesis halaman. Logo infinity hadir besar sebagai sumber sulur, bukan sebagai kotak gambar tempelan. CTA unduhan dominan memakai emerald-deep; `Lihat cara kerjanya` menjadi tautan teks dengan panah.

Hero tidak memakai foto makanan atau mockup ponsel. Ini membuat logo dan gagasan kaskade menjadi identitas yang langsung diingat.

### Masalah

Empat angka ditampilkan sebagai komposisi editorial, bukan empat kartu identik:

- 14,73 juta ton sampah makanan Indonesia per tahun.
- Rp213-551 triliun kerugian ekonomi per tahun.
- 7,29% kontribusi emisi gas rumah kaca.
- 40,76% porsi sisa makanan dari total sampah nasional.

Angka memiliki label langsung dan sumber manusia-terbaca. Susunan desktop membentuk ritme dua besar dan dua kecil; mobile menjadi satu alur vertikal tanpa scroll horizontal.

### Kaskade

Bagian terpenting halaman memakai diagram SVG yang dapat dibaca sebagai teks berurutan:

`Surplus -> Triage AI -> Validasi Fisik -> Flash Sale B2C / Limbah Organik B2B -> Laporan ESG`

Validasi fisik ditampilkan sebagai gerbang nyata, bukan node AI. B2C memakai aksen oranye untuk nilai komersial; B2B dan ESG memakai hijau. Pada mobile, diagram berubah menjadi alur vertikal dan tidak memaksa pengguna melakukan zoom atau geser horizontal.

### Tiga Aktor

Tiga tangkapan layar aplikasi nyata ditampilkan berdampingan pada desktop dan bertumpuk pada mobile. Masing-masing memiliki satu kalimat yang menjelaskan konteks pemakaian, bukan daftar fitur:

- Konsumen: ringan dan menyenangkan untuk berburu penawaran.
- Merchant: kokpit data untuk keputusan operasional.
- Pengepul: terbaca di luar ruangan dan dapat digunakan dengan satu tangan.

Tangkapan layar mempertahankan rasio asli, tidak dipotong ke bentuk ornamental, dan memiliki dimensi eksplisit untuk mencegah layout shift. `mockup.png` tidak boleh dipakai sebagai pengganti tiga tangkapan layar nyata.

### Buffer Intelligence

Bagian ini memakai satu komposisi angka dan garis prediksi sederhana, bukan dashboard tiruan. Copy menjelaskan bahwa LSTM memprediksi permintaan besok dan jalur keluar surplus membuat merchant berani memproduksi lebih banyak. Asal setiap prediksi dicatat pada `forecasts.source`.

### Dampak

Target 12 bulan ditampilkan sebagai satu baris progres editorial pada desktop dan daftar pada mobile:

`200 merchant / 3.000 transaksi per bulan / 3.000 kg limbah tersalurkan / 4.500 kg CO2eq per bulan`

Nilai dipertahankan persis dari tabel proposal. Ketidaksesuaian internal antara target CO2eq dan faktor `0,25 kg CO2eq/kg` dicatat di handoff dan tidak diperbaiki diam-diam.

### Unduh

CTA akhir mengulang `Unduh APK`, menampilkan ukuran berkas aktual, serta tiga langkah pemasangan Android:

1. Unduh APK.
2. Izinkan instalasi dari sumber ini saat Android meminta.
3. Buka Lestar dan pilih salah satu akun demo.

Akun yang ditampilkan:

- `merchant@lestar.id`
- `amira@lestar.id`
- `budi@lestar.id`
- Kata sandi bersama: `lestar2026`

## Deck

Deck menggunakan kanvas 16:9, margin kiri dan kanan konsisten, serta siluet slide yang bervariasi tanpa berubah menjadi kumpulan panel UI. Motif sulur menjadi pengikat kecil di tepi kanvas, bukan bingkai penuh pada semua slide.

| # | Klaim slide | Komposisi |
|---:|---|---|
| 1 | Setiap kilogram punya jalur nilai | Judul minimal, logo infinity besar, `Tim Lestar - 2 September 2026` |
| 2 | Food waste Indonesia adalah kerugian ekonomi berskala nasional | Tiga angka utama; sumber ringkas di footer |
| 3 | Solusi yang ada berhenti sebelum seluruh nilai dipulihkan | Perbandingan datar: flash sale, donasi, limbah, pricing, ESG, forecasting |
| 4 | Lestar mencegah kerugian lalu memulihkan sisa nilainya | Diagram kaskade dua tahap |
| 5 | Sekarang lihat alurnya bekerja | Penanda `DEMO` full-bleed forest tanpa detail app |
| 6 | Empat komponen menjaga jalur data tetap sederhana | Flutter APK, Supabase, FastAPI/Railway, landing Vercel |
| 7 | Sistem tetap memberi angka dan selalu mengaku dari mana asalnya | LSTM + Gemini -> LSTM saja -> heuristik; `forecasts.source` |
| 8 | Tiga dunia kerja membutuhkan tiga antarmuka berbeda | Tiga tangkapan layar nyata dan argumen aksesibilitas |
| 9 | Tiga arus pendapatan membiayai ekosistem | Komisi B2C, langganan B2B, green fee Rp1.000 |
| 10 | Pasar awal cukup fokus untuk dimenangkan dan cukup besar untuk tumbuh | Bar horizontal TAM Rp960 M/tahun, SAM Rp48 M/tahun, SOM Rp480 jt/tahun |
| 11 | Dua belas bulan membawa Lestar dari fondasi ke scaling | Fase 0 sampai Fase 4 sesuai proposal |
| 12 | Dimulai dari Malang, dikembangkan menuju skala nasional | Penutup dengan logo dan jalur sulur kembali ke bentuk infinity |

Slide 8 menggunakan kutipan berikut sebagai inti, dengan copy dipadatkan agar tetap terbaca:

> Lestar tidak memaksakan satu design system ke tiga aktor yang hidup di dunia berbeda. Konsumen mendapat pengalaman ringan dan menyenangkan. Merchant mendapat kokpit data. Pengepul mendapat antarmuka yang bisa dibaca di bawah terik matahari dengan satu tangan.

Slide 7 tidak menyebut fallback sebagai sekadar toleransi error. Slide tersebut menegaskan ketahanan dan kejujuran sistem. Setiap sumber angka dicatat sebagai `lstm_gemini`, `lstm_only`, atau `heuristic`.

Setiap klaim nontrivial dan aset eksternal memiliki blok `[Sources]` di speaker notes. Deck tidak memakai foto makanan karena tidak diperlukan untuk pekerjaan komunikasinya.

## Motion

Motion dibatasi pada dua momen:

1. Sulur hero tergambar sekali saat halaman masuk, menggunakan transform dan opacity selama maksimal 400 ms.
2. Node kaskade muncul mengikuti arah alur ketika pertama kali masuk viewport, 30-50 ms antar-node.

Hover dan pressed state berlangsung 150-250 ms. Seluruh motion berhenti atau disederhanakan ketika `prefers-reduced-motion: reduce` aktif. Konten dapat dipahami sepenuhnya tanpa animasi.

## Responsivitas, Aksesibilitas, dan Performa

- Mobile-first pada 375 px, lalu 768 px, 1024 px, dan 1440 px.
- Tidak ada horizontal scroll pada 320 px ke atas.
- Heading berurutan dan hanya satu `h1`.
- Tersedia skip link menuju konten utama.
- Fokus keyboard terlihat pada semua tautan dan tombol.
- Alt text deskriptif untuk logo dan tangkapan layar; SVG dekoratif disembunyikan dari screen reader.
- Warna tidak menjadi satu-satunya pembeda cabang alur; setiap cabang memiliki label dan bentuk node berbeda.
- Font lokal diprioritaskan untuk menghindari kegagalan jaringan dan layout shift.
- Gambar di bawah fold memakai lazy loading dan dimensi eksplisit.
- JavaScript tidak diperlukan untuk membaca konten atau mengunduh APK.
- Halaman tetap berguna bila motion atau JavaScript tidak tersedia.

## Penanganan Kekurangan Aset dan Kegagalan

Landing dan deck tidak boleh menyamarkan aset yang belum ada. Jika tiga tangkapan layar nyata belum tersedia, build dapat dilanjutkan untuk bagian lain tetapi deck final dan definisi selesai tetap dinyatakan belum lulus. Tidak ada mockup AI atau `mockup.png` sebagai pengganti diam-diam.

Jika APK sumber tidak ditemukan, tombol unduh tidak boleh mengarah ke berkas kosong dan proses build harus gagal. Jika ekspor PDF tidak tersedia, PPTX tetap disimpan tetapi deliverable tidak dinyatakan selesai sampai PDF berhasil dibuat dan dirender.

Jika Vercel belum terautentikasi, halaman diuji lokal dan status deploy dicatat sebagai blocker tanpa meminta token manual.

## Verifikasi

1. Validasi HTML semantik, tautan jangkar, target unduhan, dan kredensial demo.
2. Uji viewport minimal 320, 375, 768, 1024, dan 1440 px tanpa overflow.
3. Uji keyboard, focus ring, heading hierarchy, alt text, dan reduced motion.
4. Audit pasangan warna terhadap rasio kontras dari design system Lestar.
5. Pastikan seluruh angka cocok dengan proposal menggunakan pencarian teks otomatis.
6. Render seluruh slide PPTX dan PDF ke PNG, periksa satu per satu pada ukuran penuh, lalu jalankan pemeriksaan overflow.
7. Pastikan slide 8 menggunakan tiga tangkapan layar aplikasi nyata.
8. Uji `landing/public/lestar.apk` dapat diunduh dan checksum-nya sama dengan APK sumber.
9. Buka URL deploy pada ukuran mobile dan desktop serta uji respons HTTP APK.

## Batas Lingkup

Agent G hanya mengubah `landing/`, `deck/`, spesifikasi ini, rencana implementasi Agent G, dan `docs/06-agent-briefs/G-HANDOFF.md`. Tidak ada perubahan pada `lib/`, `api/`, `ml/`, atau `supabase/`.
