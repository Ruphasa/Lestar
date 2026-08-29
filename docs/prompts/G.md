Kamu **Agent G (Landing Page & Deck)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

Kamu jalur bebas. Tidak bergantung pada siapa pun dan tidak memblokir siapa pun. Satu-satunya yang kamu tunggu: tangkapan layar app dari D/E/F untuk slide 8 deck.

## Baca dulu

```
docs/README.md
docs/00-PRD.md                          apa produknya dan untuk siapa
docs/03-design-system.md                §2 sumber palet, §3 token, §4 font, §5 logo
docs/05-demo-script.md                  deck harus selaras dengan alur demo
docs/06-agent-briefs/G-web-deck.md      tugasmu
LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md    sumber SELURUH angka
```

## Milikmu

```
landing/
deck/
```

Jangan menyentuh `lib/`, `api/`, `ml/`, `supabase/`.

## Palet dan font

Dua keluarga warna, dari logo:

```
HIJAU — sistem, keberlanjutan
  #265938  forest       judul, teks penting (8,1:1)
  #009966  emerald-600  tombol, angka besar
  #00BC7D  emerald-500  aksen, ikon, garis

ORANYE — selera, urgensi, uang
  #F38222  orange       CTA, badge diskon, angka dampak
  #C2540E  orangeText   teks oranye di latar terang (4,6:1)

NETRAL  #0A0A0A · #171717 · #737373 · #A1A1A1 · #F5F5F5   (Tailwind v4)
```

Font: **Plus Jakarta Sans** (display) + **Inter** (body), keduanya di Google Fonts.

Seluruh netral cocok dengan token Tailwind v4 — kalau memakai Tailwind, pakai `neutral-*` apa adanya.

**Aturan keras:** isian oranye selalu dengan teks gelap `#0A0A0A`, tidak pernah putih.

Logo `assets/logo.png` bisa dipakai apa adanya di landing page — latar krem `#EDE5D8` justru menyatu dengan hero yang hangat. Untuk favicon dan header, buat varian glyph transparan.

## Bagian 1 — Landing Page

**Tujuan:** juri membuka satu link, paham produknya dalam 30 detik, bisa mengunduh APK.

**Stack:** Next.js statis, deploy Vercel. Boleh HTML + Tailwind murni kalau lebih cepat — tidak ada yang menilai kodenya.

**Struktur:**
```
1. HERO
   Lestar — Setiap kilogram punya jalur nilai
   [ Unduh APK ]  [ Lihat cara kerjanya ]

2. MASALAH
   14,73 juta ton      sampah makanan Indonesia per tahun
   Rp 213–551 triliun  kerugian ekonomi per tahun
   7,29%               kontribusi emisi gas rumah kaca
   40,76%              porsi sisa makanan dari total sampah nasional
   (UNEP Food Waste Index 2024, KLHK 2025)

3. KASKADE — diagram alur, bagian terpenting halaman ini
   Surplus → Triage AI → Validasi Fisik → Flash Sale B2C
                                        → Limbah Organik B2B
                                        → Laporan ESG

4. TIGA AKTOR — tiga kartu, tangkapan layar app masing-masing
   Tunjukkan bahwa UI-nya memang berbeda. Ini pembeda utama.

5. BUFFER INTELLIGENCE
   LSTM memprediksi permintaan besok. Merchant berani produksi lebih
   banyak karena setiap surplus punya jalur keluar.

6. DAMPAK
   Target 12 bulan: 200 merchant · 3.000 transaksi/bulan ·
   3.000 kg limbah tersalurkan · 4.500 kg CO₂eq/bulan

7. UNDUH
   [ Unduh APK ]
   Akun demo: merchant@lestar.id / amira@lestar.id / budi@lestar.id
   Kata sandi: lestar2026
```

Terang, bersih, banyak ruang kosong — **bukan** gelap seperti UI merchant. Responsif; juri mungkin membukanya di HP.

**Angka harus persis sesuai proposal.** Jangan bulatkan atau lebihkan.

APK diletakkan di `landing/public/lestar.apk`. Karena Android memblokir instalasi dari sumber tak dikenal, sertakan panduan tiga langkah di bawah tombol unduh.

## Bagian 2 — Deck

10–12 slide. **Mendampingi demo live 7 menit, bukan menggantikannya.**

Aturan: kalau sesuatu ditunjukkan di app, jangan diulang di slide. Slide hanya untuk yang tidak bisa didemokan — angka pasar, arsitektur, roadmap.

| # | Slide | Isi |
|---|---|---|
| 1 | Judul | Lestar · nama · tanggal |
| 2 | Masalah | 14,73 juta ton · Rp 213–551 T · 7,29% emisi |
| 3 | Kenapa solusi lama gagal | Tabel gap analisis proposal §2.1 — Too Good To Go dan Surplus.id berhenti di B2C |
| 4 | Gagasan | Diagram kaskade dua tahap |
| 5 | **DEMO** | Slide penanda. Pindah ke HP. |
| 6 | Arsitektur | 4 komponen dari `01-architecture.md` |
| 7 | AI Pipeline | LSTM → Gemini → heuristik. **Tekankan fallback chain.** |
| 8 | Kenapa tiga UI berbeda | Tiga tangkapan layar berdampingan + argumen aksesibilitas |
| 9 | Model bisnis | Komisi + langganan B2B + green fee |
| 10 | Pasar | TAM Rp 960 M/thn · SAM Rp 48 M/thn · SOM Rp 480 jt/thn |
| 11 | Roadmap | 4 fase 12 bulan, proposal §2.7.1 |
| 12 | Penutup | "Dimulai dari Malang, dikembangkan menuju skala nasional." |

**Slide 8 adalah slide terkuat.** Argumen yang jarang dibawa peserta lain. Beri ruang penuh:

> *"Lestar tidak memaksakan satu design system ke tiga aktor yang hidup di dunia berbeda. Konsumen mendapat pengalaman ringan dan menyenangkan. Merchant mendapat kokpit data. Pengepul mendapat antarmuka yang bisa dibaca di bawah terik matahari dengan satu tangan."*

**Slide 7 — tekankan kejujuran.** Fallback chain bukan sekadar fitur teknis. Ini bukti sistemnya dipikirkan dan timnya tidak melebih-lebihkan. Sebutkan bahwa kolom `forecasts.source` mencatat asal setiap angka.

## Aset

| Aset | Sumber |
|---|---|
| Logo | `assets/logo.png` |
| Tangkapan layar app | ambil dari HP setelah D/E/F selesai |
| Diagram kaskade | buat sendiri, SVG, ikuti palet |
| Diagram arsitektur | dari `01-architecture.md` §1 |
| Foto makanan | Unsplash/Pexels, sama dengan yang dipakai di app |
| Grafik pasar | dari angka TAM/SAM/SOM proposal |

Ilustrasi hero dan diagram boleh dibuat dengan AI image generation. **Foto makanan jangan** — pakai stok asli, hasil generate sering janggal pada tekstur dan itu terbaca di layar besar.

## Deploy

MCP Vercel sudah terpasang. Kalau statusnya masih `Needs authentication`, minta pemilik proyek menjalankan `/mcp` → `plugin:vercel:vercel` → authenticate. **Tidak perlu token.**

## Cara kerja

- Commit setiap bagian yang jadi.
- Pesan commit Bahasa Indonesia.

## Selesai berarti

- Landing page terdeploy di Vercel, URL publik aktif
- Responsif di HP dan desktop
- APK bisa diunduh dan terpasang di perangkat bersih
- Kredensial akun demo tercantum di halaman
- **Semua angka cocok dengan proposal**, tidak ada yang dilebihkan
- Isian oranye memakai teks gelap, bukan putih
- Deck 10–12 slide, format PDF
- **Slide 8 memuat tiga tangkapan layar nyata dari app**, bukan mockup
- Deck selaras dengan urutan demo — tidak ada yang diulang dua kali

## Sebelum menutup sesi

Tulis ringkasan di `docs/06-agent-briefs/G-HANDOFF.md`: URL landing page, lokasi berkas deck, aset yang masih kurang, dan keputusan yang kamu ambil sendiri.
