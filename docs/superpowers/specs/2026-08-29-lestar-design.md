# Lestar — Spec Induk

**Tanggal** 29 Agustus 2026 · **Status** disetujui · **Deadline** Rabu 2 September 2026

---

## Ringkasan keputusan

Membangun **Lestar** — platform ekonomi sirkular tiga sisi — sebagai aplikasi Flutter Android tunggal, siap didemokan dalam 4 hari kerja oleh satu orang dibantu agent.

Basis kode difork dari **Ecobite** (16.882 baris Dart, Juara 1 National Excellence Competitions 2026), dengan seluruh lapisan Firebase diganti Supabase dan seluruh lapisan UI ditulis ulang.

## Keputusan yang diambil dan alasannya

| # | Keputusan | Alternatif yang ditolak | Alasan |
|---|---|---|---|
| 1 | **Flutter mobile penuh** | Web app, Flutter Web | Keputusan pemilik proyek. Risiko waktu diterima secara sadar dan dimitigasi dengan keputusan #2. |
| 2 | **Satu APK, tiga shell** | Tiga aplikasi terpisah | Satu codebase, satu build. Saat demo, juri melihat kaskade utuh dari satu perangkat — lebih kuat daripada berpindah aplikasi. |
| 3 | **Supabase, bukan Firebase** | Tetap di Firebase Ecobite | Keputusan pemilik proyek, sesuai proposal asli. Biaya: ~8–12 jam migrasi, dialokasikan penuh di Hari 1. |
| 4 | **flutter_map + OSM** | google_maps_flutter | Tanpa API key, tanpa billing, tanpa konfigurasi manifest. Satu titik gagal demo dihilangkan. |
| 5 | **FastAPI tidak menyentuh database** | FastAPI menulis langsung ke Postgres | Satu jalur tulis, tidak ada konflik saat demo, FastAPI boleh mati tanpa merusak data, tidak perlu service_role key di sisi Python. |
| 6 | **Tiga design system berbeda** | Satu design system untuk tiga role | Keputusan aksesibilitas. Pengepul memakai app di bawah matahari pada HP entry-level — glassmorphism di sana adalah penghalang. Sekaligus pembeda terkuat di depan juri. |
| 7 | **Triage dan pricing deterministik** | LLM menentukan skor keamanan pangan | Keamanan pangan tidak boleh bergantung pada model probabilistik. LLM hanya memperkaya narasi. |
| 8 | **Gerbang validasi fisik ditegakkan di database** | Cukup dicek di Flutter | Trigger Postgres menolak `status='live'` tanpa `physical_validated`. Aturan keselamatan tidak boleh hidup hanya di lapisan UI. |
| 9 | **Fallback heuristik di dalam APK** | Fallback hanya di server | Kalau internet mati, app tetap memberi rekomendasi. Ini juga penutup demo. |
| 10 | **`forecasts.source` selalu jujur** | Sembunyikan saat jatuh ke heuristik | Sistem tidak pernah menyamarkan asal angka. Kejujuran ini adalah bagian dari argumen di depan juri. |
| 11 | **Foto Unsplash, bukan AI** | AI image generation untuk makanan | Makanan hasil generate sering janggal pada tekstur dan bayangan, dan itu terbaca di layar besar. |
| 12 | **Cloudflare Workers AI dilewati** | Implementasi penuh sesuai proposal | Tidak menambah kemampuan yang terlihat, memakan waktu yang tidak ada. Fallback chain tetap tiga lapis dan tetap jujur. |

## Dokumen turunan

| Dokumen | Isi | Pemilik |
|---|---|---|
| `docs/00-PRD.md` | Produk, aktor, fitur, aturan bisnis, non-goals, risiko | semua |
| `docs/01-architecture.md` | 4 komponen, aliran data, state machine, ketahanan, peta migrasi | B |
| `docs/02-data-model.md` | 13 tabel, 7 enum, RLS, trigger, index, konstanta | A |
| `docs/03-design-system.md` | 3 sistem desain, token, komponen, gerak | D, E, F |
| `docs/04-ai-pipeline.md` | LSTM, 4 endpoint, fallback chain, data sintetis, deploy | C |
| `docs/05-demo-script.md` | Skenario 7 menit, data seed, alat bantu, pertanyaan juri | semua |
| `docs/06-agent-briefs/` | Brief per agent: kepemilikan file, tugas, definisi selesai | masing-masing |
| `docs/CREDENTIALS-NEEDED.md` | Daftar token yang harus diisi pemilik proyek | pemilik |

## Lingkup

**Termasuk:** autentikasi 3 role · Buffer Intelligence (LSTM + Gemini + heuristik) · input surplus + triage + gerbang validasi fisik · dynamic pricing · radar konsumen realtime · booking + QR claim · auto-cascade B2C ke B2B · radar pengepul + alur penjemputan · laporan ESG + export PDF · landing page · deck

**Tidak termasuk:** payment gateway sungguhan · push notification native · Cloudflare Workers AI · model LSTM per-merchant · build iOS · multi-bahasa · onboarding merchant mandiri

## Urutan korban kalau waktu habis

1. Langganan mitra B2B
2. Export PDF ESG — cukup tampil di layar
3. Animasi transisi

**Tidak pernah dikorbankan:** kaskade, QR claim, radar realtime, Buffer Intelligence, gerbang validasi fisik.

## Jadwal

| Hari | Fokus | Selesai kalau |
|---|---|---|
| **Sab 29** | Fondasi & migrasi (A, B, C mulai) | Login 3 role jalan, data terbaca dari Supabase |
| **Min 30** | Tema + merchant (D) + latih model (C) | Layar merchant tidak bisa dibedakan dari mockup |
| **Sen 31** | Konsumen (E) + pengepul (F) + deploy API (C) | Tiga UI berdiri, angka forecast dari LSTM nyata |
| **Sel 1** | Kaskade, ESG, landing (G), gladi 3× | Alur 7 menit jalan tanpa crash tiga kali berturut |
| **Rab 2** | Buffer + presentasi | — |

## Kriteria keberhasilan

- Alur demo 7 menit selesai tanpa crash, tiga kali gladi berturut-turut
- Setiap layar di jalur demo terhubung ke data nyata — nol mock
- Buffer Intelligence tetap memberi angka saat internet dimatikan
- Tiga UI terlihat jelas berbeda saat disandingkan
- Setiap angka di laporan ESG bisa ditelusuri ke baris `esg_events`

## Catatan kejujuran

Beberapa hal sengaja dibatasi supaya bisa dipertanggungjawabkan kalau ditanya juri:

- **Akurasi diklaim 70%**, bukan 95%. Model dilatih pada data sintetis, dan itu dinyatakan terbuka.
- **Gemini dibatasi menggeser angka LSTM maksimal 20%.** LLM tidak mengarang angka dari nol.
- **Pembayaran adalah simulasi**, dan itu disebutkan kalau ditanya.
- **Pintasan ganti role** adalah alat bantu presentasi, bukan fitur produk, dan disebut apa adanya.
- **`forecasts.source`** mencatat asal setiap angka, termasuk saat sistem jatuh ke heuristik.

Posisi ini diambil dengan sengaja. Klaim rendah yang bisa dibuktikan lebih kuat daripada klaim tinggi yang runtuh saat sesi tanya jawab.

## Referensi

- Proposal: `LESTAR - Proposal Hackathon KMIPN VIII After Revisi.md`
- Mockup: `mockup.png`
- Ecobite: https://github.com/Third-Connectors/EcoBite
