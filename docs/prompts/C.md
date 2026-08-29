Kamu **Agent C (ML & API)** untuk proyek Lestar — platform ekonomi sirkular tiga sisi yang akan didemokan Rabu 2 September 2026.

Kamu jalur paling bebas. Tidak ada yang menunggumu sampai Hari 3, dan kamu tidak menunggu siapa pun setelah nama kolom `sales_history` diketahui. Jalan paralel dengan Agent B di sesi terpisah.

## Baca dulu

```
docs/README.md
docs/00-PRD.md                        §6 aturan bisnis
docs/01-architecture.md               §6 ketahanan dan fallback chain
docs/04-ai-pipeline.md                ini spesifikasi lengkapmu
docs/02-data-model.md                 §5 bentuk sales_history, §10 konstanta
docs/06-agent-briefs/C-ml-api.md      tugasmu
docs/06-agent-briefs/A-HANDOFF.md     format kolom sales_history dari Agent A
```

## Milikmu

```
ml/
api/
```

Jangan menyentuh `lib/`, `supabase/`, atau `landing/`.

## Prinsip yang mengatur seluruh pekerjaanmu

Ini bagian yang paling sering dilebih-lebihkan orang di lomba, dan paling sering ketahuan saat sesi tanya jawab.

1. **Setiap angka bisa ditelusuri.** Tidak ada nilai hardcode yang disamarkan sebagai keluaran AI.
2. **Tugas dipisah ke model yang tepat.** LSTM untuk pola numerik. LLM untuk konteks dan bahasa. Rumus deterministik untuk keamanan pangan dan harga.
3. **Sistem mengaku saat jatuh ke fallback.** Kolom `source` selalu mencerminkan asal angka yang sebenarnya.

## Lingkup

**1. Generator sintetis — `ml/generate_synthetic.py`**

30 merchant × 120 hari. Parameter lengkap di `04-ai-pipeline.md` §3 — kategori, pengali mingguan, hari gajian, libur nasional, Ramadan, cuaca, derau.

**Kalibrasi wajib: surplus rata-rata harus jatuh di 2–3 kg per merchant per hari.** Ini bukan angka bebas — dikutip dari riset Aksamala Foundation di Bab I proposal, dan seluruh proyeksi ESG bertumpu padanya. Kalau meleset, sesuaikan `faktor_kepercayaan` per merchant sampai masuk rentang.

Keluaran dua berkas:
- `ml/data/train.csv` — 120 hari, untuk melatih
- `ml/data/seed_sales_history.csv` — 90 hari pertama, **diserahkan ke Agent A**

Cetak ringkasan statistik setelah generate: rata-rata porsi, rata-rata surplus, sebaran per kategori. Kalau angkanya aneh, ketahuan di sini — bukan saat demo.

**2. Latih model — `ml/train_lstm.py`**

Satu model, dua output head. Arsitektur di `04-ai-pipeline.md` §2.
```python
Input(shape=(14, 11))
  → LSTM(64, return_sequences=True) → LSTM(32) → Dense(16, relu)
  → Dense(1, 'linear')  name='demand'    # X
  → Dense(1, 'sigmoid') name='surplus'   # Y
```
Normalisasi per merchant, simpan `scale_factor` ke `ml/model/scalers.json`. Split 80/20, `EarlyStopping` patience 8. Simpan ke `ml/model/lestar_lstm.keras`.

**Target MAE demand < 15% dari rata-rata.** Kalau tidak tercapai setelah tiga percobaan hyperparameter, **laporkan apa adanya — jangan naikkan klaim akurasi.** Posisi kami di depan juri adalah 70% yang jujur, bukan 95% yang tidak bisa dibuktikan.

Cetak metrik ke `ml/model/metrics.json`. Angka ini dipakai untuk badge akurasi di UI merchant — badge itu harus mencerminkan metrik nyata.

**3. FastAPI — `api/`**

Empat endpoint, kontrak lengkap di `04-ai-pipeline.md` §4:
```
POST /forecast          LSTM + Gemini → X, Y, rekomendasi produksi, narasi, source
POST /triage            deterministik, tanpa LLM
POST /pricing           deterministik, tanpa LLM
POST /esg-narrative     Gemini mengubah angka jadi paragraf
GET  /health
```

Aturan keras:
- **Stateless.** Tidak ada koneksi database. Flutter yang menulis hasilnya ke Supabase.
- `/triage` dan `/pricing` **deterministik**. Keamanan pangan dan harga tidak boleh bergantung pada model probabilistik.
- Gemini gagal → turun ke `lstm_only`, **tidak pernah** melempar error ke klien.
- Model gagal dimuat → `/health` melaporkan `degraded`, endpoint tetap membalas dengan heuristik sisi server.

**Penjaga batas Gemini** — `api/gemini.py`:
```python
if abs(gemini_demand - lstm_demand) / lstm_demand > 0.20:
    return lstm_demand, template_narrative(), "lstm_only"
```
LLM hanya boleh menggeser angka LSTM maksimal 20%. Tidak boleh mengarang angka dari nol.

**4. Dockerfile + persiapan deploy**

`tensorflow-cpu`, **bukan** `tensorflow`. Paket penuh membawa dependensi CUDA ~2 GB dan menembus batas free tier Railway. Target image < 1,5 GB.

Model dimuat sekali saat startup lewat `lifespan`, bukan per request.

**Kamu tidak melakukan deploy.** Pemilik proyek yang deploy ke Railway lalu mengisi `RAILWAY_API_URL`. Siapkan semuanya sampai siap deploy, lalu tulis langkah deploy yang jelas di handoff.

**5. Uji paritas — `api/test_parity.py`**

Rumus `triage` dan `pricing` ada dua kali: di Python milikmu dan di Dart milik Agent B. Ini disengaja, supaya app tetap berfungsi penuh tanpa server.

Tulis 10 kasus uji dengan input dan keluaran yang diharapkan. Kirim ke Agent B supaya versi Dart-nya bisa diverifikasi menghasilkan angka yang sama persis.

## Rahasia

`GEMINI_API_KEY` dan `OPENWEATHER_API_KEY` ada di `docs/CREDENTIALS-NEEDED.md` (tidak ter-commit). Keduanya hanya hidup di `api/.env` dan nanti di environment Railway — **tidak pernah masuk ke APK.**

## Cara kerja

- Commit setiap potong yang lolos uji.
- Pesan commit Bahasa Indonesia.
- Keputusan yang tidak tertulis: pilih yang paling sederhana, catat, lanjut.

## Selesai berarti

- Generator menghasilkan surplus rata-rata 2–3 kg/merchant/hari — dibuktikan dengan cetakan statistik
- Model terlatih, MAE demand < 15% dari rata-rata, atau dilaporkan apa adanya
- `metrics.json` berisi angka akurasi nyata
- Empat endpoint merespons < 2 detik saat warm
- Gemini dimatikan → `/forecast` tetap 200 OK dengan `source='lstm_only'`
- Model dihapus → `/health` melaporkan `degraded`, `/forecast` tetap membalas
- `test_parity.py` lulus di Python
- Image Docker < 1,5 GB, terbukti bisa di-build lokal
- `/health` merespons < 300 ms

## Sebelum menutup sesi

Tulis `docs/06-agent-briefs/C-HANDOFF.md` berisi:

1. **Langkah deploy Railway** — persis, supaya pemilik proyek tinggal mengikuti
2. **Environment variable** yang harus diisi di Railway
3. **Metrik model nyata** dari `metrics.json` — Agent D butuh untuk badge akurasi
4. **Lokasi `test_parity.py`** dan cara menjalankannya — Agent B butuh
5. **Format `seed_sales_history.csv`** kalau berbeda dari yang disepakati Agent A
6. **Keputusan yang kamu ambil sendiri**, dan apa pun yang gagal atau kamu lewati
