# Agent G — Landing Page & Deck

**Jadwal** Selasa 1 September, **paralel penuh** · **Tidak bergantung pada siapa pun** · **Tidak memblokir siapa pun**

Kamu jalur paling bebas kedua setelah C. Bisa mulai kapan saja begitu aset brand tersedia.

---

## Milik kamu

```
landing/
deck/
```

Tidak menyentuh apa pun di `lib/`, `api/`, `supabase/`.

## Baca dulu

1. `docs/00-PRD.md` — apa produknya dan untuk siapa
2. `docs/03-design-system.md` — bahasa visual
3. `LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md` — sumber seluruh angka dan klaim
4. `docs/05-demo-script.md` — deck harus selaras dengan alur demo

## Bagian 1 — Landing Page

### Tujuan
Juri membuka satu link, memahami produknya dalam 30 detik, dan bisa mengunduh APK.

### Stack
Next.js statis, deploy Vercel. Boleh HTML + Tailwind murni kalau lebih cepat — tidak ada yang menilai kodenya.

### Struktur

```
1. HERO
   Lestar — Setiap kilogram punya jalur nilai
   Platform ekonomi sirkular yang menghubungkan merchant F&B,
   konsumen, dan pengolah limbah organik dalam satu alur kaskade.
   [ Unduh APK ]  [ Lihat cara kerjanya ]

2. MASALAH
   14,73 juta ton      sampah makanan Indonesia per tahun
   Rp 213–551 triliun  kerugian ekonomi per tahun
   7,29%               kontribusi emisi gas rumah kaca
   40,76%              porsi sisa makanan dari total sampah nasional
   (sumber: UNEP Food Waste Index 2024, KLHK 2025)

3. KASKADE — diagram alur, bagian terpenting halaman ini
   Surplus → Triage AI → Validasi Fisik → Flash Sale B2C
                                        → Limbah Organik B2B
                                        → Laporan ESG

4. TIGA AKTOR — tiga kartu, tangkapan layar app masing-masing
   Merchant · Konsumen · Pengepul
   Tunjukkan bahwa UI-nya memang berbeda. Ini pembeda utama.

5. BUFFER INTELLIGENCE
   LSTM memprediksi permintaan besok. Merchant berani produksi
   lebih banyak karena setiap surplus punya jalur keluar.

6. DAMPAK
   Target 12 bulan: 200 merchant · 3.000 transaksi/bulan ·
   3.000 kg limbah tersalurkan · 4.500 kg CO₂eq/bulan

7. UNDUH
   [ Unduh APK — 24 MB ]
   Akun demo: merchant@lestar.id / amira@lestar.id / budi@lestar.id
   Kata sandi: lestar2026
```

### Aturan visual
- Palet mengikuti `03-design-system.md` §3 — **dua keluarga warna dari logo**: hijau (`#265938` forest · `#009966` · `#00BC7D`) untuk sistem dan keberlanjutan, oranye (`#F38222` · `#C2540E`) untuk selera, urgensi, dan uang. Netral memakai token `neutral-*` Tailwind v4
- Font **Plus Jakarta Sans** (display) + **Inter** (body) — dua-duanya di Google Fonts
- **Isian oranye selalu memakai teks gelap `#0A0A0A`**, tidak pernah putih
- Logo `assets/logo.png` bisa dipakai apa adanya di landing page — latar krem `#EDE5D8` justru menyatu dengan hero yang hangat. Untuk favicon dan header pakai varian glyph transparan
- Terang, bersih, banyak ruang kosong. Bukan gelap seperti UI merchant.
- Responsif. Juri mungkin membukanya di HP.
- **Angka harus sesuai proposal.** Jangan bulatkan atau lebihkan.

### APK
Letakkan di `landing/public/lestar.apk`. Tombol unduh menunjuk langsung ke sana.

Karena Android memblokir instalasi dari sumber tidak dikenal, sertakan panduan tiga langkah singkat di bawah tombol.

## Bagian 2 — Deck

### Format
10–12 slide. Mendampingi demo live 7 menit, **bukan menggantikannya**.

Aturan: kalau sesuatu ditunjukkan di app, jangan diulang di slide. Slide hanya untuk yang tidak bisa didemokan — angka pasar, arsitektur, roadmap.

### Struktur

| # | Slide | Isi |
|---|---|---|
| 1 | Judul | Lestar · nama · tanggal |
| 2 | Masalah | 14,73 juta ton · Rp 213–551 T · 7,29% emisi |
| 3 | Kenapa solusi lama gagal | Tabel gap analisis dari proposal §2.1 — Too Good To Go dan Surplus.id berhenti di B2C |
| 4 | Gagasan | Diagram kaskade dua tahap |
| 5 | **DEMO** | Slide penanda. Pindah ke HP. |
| 6 | Arsitektur | 4 komponen dari `01-architecture.md` |
| 7 | AI Pipeline | LSTM → Gemini → heuristik. Tekankan fallback chain. |
| 8 | Kenapa tiga UI berbeda | Tiga tangkapan layar berdampingan + argumen aksesibilitas |
| 9 | Model bisnis | Komisi + langganan B2B + green fee |
| 10 | Pasar | TAM Rp 960 M/thn · SAM Rp 48 M/thn · SOM Rp 480 jt/thn |
| 11 | Roadmap | 4 fase 12 bulan dari proposal §2.7.1 |
| 12 | Penutup | "Dimulai dari Malang, dikembangkan menuju skala nasional." |

### Slide 8 adalah slide terkuat

Ini argumen yang jarang dibawa peserta lain. Berikan ruang penuh.

> *"Lestar tidak memaksakan satu design system ke tiga aktor yang hidup di dunia berbeda. Konsumen mendapat pengalaman ringan dan menyenangkan. Merchant mendapat kokpit data. Pengepul mendapat antarmuka yang bisa dibaca di bawah terik matahari dengan satu tangan."*

### Slide 7 — tekankan kejujuran

Fallback chain bukan sekadar fitur teknis. Ini bukti bahwa sistemnya dipikirkan dan timnya tidak melebih-lebihkan. Sebutkan bahwa `forecasts.source` mencatat asal setiap angka.

## Aset yang dibutuhkan

| Aset | Sumber |
|---|---|
| Logo Lestar | dari pemilik proyek |
| Tangkapan layar app | ambil dari HP setelah D/E/F selesai (Selasa siang) |
| Diagram kaskade | buat sendiri — SVG, mengikuti palet |
| Diagram arsitektur | buat sendiri, dari `01-architecture.md` §1 |
| Foto makanan | Unsplash/Pexels, sama dengan yang dipakai di app |
| Grafik pasar | buat sendiri dari angka TAM/SAM/SOM proposal |

Ilustrasi hero dan diagram boleh dibuat dengan AI image generation. **Foto makanan jangan** — pakai stok asli.

## Definisi selesai

- [ ] Landing page terdeploy di Vercel, URL publik aktif
- [ ] Responsif di HP dan desktop
- [ ] APK bisa diunduh dan terpasang di perangkat bersih
- [ ] Kredensial akun demo tercantum di halaman
- [ ] Semua angka cocok dengan proposal, tidak ada yang dilebihkan
- [ ] Deck 10–12 slide selesai, format PDF
- [ ] Slide 8 memuat tiga tangkapan layar nyata dari app, bukan mockup
- [ ] Deck selaras dengan urutan demo — tidak ada yang diulang dua kali
