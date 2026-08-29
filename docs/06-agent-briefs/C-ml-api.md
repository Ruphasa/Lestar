# Agent C — ML & API

**Jadwal** Sabtu–Senin, **paralel penuh** · **Bergantung pada** A (nama kolom saja) · **Tidak memblokir siapa pun**

Kamu jalur paling bebas. Tidak ada yang menunggu kamu sampai Hari 3, dan kamu tidak menunggu siapa pun setelah nama kolom dibekukan. Manfaatkan itu — mulai dari generator sintetis Sabtu pagi.

---

## Milik kamu

```
ml/
api/
```

Tidak menyentuh apa pun di `lib/` atau `supabase/`.

## Baca dulu

1. `docs/04-ai-pipeline.md` — ini spesifikasi lengkapmu
2. `docs/02-data-model.md` §5, §10 — bentuk `sales_history` dan konstanta bersama

## Tugas

### 1. Generator sintetis — `ml/generate_synthetic.py`

30 merchant × 120 hari. Parameter lengkap ada di `04-ai-pipeline.md` §3.

**Kalibrasi wajib:** surplus rata-rata harus jatuh di **2–3 kg per merchant per hari**. Ini bukan angka bebas — dikutip dari riset Aksamala Foundation di Bab I proposal, dan seluruh proyeksi ESG bertumpu padanya. Kalau meleset, sesuaikan `faktor_kepercayaan` per merchant sampai masuk rentang.

Keluaran dua berkas:
- `ml/data/train.csv` — 120 hari penuh, untuk melatih
- `ml/data/seed_sales_history.csv` — 90 hari pertama, **diserahkan ke Agent A** untuk di-seed

Koordinasikan format kolom `seed_sales_history.csv` dengan Agent A sebelum menghasilkan berkasnya.

Cetak ringkasan statistik setelah generate — rata-rata porsi, rata-rata surplus, sebaran per kategori. Kalau angkanya terlihat aneh, ketahuan di sini, bukan saat demo.

### 2. Latih model — `ml/train_lstm.py`

Arsitektur ada di `04-ai-pipeline.md` §2. Satu model, dua output head.

- Window 14 hari, 11 fitur per hari
- Normalisasi per merchant, simpan `scale_factor` ke `ml/model/scalers.json`
- Split 80/20, `EarlyStopping` patience 8
- Simpan ke `ml/model/lestar_lstm.keras`

**Target:** MAE demand < 15% dari rata-rata. Kalau tidak tercapai setelah tiga kali percobaan hyperparameter, **laporkan apa adanya** — jangan naikkan klaim akurasi. Akurasi 70% yang jujur adalah posisi yang kita ambil di depan juri.

Cetak metrik akhir ke `ml/model/metrics.json`. Angka ini yang dipakai untuk badge `accuracy` di UI merchant — badge itu harus mencerminkan metrik nyata, bukan angka karangan.

### 3. FastAPI — `api/`

```
api/
  main.py           app + lifespan (muat model sekali) + /health
  constants.py      konstanta bersama — cocokkan dengan lib/core/constants.dart
  forecast.py       POST /forecast
  triage.py         POST /triage
  pricing.py        POST /pricing
  esg.py            POST /esg-narrative
  gemini.py         klien Gemini + penjaga batas ±20%
  weather.py        klien OpenWeatherMap
  Dockerfile
  requirements.txt
```

Kontrak keempat endpoint ada di `04-ai-pipeline.md` §4.

**Aturan keras:**
- **Stateless.** Tidak ada koneksi database. Tidak ada state antar request.
- `/triage` dan `/pricing` **deterministik**, tanpa LLM. Keamanan pangan dan harga tidak boleh bergantung pada model probabilistik.
- Gemini gagal → turun ke `lstm_only`, **tidak pernah** melempar error ke klien.
- Model gagal dimuat → `/health` melaporkan `degraded`, endpoint tetap membalas dengan heuristik sisi server.

**Penjaga batas Gemini** — `api/gemini.py`:
```python
# Gemini hanya boleh menggeser angka LSTM maksimal 20%
if abs(gemini_demand - lstm_demand) / lstm_demand > 0.20:
    return lstm_demand, template_narrative(), "lstm_only"
```
LLM tidak boleh mengarang angka dari nol. Kalau keluarannya di luar rentang wajar, tolak.

### 4. Deploy Railway

`Dockerfile` ada di `04-ai-pipeline.md` §7.

**`tensorflow-cpu`, bukan `tensorflow`.** Paket penuh membawa dependensi CUDA ~2 GB dan menembus batas free tier Railway.

Environment variable yang dibutuhkan:
```
GEMINI_API_KEY
OPENWEATHER_API_KEY
MODEL_PATH=./model/lestar_lstm.keras
ALLOWED_ORIGINS=*
```

Setelah deploy, kirim URL publiknya ke Agent B untuk dimasukkan ke `lestar_api.dart`.

### 5. Sinkronisasi rumus dengan Agent B

Rumus `triage` dan `pricing` ada **dua kali** — di Python milikmu dan di Dart milik Agent B. Ini disengaja, supaya app tetap berfungsi penuh tanpa server.

Buat `api/test_parity.py` berisi 10 kasus uji dengan input dan output yang diharapkan. Kirim berkas itu ke Agent B supaya dia bisa memverifikasi versi Dart-nya menghasilkan angka yang sama persis.

Kalau salah satu rumus diubah nanti, **yang lain harus ikut diubah**.

## Koordinasi

- **Ke Agent A:** kirim format `seed_sales_history.csv` sedini mungkin, Sabtu pagi kalau bisa
- **Ke Agent B:** kirim URL Railway + `test_parity.py`
- **Ke Agent D:** kirim `metrics.json` untuk badge akurasi di kartu forecast

## Definisi selesai

- [ ] Generator menghasilkan surplus rata-rata 2–3 kg/merchant/hari — dibuktikan dengan cetakan statistik
- [ ] Model terlatih, MAE demand < 15% dari rata-rata (atau dilaporkan apa adanya kalau tidak tercapai)
- [ ] `metrics.json` berisi angka akurasi nyata
- [ ] Empat endpoint merespons < 2 detik saat warm
- [ ] Gemini dimatikan → `/forecast` tetap 200 OK dengan `source='lstm_only'`
- [ ] Model dihapus → `/health` melaporkan `degraded`, `/forecast` tetap membalas
- [ ] `test_parity.py` lulus di Python, dan hasilnya cocok dengan versi Dart Agent B
- [ ] Image Docker < 1,5 GB
- [ ] Terdeploy di Railway, URL publik terkirim ke Agent B
- [ ] `/health` merespons < 300 ms
