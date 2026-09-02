# Agent G — Web Deck Astro + Bun

**Tanggal:** 2 September 2026  
**Status:** Disetujui secara prinsip oleh pengguna  
**Menggantikan:** bagian deck PPTX pada `2026-09-02-agent-g-art-nouveau-design.md`  
**Tidak mengubah:** landing statis yang sudah terdeploy dan lolos audit

## Tujuan

Deck Lestar menjadi presentasi web-native 12 slide yang mendampingi demo langsung selama tujuh menit. Deck harus terasa seperti satu narasi yang mengalir, bukan halaman pemasaran kedua dan bukan kumpulan panel aplikasi. Output utama adalah situs Astro statis; output arsip adalah PDF 12 halaman. PPTX tidak lagi menjadi deliverable.

Keberhasilan berarti:

- presenter dapat berpindah slide cepat lewat keyboard, tombol, atau swipe;
- seluruh isi tetap terbaca sebagai dokumen vertikal bila JavaScript gagal;
- PDF memiliki 12 halaman dengan komposisi yang setara dengan layar;
- tiga screenshot aplikasi asli menjadi pusat slide 8;
- seluruh angka dan klaim tetap identik dengan proposal;
- visual jelas dari jarak presentasi, tenang, dan memakai negative space secara sengaja.

## Keputusan Arsitektur

`deck/` menjadi project Astro statis mandiri yang dikelola dengan Bun. Astro dipakai untuk komposisi halaman, komponen slide, build statis, dan asset pipeline. Interaksi presentasi memakai TypeScript/DOM kecil tanpa framework UI tambahan.

Struktur target:

```text
deck/
  astro.config.mjs
  package.json
  bun.lock
  public/
    assets/
      logo-full.png
      logo-glyph.svg
      value-route.svg
      screenshots/
        consumer.png
        merchant.png
        partner.png
      fonts/
        PlusJakartaSans-wght.ttf
        Inter-opsz-wght.ttf
  src/
    components/
      DeckShell.astro
      SlideFrame.astro
      VineOrnament.astro
      DeckControls.astro
    data/
      slides.ts
    pages/
      index.astro
    scripts/
      deck-controller.ts
    styles/
      deck.css
      print.css
  tests/
    verify.ts
  scripts/
    export-pdf.ts
  Lestar-KMIPN-VIII.pdf
```

`slides.ts` adalah sumber narasi tunggal. Ia mengekspor tepat 12 slide dengan nomor, jenis layout, judul, visible copy, data, dan sumber. Komponen layout tidak menyimpan angka proposal. Ini membuat copy dapat diverifikasi tanpa merender browser.

Astro menghasilkan HTML statis. Vercel tidak memerlukan adapter server untuk deck ini. Bun dipakai untuk instalasi, script, build, test, dan ekspor PDF. Versi dependency dikunci lewat `bun.lock`; tidak ada SSR, React, Tailwind, database, atau API baru.

## Model Interaksi

Tanpa JavaScript, setiap slide adalah `<section>` berurutan dalam satu halaman vertikal. Dengan JavaScript aktif, `DeckShell` mengubahnya menjadi mode presentasi:

- `ArrowRight`, `ArrowDown`, `PageDown`, dan `Space`: slide berikutnya;
- `ArrowLeft`, `ArrowUp`, dan `PageUp`: slide sebelumnya;
- `Home` dan `End`: slide pertama dan terakhir;
- tombol Previous/Next berlabel teks untuk pointer dan touch;
- swipe horizontal dengan threshold yang mencegah perpindahan tidak sengaja;
- URL hash `#slide-7` mengikuti posisi agar slide dapat dibagikan dan dipulihkan;
- indikator `7 / 12` menunjukkan posisi, bukan badge dekoratif;
- tombol fullscreen memakai glyph kustom sederhana dan label aksesibel.

Kontrol tidak menutupi isi dan menghilang saat print. Fokus keyboard selalu terlihat. Perubahan slide diumumkan secara ringkas melalui live region. `prefers-reduced-motion: reduce` mematikan transisi dan langsung menampilkan state akhir.

## Arah Visual

Tema tetap **Botanical Art Nouveau kontemporer**, dengan negative space sebagai elemen dominan. Target visual bukan poster vintage yang ramai. Setiap slide memakai satu gerak kurva atau satu massa visual utama; ornamen tidak diulang di keempat sudut.

Prinsip komposisi:

- 60–70% kanvas dibiarkan sebagai bidang tenang atau ruang baca;
- satu klaim dominan per slide;
- maksimal satu motif sulur utama dan dua aksen buah/daun kecil per slide;
- sulur berfungsi sebagai alur, connector, baseline, atau penanda arah—bukan bingkai;
- logo infinity penuh hanya muncul pada slide 1 dan 12;
- tidak ada kartu generik, badge, pill, gradient blob, glassmorphism, emoji, atau library ikon;
- tidak ada divider `---`, accent stripe, maupun garis bawah judul dekoratif;
- screenshot mempertahankan rasio asli, tanpa phone mockup dan tanpa crop ornamental;
- isian oranye selalu memakai teks `#0A0A0A`.

Palet dan font mengikuti landing: paper `#EDE5D8`, white `#FFFFFF`, forest `#265938`, emerald deep `#009966`, emerald `#00BC7D`, orange `#F38222`, orange text `#C2540E`, ink `#0A0A0A`, ink soft `#171717`, muted `#737373`, dan surface grey `#F5F5F5`; Plus Jakarta Sans untuk display dan Inter untuk body.

Ukuran minimum pada viewport presentasi 16:9: judul utama setara 64 px, judul slide 44 px, subjudul 26 px, body 18 px, dan sumber 13 px. Copy dipendekkan sebelum font dikecilkan.

## Urutan dan Komposisi Slide

1. **Setiap kilogram punya jalur nilai** — judul minimal di kiri, logo infinity besar di kanan, satu sulur tipis menghubungkan keduanya.
2. **Kerugian nasional** — tiga angka utama pada satu baseline editorial; sumber kecil dan terbaca.
3. **Nilai berhenti terlalu cepat** — enam baris perbandingan datar; tidak berubah menjadi tabel penuh kotak.
4. **Dua tahap pemulihan** — diagram kaskade dengan gerbang Validasi Fisik yang berbeda bentuk.
5. **DEMO** — bidang forest penuh, satu kata dan satu instruksi untuk berpindah ke HP.
6. **Empat komponen, satu jalur data** — arsitektur datar Flutter, Supabase, FastAPI/Railway, dan landing Vercel.
7. **Sistem selalu mengaku dari mana angkanya berasal** — urutan `lstm_gemini`, `lstm_only`, `heuristic`, serta `forecasts.source` sebagai bukti kejujuran.
8. **Tiga dunia kerja, tiga antarmuka** — slide terkuat; screenshot asli mengisi minimal 65% kanvas dan copy maksimal 42 kata.
9. **Tiga arus pendapatan** — komisi B2C, langganan B2B, dan green fee Rp1.000 sebagai satu sungai bercabang.
10. **Pasar awal yang fokus** — TAM Rp960 miliar/tahun, SAM Rp48 miliar/tahun, SOM Rp480 juta/tahun dengan skala eksplisit.
11. **Dua belas bulan menuju scaling** — lima fase 0–4 mengikuti proposal pada satu sulur timeline.
12. **Dimulai dari Malang** — kalimat penutup dan sulur kembali menjadi infinity.

Slide 5 tetap menjadi batas demo; slide tidak mengulang interaksi yang sedang diperagakan di aplikasi. Slide 8 memakai capture consumer, merchant, dan partner yang hash-nya identik dengan landing.

## Motion dan State

Perpindahan slide memakai opacity dan translasi pendek 180–240 ms. Satu animasi sulur boleh berjalan pada slide 1 dan node kaskade boleh muncul berurutan pada slide 4; seluruh sequence selesai maksimal 400 ms. Tidak ada parallax, autoplay, scroll-jacking, atau animasi terus-menerus.

Mode presentasi memiliki state tunggal `activeIndex`. Hash navigation, keyboard, tombol, dan swipe semuanya memanggil fungsi perpindahan yang sama agar tidak ada state yang bersaing. Input diabaikan saat target sama atau perpindahan masih dalam frame yang sama.

## PDF dan Print

`print.css` mengubah setiap `.slide` menjadi satu halaman landscape 16:9, menyembunyikan kontrol, menghapus transisi, dan memaksa warna background tercetak. Script `export-pdf.ts` menjalankan build, membuka output statis dengan browser headless, lalu mengekspor tepat 12 halaman ke `deck/Lestar-KMIPN-VIII.pdf`.

PDF adalah deliverable arsip, bukan screenshot panjang. Setiap halaman harus mempertahankan margin aman, sumber, screenshot, dan urutan slide. Font lokal dimuat sebelum ekspor; proses gagal bila font, screenshot, atau halaman tidak lengkap.

## Aksesibilitas dan Responsivitas

- Semantik memakai satu `h1`, judul `h2` per slide, dan urutan DOM yang sama dengan narasi.
- Kontrol keyboard tidak menangkap shortcut ketika fokus berada pada elemen interaktif yang membutuhkan tombol tersebut.
- Target sentuh minimal 44 × 44 px dan focus ring minimal 3 px.
- Warna bukan satu-satunya pembeda jalur; label dan bentuk node tetap berbeda.
- Viewport utama: 320 × 568, 375 × 812, 768 × 1024, 1024 × 768, 1280 × 720, dan 1440 × 900.
- Pada layar sempit, presentasi boleh menjadi scroll vertikal yang nyaman daripada memaksa komposisi desktop mengecil.
- Tidak ada overflow horizontal, teks tertutup kontrol, atau ornament melintasi isi.

## Verifikasi

1. `bun run check` memverifikasi Astro/TypeScript dan build statis.
2. Test data memastikan tepat 12 slide, nomor berurutan, semua angka proposal hadir, serta screenshot deck identik dengan landing.
3. Browser QA memeriksa keyboard, hash, touch/swipe, focus ring, reduced motion, no-JS, dan overflow pada seluruh viewport target.
4. Setiap slide dirender pada 1280 × 720 dan diperiksa satu per satu; contact sheet hanya menilai alur keseluruhan.
5. PDF diverifikasi memiliki 12 halaman, ukuran wajar, font termuat, dan visual setara dengan render web.
6. Detector/audit UI dijalankan sekali pada state final; P0/P1 wajib diperbaiki sebelum deploy.
7. Preview Vercel dibuka pada mobile dan desktop; URL serta hasil aktual dicatat di `G-HANDOFF.md`.

## Penanganan Kegagalan

- Bila Bun tidak tersedia, implementasi berhenti sebelum scaffold; package manager tidak diganti diam-diam.
- Bila screenshot asli hilang atau hash berbeda, build/test gagal dan slide 8 tidak diberi mockup pengganti.
- Bila JavaScript gagal, semua slide tetap ada dalam alur vertikal.
- Bila ekspor PDF gagal, web deck tetap dapat diuji tetapi deliverable belum dinyatakan selesai.
- Bila deployment belum terautentikasi, QA lokal tetap diselesaikan dan hanya gerbang deploy yang dicatat sebagai blocker.

## Batas Lingkup

- Landing statis, deployment landing, dan APK tidak dimigrasikan atau diubah.
- Tidak membuat PPTX.
- Tidak menyentuh `lib/`, `api/`, `ml/`, atau `supabase/`.
- Perubahan terbatas pada `deck/`, spec/plan Agent G, dan bagian deck pada `docs/06-agent-briefs/G-HANDOFF.md`.

## Referensi Teknis

- Astro, “Use Bun with Astro”: https://docs.astro.build/en/recipes/bun/
- Astro, “Deploy your Astro Site to Vercel”: https://docs.astro.build/en/guides/deploy/vercel/
- Bun, “Build an app with Astro and Bun”: https://bun.sh/guides/ecosystem/astro
