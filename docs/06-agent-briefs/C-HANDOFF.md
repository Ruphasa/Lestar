# Agent C — Serah Terima ML & API

**Selesai** 31 Agustus 2026 · **11 commit** (`1b7e69c^..d5fb156`) · **Python** 3.11.0
di `ml/.venv` · **api/** 86 test lolos, **ml/** 14 test lolos (dijalankan ulang
sendiri sebelum menulis dokumen ini, bukan disalin dari laporan tugas)

Lima route jadi: `/health`, `/triage`, `/pricing`, `/forecast`,
`/esg-narrative`. **Belum di-deploy ke Railway** — bagian 1 di bawah adalah
langkahnya. `api/.env` **belum pernah dibuat**, jadi Gemini dan OpenWeatherMap
belum pernah dipanggil sungguhan sekali pun — lihat bagian 6.2, ini risiko
terbesar yang tersisa.

> **Aturan satu kalimat:** apa pun angka di dokumen ini datang dari keluaran
> yang benar-benar dijalankan (laporan tugas, ledger pengontrol, atau
> dijalankan ulang sendiri saat menulis dokumen ini). Tidak ada angka yang
> dikarang untuk mengisi tabel.

---

## 0. Cara mulai

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -q       # 86 passed
cd ml  && .venv/Scripts/python.exe -m pytest -q              # 14 passed

# Jalankan lokal tanpa Docker:
cd api && ../ml/.venv/Scripts/python.exe -m uvicorn main:app --port 8000
curl http://127.0.0.1:8000/health
```

`python`/`python3` biasa **tidak boleh dipakai** di mesin Windows manapun yang
menjalankan repo ini — itu stub Microsoft Store yang rusak. Selalu panggil
`ml/.venv/Scripts/python.exe` secara eksplisit.

---

## 1. Langkah deploy Railway

Belum pernah dijalankan — pemilik proyek yang menjalankan ini, bukan agent.
Persis, supaya tinggal diikuti dari folder `api/`:

```bash
cd api
railway login
railway init                 # atau: railway link, kalau project sudah ada
railway up                   # build dari Dockerfile di folder ini
```

Railway menyuntikkan variabel `PORT` miliknya sendiri saat container jalan.
`api/Dockerfile` sudah membacanya:

```
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

Tidak perlu di-set manual — kalau `PORT` tidak ada (mis. `docker run` lokal
tanpa `-e PORT`), default `8000` yang dipakai, dan itu sudah terbukti jalan
(lihat bagian 3 di `.superpowers/sdd/2026-08-30-agent-c-ml-api/task-10-report.md`).

**Isi environment variable** lewat dashboard Railway (project → service →
tab *Variables*), bukan lewat file yang ikut ter-commit. Daftar lengkap dan
sumber nilainya ada di bagian 2.

**Pasang domain publik**: dashboard Railway → service → tab *Settings* →
*Networking* → *Generate Domain*. Railway memberi subdomain `*.up.railway.app`
gratis; domain custom tidak diperlukan untuk demo.

**Pastikan hidup**, setelah domain terbit:

```bash
curl https://<domain-railway-anda>.up.railway.app/health
```

Harapannya: `{"status":"ok","model_loaded":true,...}`. Kalau `status` malah
`degraded`, model tidak ikut ter-copy ke image atau `MODEL_PATH` salah — lihat
bagian 6.3 tentang jebakan `.keras` sebelum menuduh Railway.

Setelah URL publik ada, kirim ke Agent B untuk `--dart-define=API_BASE_URL=...`
(lihat baris terakhir bagian 6.1).

---

## 2. Environment variable Railway

Nama saja — **tanpa nilainya** di sini atau di mana pun di repo:

| Variable | Dibaca oleh | Efek kalau kosong |
|---|---|---|
| `GEMINI_API_KEY` | `api/gemini.py` | `/forecast` tetap `source='lstm_only'`, `/esg-narrative` tetap `source='template'` — tidak pernah error |
| `OPENWEATHER_API_KEY` | `api/weather.py` | `/forecast` memakai `weather_forecast` dari klien atau kode cuaca `0` (cerah) |
| `MODEL_PATH` | `api/main.py` (lifespan) | default `./model/lestar_lstm.keras`, sudah benar untuk image ini — biasanya tidak perlu di-override |
| `ALLOWED_ORIGINS` | `api/main.py` (CORS) | default `*` |

Sumber nilainya: `docs/CREDENTIALS-NEEDED.md` (tidak ter-commit). Dokumen ini
**tidak dibaca** saat menulisnya — instruksi tugas eksplisit melarangnya, dan
tidak ada nilai kunci yang perlu diketahui untuk mengisi tabel di atas.

---

## 3. Metrik model nyata

Dari `ml/model/metrics.json` (byte-identik dengan `api/model/metrics.json`,
yang dipakai container — dicocokkan sendiri dengan `cmp` semantik saat
menulis dokumen ini):

| Field | Nilai | Untuk apa |
|---|---|---|
| `demand_mae_porsi` | **8,2 porsi** | MAE mentah, dipakai di badge sisi jika perlu satuan porsi |
| `demand_mae_pct` | **7,73%** | MAE relatif terhadap rata-rata — ini yang dibandingkan ke target 15% |
| `demand_akurasi` | **0,9227** (92%) | `1 − MAE%`, dasar badge akurasi merchant |
| `surplus_akurasi` | **0,8583** (85,8%) | akurasi kepala kedua (klasifikasi surplus/tidak) |
| `target_met` | **true** | target MAE < 15% tercapai di percobaan pertama, tanpa tuning hyperparameter tambahan |
| `klaim_publik` | **0,70** | **tidak berubah** — ini klaim ke juri/merchant sungguhan, bukan metrik model |
| `n_window_validasi` | 720 | split kronologis 80/20, 30 merchant, `leak_found=False` (diverifikasi ulang reviewer Tugas 5 dari nol) |

`target_met` **true**, jadi tidak ada eskalasi tiga-percobaan hyperparameter
yang perlu dilaporkan — jalur default (`epochs=120, batch=32, unit1=64,
unit2=32`, berhenti di epoch 19 lewat `EarlyStopping patience=8`) langsung
mencapai target.

**Jangan hardcode 92% di UI.** Agent D membaca `demand_akurasi` langsung dari
`metrics.json` lewat respons `/health`, badge-nya berlabel `92% · data
sintetis` (bukan angka polos) — keputusan pemilik proyek di
`docs/04-ai-pipeline.md` §10, ditulis 30 Agustus 2026, MENGGANTIKAN instruksi
awal di brief tugas ini yang meminta clamp ke 0,70.

**Kenapa dua angka (92% dan 70%) hidup berdampingan, kata pemilik proyek
sendiri**, disimpan verbatim di `metrics.json` → `dasar_klaim`:

> *"92% diukur pada split kronologis data sintetis Fase 1. Untuk merchant
> sungguhan kami klaim 70% — dan jarak itulah alasan Fase 2 melakukan
> fine-tuning dengan data transaksi nyata."*

`confidence` per ramalan (field berbeda dari badge akurasi, jangan disatukan
— lihat `04-ai-pipeline.md` §10) dihitung `demand_akurasi × faktor_situasi`:

| `source` | faktor_situasi | confidence (dari 0,9227) |
|---|---|---|
| `lstm_gemini`, riwayat 14 hari penuh | 1,00 | 0,923 |
| `lstm_only` | 0,90 | 0,830 |
| riwayat < 14 hari | dikali `n_hari/14` | — lihat bagian 6.2, jalur ini tidak tercapai lewat `/forecast` di arsitektur sekarang |
| `heuristic` (server) | tetap | 0,45 |

Kedua nilai (0,830 dan 0,923) diverifikasi lewat server `uvicorn` sungguhan
saat Tugas 6–7, bukan cuma lewat `TestClient`.

---

## 4. `test_parity.py` — untuk Agent B

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_parity.py -v
```

Dijalankan ulang saat menulis dokumen ini: **18 passed** (10 kasus triage +
2 tambahan + 3 kasus pricing + 3 tambahan). Tabel di bawah adalah 10+3 kasus
inti; kolom terakhir adalah hasil Python sungguhan dari run ini — untuk
dibandingkan baris demi baris dengan `test/fallback_engine_test.dart`.

### Triage — 10 kasus

| Kategori | Jam sejak masak | Suhu °C | Rute | Asal angka | Hasil Python |
|---|---|---|---|---|---|
| roti | 6 | 28 | b2c | 100 − 6/24×60 | **85** |
| gorengan | 3 | 28 | b2c | 100 − 3/6×60, tepat di ambang | **70** |
| gorengan | 4 | 28 | b2b | 100 − 40 | **60** |
| nasi_lauk | 2 | 28 | b2c | 100 − 2/8×60 | **85** |
| nasi_lauk | 2 | 33 | b2c | 85 − 15 (penalti suhu) | **70** |
| kue | 12 | 28 | b2c | 100 − 12/72×60 | **90** |
| seafood | 1 | 28 | b2b | 100 − 15 − 20 (kategori cepat rusak) | **65** |
| santan_susu | 1 | 28 | b2b | 100 − 12 − 20 | **68** |
| minuman | 6 | 31 | b2b | 100 − 30 − 15 (suhu) | **55** |
| **lainnya** | **1** | **28** | **b2c** | shelf default 8 jam: 100 − 7,5 = 92,5 | **93** |

**Kasus 10 adalah jebakan pembulatan yang eksplisit diminta B-HANDOFF §11.1**:
`lainnya · 1 jam · 28°C` memberi **93, bukan 92**. `round()` bawaan Python
membulatkan 92,5 ke genap (92); `round_half_away` (dan `double.round()` Dart)
membulatkan menjauhi nol (93). Kalau Dart dan Python pernah berbeda di kasus
ini, salah satu sisi memakai fungsi pembulatan yang salah — bukan bug logika
triage.

Dua kasus batas tambahan yang juga lolos: `seafood · 48 jam · 35°C` dijepit ke
**0**, `kue · 0 jam · 25°C` dijepit ke **100**.

### Pricing — 3 kasus

| Harga asli | Jam tersisa | Jam total | Stok sisa | Stok awal | Diskon | Harga | Hasil Python |
|---|---|---|---|---|---|---|---|
| 25.000 | 0 | 8 | 10 | 10 | 0,80 → dijepit **0,70** | 7.500 | **diskon 0,70 · harga 7500** |
| 20.000 | 8 | 8 | 0 | 10 | 0,30 | 14.000 | **diskon 0,30 · harga 14000** |
| 30.000 | 4 | 8 | 5 | 10 | 0,55 | 13.500 | **diskon 0,55 · harga 13500** |

Kasus pertama menunjukkan `DISKON_MAKSIMUM=0,70` bekerja (rumus mentah memberi
0,80). Semua harga hasil adalah kelipatan 500, dan `jam_total=0` diperlakukan
sebagai jendela sudah habis (`rasio_waktu=1.0`), bukan pembagian oleh nol —
diuji terpisah di `test_pricing_jam_total_nol_tidak_membagi_nol`.

---

## 5. Format `seed_sales_history.csv` — untuk Agent A

`ml/data/seed_sales_history.csv`, **2700 baris** (30 merchant × 90 hari),
jendela tanggal `2026-05-31` sampai `2026-08-28`. Kolom persis, urutan persis:

```
merchant_id,date,portions_sold,revenue,day_of_week,is_holiday,weather_code,surplus_kg
```

`day_of_week` 0 = Senin (`ts.weekday()`, tanpa offset — konvensi yang sama
dipakai di seluruh proyek). `weather_code` 0..3 (0 cerah … 3 hujan). Sudah
diverifikasi: berkas ini adalah prefiks persis dari `ml/data/train.csv`
(3600 baris, sampai `2026-09-27`) — data yang sama, dipotong per tanggal.

**Dua berkas, dua tujuan berbeda — jangan tertukar.** `train.csv` (120 hari,
3600 baris) dipakai untuk melatih model dan **tidak pernah keluar dari
`ml/`** — tidak di-commit, tidak masuk Supabase. `seed_sales_history.csv`
(90 hari, 2700 baris, berkas yang dibahas di bagian ini) adalah yang
di-`insert` ke `sales_history` lewat Agent A, dan karena itu **satu-satunya**
yang muncul di layar mana pun — kartu forecast, badge ESG, apa pun yang
Agent D query dari database. Seluruh statistik di bagian ini dihitung dari
`seed_sales_history.csv`, bukan `train.csv` — keduanya berbeda tipis (sekitar
0,3%) karena `train.csv` punya 30 hari tambahan yang tidak ikut ter-seed.

**Insert aman**, `on conflict` bukan `delete`, supaya FK yang sudah ada
(`sales_history` dirujuk `forecasts`) tidak putus:

```sql
insert into sales_history (merchant_id, date, portions_sold, revenue,
                           day_of_week, is_holiday, weather_code, surplus_kg)
values (...)
on conflict (merchant_id, date) do update set
  portions_sold = excluded.portions_sold,
  revenue       = excluded.revenue,
  day_of_week   = excluded.day_of_week,
  is_holiday    = excluded.is_holiday,
  weather_code  = excluded.weather_code,
  surplus_kg    = excluded.surplus_kg;
```

**Kenapa berkas ini menggantikan seed lama**: seed lama (dibuat Agent A
sebagai penjaga sementara sebelum tugas ini jalan, lihat `A-HANDOFF.md` §3)
memberi surplus rata-rata **1,422 kg/merchant/hari** — di bawah rentang
riset Aksamala Foundation (2–3 kg). Berkas baru ini terkalibrasi lewat bagi
dua (bukan diundi) sampai rata-rata masuk rentang, dan tercapai di **2,371
kg/merchant/hari** — dihitung langsung dari `seed_sales_history.csv` sendiri
(`pandas.read_csv(...)['surplus_kg'].mean()`), bukan dari cetakan generator
yang mencakup 120 hari penuh (yang mencetak 2,381 kg — lihat bagian 6.1).
Keduanya masuk rentang 2–3 kg; angka 2,371 kg adalah yang benar-benar ada di
Supabase.

**Agent D akan melihat angka bergeser** setelah reseed ini masuk: rata porsi
per hari naik dari basis lama ke **105,45 porsi/hari** (dulu sekitar 71 —
lihat catatan di laporan Tugas 4), dan rata revenue **Rp 1.922.620/hari**.
Ini perubahan yang disengaja, bukan regresi — kartu forecast dan badge ESG
di layar merchant akan menampilkan angka yang lebih tinggi daripada saat
gladi memakai seed lama.

Sebaran per kategori merchant (rata porsi, rata surplus kg), dihitung dari
`seed_sales_history.csv`:

| Kategori | Avg porsi | Avg surplus kg |
|---|---|---|
| bakery | 135,59 | 2,076 |
| kafe | 97,17 | 2,571 |
| katering | 142,69 | 2,397 |
| warung | 67,81 | 2,422 |

---

## 6. Keputusan yang diambil sendiri, dan apa pun yang gagal atau dilewati

### 6.1 Keputusan desain

- **Jendela 120 hari `2026-05-31`…`2026-09-27`.** 30 hari terakhir jendela
  ini (`2026-08-29`…`2026-09-27`) jatuh **setelah** hari demo (2 September
  2026). Ini bukan kesalahan tanggal — kalender generator sepenuhnya
  sintetis (pola hari-dalam-minggu, gajian, libur, cuaca acak berseed),
  tidak menyimpan atau membocorkan kejadian nyata hari demo. 120 hari
  dipakai supaya `train_lstm.py` punya cukup baris untuk split kronologis
  80/20 yang berarti (2460 window latih, 720 validasi); hanya **90 hari
  pertama** (`seed_sales_history.csv`, berhenti di `2026-08-28`, sebelum
  demo) yang benar-benar masuk ke database Supabase lewat Agent A. Cetakan
  statistik generator (`ml/generate_synthetic.py`, tanpa argumen, dicetak
  ulang saat menulis dokumen ini) melaporkan seluruh 3600 baris/120 hari:
  rata porsi/hari 105,74, rata revenue Rp 1.928.837, rata surplus global
  **2,381 kg/merchant/hari** (per kategori: bakery 135,63/2,115 kg, kafe
  97,64/2,551 kg, katering 143,25/2,377 kg, warung 67,99/2,449 kg). Ini
  angka generator penuh, dipakai untuk membuktikan definisi-selesai di
  bagian 7 — **bukan** angka yang ada di Supabase. Angka yang benar-benar
  ter-seed (90 hari pertama saja) ada di bagian 5, dan sedikit lebih rendah
  di semua baris karena 30 hari terakhir generator tidak ikut ter-potong ke
  dalamnya.
- **Kalibrasi `faktor_kepercayaan` lewat bagi dua** (`_cari_faktor`, binary
  search di rentang `0,90–1,30` yang dikunci), bukan diundi lalu diharap
  masuk rentang. Satu merchant (Roti Gembong Blimbing, bakery) tetap tidak
  tercapai — lihat bagian 6.4.
- **Pemetaan kategori merchant → berat porsi** (warung/katering **0,35 kg**,
  kafe **0,20 kg**, bakery **0,08 kg**) diambil apa adanya dari
  `BERAT_PORSI_KG` di `api/constants.py` / `02-data-model.md` §10 —
  **tidak ada konstanta baru yang lahir** di `ml/generate_synthetic.py`.
- **Split kronologis 80/20, bukan acak**, per merchant (`bangun_window_terpisah`
  di `ml/train_lstm.py`, `batas = int(len(g) * 0.8)`, validasi mengambil
  `WINDOW` hari tambahan ke belakang supaya window pertamanya tetap penuh).
  Kebocoran yang dihindari: kalau split acak dipakai, window validasi bisa
  memuat hari-hari yang tetangganya (14 hari sebelum/sesudah) ada di set
  latih, sehingga model "mengintip" pola musiman yang seharusnya diuji buta.
  Diverifikasi ulang dari nol oleh reviewer Tugas 5: `leak_found=False`,
  30 merchant diperiksa.
- **`scale_factor` saat inferensi diambil dari request** (rata-rata 14 baris
  history yang dikirim), **bukan dari `scalers.json`** — didokumentasikan
  langsung di docstring `rakit_window()`: layanan ini stateless dan bisa
  menerima merchant yang belum pernah dilihat model, jadi skala per-merchant
  yang tersimpan tidak selalu relevan. `scalers.json`'s `global` dipakai
  sebagai jaring pengaman kalau history-nya semua nol.
- **Gemini dipanggil lewat REST `httpx`**, bukan SDK `google-generativeai` —
  satu dependensi berat lebih sedikit di image, kontrol timeout langsung di
  tangan (`TIMEOUT=3.0` di `api/gemini.py`). Alasan ini dicatat sebagai
  komentar di `api/requirements.txt` sendiri.
- **Model tidak ada → `source='heuristic'`.** Penting untuk diluruskan:
  `'heuristic'` di server (`api/heuristik.py`) **bukan** "dihitung di dalam
  APK" — itu istilah lain untuk `FallbackEngine` Dart yang berjalan offline
  di perangkat. `'heuristic'` di server berarti "tidak ada model LSTM yang
  menghasilkan angka ini", dan heuristik Python-nya adalah port terpisah
  (rata-rata 7 hari terakhir × pengali hari-dalam-minggu × faktor hujan
  0,88), bukan panggilan ke kode Dart. Enum `forecast_source` di database
  (`lstm_gemini | lstm_only | heuristic`) tidak membedakan siapa yang
  menghitungnya — Agent D perlu tahu ini kalau menampilkan label sumber di UI.
- **`confidence` diturunkan dari `metrics.json`** (`demand_akurasi ×
  faktor_situasi`), bukan angka tetap — lihat tabel di bagian 3.
- **Pengali Ramadan diterapkan di generator** (`RAMADAN = 0.40` di
  `ml/generate_synthetic.py`) **tapi tidak pernah aktif** di jendela data
  ini — Ramadan 1447 H jatuh 17 Februari–19 Maret 2026, seluruhnya di luar
  `2026-05-31`…`2026-09-27`. Kodenya benar kalau jendela pernah digeser
  mundur ke awal tahun, tapi pada data yang ada sekarang efeknya nol.
- **Tanggal Hijriah di `ml/kalender.py`** (Tahun Baru Islam, Maulid Nabi)
  adalah **perkiraan hisab**, bukan hasil sidang isbat resmi. SKB tiga
  menteri bisa menggeser satu hari. Untuk data sintetis ini tidak masalah —
  pergeseran satu hari tidak mengubah pola yang dipelajari model — tapi
  jangan dipakai sebagai sumber kalender resmi di tempat lain.
- **`api/weather.py` tidak punya rute sendiri.** `04-ai-pipeline.md` §4 hanya
  menetapkan lima endpoint (empat awal + `/esg-narrative`); `weather.py`
  adalah helper yang dipanggil dari dalam `/forecast` saat klien tidak
  mengirim `weather_forecast`-nya sendiri.
- **Bukan setiap field bernama `code`/`weather_code` memakai skala yang
  sama** — jangan asumsikan keseragaman meski `04-ai-pipeline.md` §4 dan
  contoh `"weather_forecast": {"code": 0}` di dalamnya terlihat seperti
  memakai skala yang sama dengan `history[].weather_code`. Tiga skala
  beredar:
  - `history[].weather_code` (dikirim Agent A lewat `sales_history`):
    smallint **0..3** (0 cerah, 1 berawan, 2 mendung, 3 hujan).
  - `weather_forecast.code` di badan permintaan `/forecast`
    (`api/schemas.py:24-26`, `WeatherForecast.code`): **tidak dijamin
    0..3.** Field ini `int` tak terbatas — pemanggil boleh mengirim skala
    0..3 di atas, id kondisi OpenWeatherMap asli (`200`..`804`, lihat
    `api/weather.py:kode_dari_owm`), atau skala ketiga yang didokumentasikan
    `lib/core/fallback_engine.dart:44` ("memakai kode OpenWeatherMap: 60 ke
    atas berarti hujan" — bukan id OWM asli, yang mulai dari `200`, jadi ini
    skala sendiri milik `FallbackEngine`).
  - `normalisasi_weather` (`api/constants.py:75`) adalah **satu-satunya**
    fungsi yang melayani ketiga skala itu sekaligus dan mengembalikan
    0..1 — ini sebabnya `api/heuristik.py` dan `api/forecast.py` wajib
    memanggilnya, bukan menulis ulang ambang batasnya sendiri (lihat
    riwayat commit `heuristik.py` untuk kasus id OWM `800` yang pernah
    salah dibaca "hujan" gara-gara perbandingan `>= 60` inline).
- **Satu baris pengecualian di `.gitignore`**: `ml/data/*.csv` mengabaikan
  seluruh CSV hasil generate (termasuk `train.csv` yang besar dan tidak
  perlu ikut commit), tapi baris berikutnya, `!ml/data/seed_sales_history.csv`,
  menegasikannya khusus untuk berkas yang diserahkan ke Agent A.
- **`api/model/` di-commit** (tiga berkas: `.keras`, `scalers.json`,
  `metrics.json`) karena konteks build Docker adalah folder `api/` sendiri
  — `Dockerfile` tidak bisa `COPY` sesuatu dari luar `api/` (`../ml/model/`
  tidak terjangkau saat `docker build` dijalankan dari `api/`).
- **Belum di-deploy.** Pemilik proyek yang menjalankan `railway up` (bagian
  1), lalu mengisi hasil URL publiknya ke `RAILWAY_API_URL`; Agent B
  menerimanya lewat `--dart-define=API_BASE_URL=...` saat build APK.

### 6.2 Risiko terbesar yang tersisa — belum ada panggilan nyata ke Gemini atau OpenWeatherMap

`api/.env` **tidak pernah dibuat** di seluruh sepuluh tugas sebelumnya.
Setiap satu dari 86 test `api/` yang menyentuh Gemini atau OpenWeatherMap
melakukannya lewat `monkeypatch` — tidak ada `httpx.post`/`httpx.get`
sungguhan yang pernah keluar ke internet dari kode ini. Bentuk respons yang
diasumsikan kode:

- Gemini: `r.json()['candidates'][0]['content']['parts'][0]['text']`
  (`api/gemini.py`)
- OpenWeatherMap: `list[].weather[0].id` di dalam `r.json()['list']`
  (`api/weather.py`)

**Kalau salah satu bentuk ini keliru** — API berubah skema, atau asumsinya
sejak awal salah — kode tetap mengembalikan `None` lewat blok
`except Exception`, dan `/forecast`/`/esg-narrative` tetap membalas **200 OK**
dengan fallback (`lstm_only` / `template`). Tidak ada yang gagal keras.
Tidak ada log yang menyala. Tidak ada test yang bisa menangkapnya, karena
tidak ada test yang pernah bicara dengan API sungguhan. Ini persis jenis
kegagalan yang baru ketahuan saat demo, di depan juri, ketika seseorang
bertanya kenapa narasinya "generik" padahal Gemini seharusnya aktif.

**Perintah persis untuk memverifikasi, begitu kunci tersedia** (isi
nilainya dari `docs/CREDENTIALS-NEEDED.md`, jangan pernah tempel di berkas
manapun di repo):

```bash
cd api

# PowerShell:
$env:GEMINI_API_KEY = "..."
$env:OPENWEATHER_API_KEY = "..."

# 1. Cek bentuk respons Gemini sungguhan
../ml/.venv/Scripts/python.exe -c "
import gemini
teks = gemini.minta_teks('Balas hanya JSON: {\"demand\": 50, \"narasi\": \"tes kalibrasi\"}')
print(repr(teks))
print(gemini.json_pertama(teks))
"

# 2. Cek bentuk respons OpenWeatherMap sungguhan
../ml/.venv/Scripts/python.exe -c "
import httpx, os
r = httpx.get('https://api.openweathermap.org/data/2.5/forecast',
              params={'lat': -7.98, 'lon': 112.63, 'appid': os.environ['OPENWEATHER_API_KEY'],
                      'units': 'metric', 'cnt': 8})
print(r.status_code)
print(r.json()['list'][0])
"
import weather
print(weather.ramalan_besok(-7.98, 112.63))

# 3. Panggil /health dan /forecast lewat server sungguhan, kunci di environment
../ml/.venv/Scripts/python.exe -m uvicorn main:app --port 8000
curl http://127.0.0.1:8000/health          # gemini_configured & weather_configured harus true
```

Kalau langkah 1/2 melempar `KeyError`/`IndexError` alih-alih mencetak
teks/dict yang masuk akal, bentuk responsnya sudah berubah — perbaiki
`gemini.py`/`weather.py` sebelum demo, jangan andalkan fallback diam-diam
untuk menutupinya.

### 6.3 Jebakan `.keras` berkas backslash — dan seberapa dekat ini nyaris lolos

Artefak model dari Tugas 5 (`lestar_lstm.keras`) **termuat sempurna di
Windows tapi gagal total di Linux**. Root cause, diverifikasi langsung
dengan `h5py`: format `.keras` v3 Keras 2.15 membangun path grup HDF5 lewat
`os.path.join(...)`, yang menghasilkan `\` di Windows (tempat model dilatih)
dan `/` di Linux (tempat container jalan). **48 dari 76 jalur** di berkas
lama berisi backslash literal (`layers\lstm\cell`, bukan `layers/lstm/cell`).

Efeknya di container: `/health` melaporkan `degraded` — bukan error yang
berisik, cuma satu kata di JSON. `.dockerignore` benar, model ikut ter-`COPY`
dengan byte yang benar, semua terlihat normal dari luar. **Tanpa ketahuan
ini, `/forecast` tetap membalas 200 dengan angka heuristik selamanya**,
diam-diam, sampai seseorang membandingkan angkanya dengan yang diharapkan
dan bertanya kenapa `source` selalu `heuristic` padahal model ada di image.

Perbaikannya **bukan retrain** — bobot yang sama disimpan ulang ke format
HDF5 legacy (`model.save(path, save_format='h5')`), yang selalu memakai
path `/` eksplisit, tidak lewat `os.path.join`. Diverifikasi independen:
12 array bobot **identik bit-demi-bit**, kedua kepala output memberi
prediksi persis sama (selisih maksimum `0.000e+00`) pada 200 input acak.
`scalers.json` dan `metrics.json` tidak berubah.

**Peringatan untuk siapa pun yang retrain model di Fase 2**: `ml/train_lstm.py`
sudah diperbaiki (`save_format='h5'` eksplisit, dengan komentar yang
menjelaskan sebabnya di baris penyimpanan) — tapi kalau baris itu pernah
"dirapikan" lagi jadi `model.save(path)` polos, bug ini kembali, dan tanda
satu-satunya adalah `/health` bilang `degraded` setelah deploy berikutnya.
Jangan asumsikan `.keras` yang termuat di Windows otomatis termuat di Linux
hanya karena versi library-nya sama — keduanya terbukti tidak cukup.

### 6.4 Yang tidak tercapai — dilaporkan apa adanya

- **Roti Gembong Blimbing** (bakery, `id 3d958ebe-7815-418a-89fa-4fc5ae2be55f`)
  mencapai hanya **1,716 kg/hari** surplus di `seed_sales_history.csv` — data
  90 hari yang sungguh ada di Supabase dan yang akan dilihat siapa pun yang
  query merchant ini (dihitung sendiri langsung dari berkas seed, bukan dari
  cetakan generator 120 hari, yang memberi angka sedikit lebih tinggi,
  1,796 kg — lihat bagian 6.1). Keduanya di bawah rentang riset 2–3 kg,
  bahkan di `faktor_kepercayaan` maksimum yang dikunci (1,30). Sebabnya:
  `base` (baseline porsi hariannya) terundi **80**, persis batas bawah
  rentang bakery `(80, 150)`, dan pada berat porsi bakery 0,08 kg, margin
  produksi-vs-demand di faktor maksimum hanya cukup untuk sekitar 1,8 kg
  surplus. Ini independen dari target yang diminta — melebarkan `FAKTOR_MAX`
  atau rentang kategori bakery untuk mengejar satu merchant ditolak karena
  keduanya berasal dari spesifikasi (`04-ai-pipeline.md` §3), bukan dari
  generator. **Rata-rata global tetap tercapai** (2,371 kg di seed 90 hari,
  2,381 kg di generator 120 hari — keduanya dalam rentang 2–3 kg) — hanya
  satu dari 30 merchant yang meleset secara individual, dan spesifikasi
  menuntut rata-rata, bukan setiap merchant.
- **Image Docker 1,52 GB, di atas target 1,5 GB.** Target itu adalah angka
  yang ditulis rencana proyek ini sendiri, **bukan batas Railway yang
  sungguh terukur**. Pemilik proyek memutuskan menerimanya apa adanya dan
  membuktikan batas sungguhannya lewat deploy, bukan menghabiskan ronde
  lagi memangkas image. Yang sudah dipangkas: **330 MB** — cache
  `__pycache__` di seluruh `site-packages` dan header C++ TensorFlow
  (`tensorflow/include`, tidak dipakai untuk inferensi murni-Python) —
  **keduanya dihapus di `RUN` yang sama dengan `pip install`**, bukan `RUN`
  terpisah, karena penghapusan di layer belakangan tidak mengecilkan image
  sama sekali (byte-nya sudah terkunci di layer sebelumnya). Perjalanan
  angkanya: 1,85 GB (build pertama) → 1,52 GB (setelah pemangkasan ini).
  `tensorboard` sengaja **tidak** dicopot (kecil, mencabutnya memicu warning
  di setiap startup); `libtensorflow_cc.so.2` sengaja tidak disentuh
  (load-bearing untuk `import tensorflow`). Kalau Railway ternyata menolak
  image di atas ukuran tertentu, opsi berikutnya adalah runtime inferensi
  yang lebih ringan (TFLite/ONNX) — perubahan `ml/`, di luar cakupan tugas
  ini.

### 6.5 Yang tidak dites — dicatat, bukan disembunyikan

- ~~`api/test_weather.py` cuma menguji dua kondisi...`~~ **Ditutup di
  konsolidasi akhir (item 3):** `api/test_weather.py` sekarang mengunci lima
  jalur kegagalan `ramalan_besok` (status bukan 200, body tanpa `list`,
  `list` kosong, entri tanpa `weather`, `weather[0]` tanpa `id` — semuanya
  tetap `None`, tidak pernah melempar), semua batas persis `kode_dari_owm`
  (199/200, 599/600, 699/700, 800..805, id di luar rentang, id negatif), dan
  `tersedia()` langsung dengan/tanpa kunci. Semuanya lewat monkeypatch
  `weather.httpx.get`, tidak ada satu pun yang menyentuh jaringan.
- Faktor confidence "riwayat < 14 hari" (`n_hari/14`) di `04-ai-pipeline.md`
  §10 **ada di kode** (`_confidence` di `api/forecast.py`) dan **diuji
  langsung sebagai unit test**, tapi **tidak bisa dipicu lewat `/forecast`
  sungguhan** — `hitung_forecast` menuntut persis `WINDOW=14` baris history
  sebelum masuk jalur LSTM sama sekali; kurang dari itu selalu jatuh ke
  heuristik (confidence tetap 0,45). Skenario "riwayat < 14 hari, tapi tetap
  lstm_only/lstm_gemini" yang didaftar §10 tak bisa dihasilkan oleh
  arsitektur endpoint saat ini.
- **Anggaran waktu.** Worst case satu panggilan `/forecast` (klien tidak
  kirim `weather_forecast`, model termuat, Gemini terkonfigurasi): OpenWeatherMap
  sampai 2,0 detik + Gemini sampai 3,0 detik = **5,0 detik**, sudah 1 detik di
  atas batas 4 detik `LestarConstants.timeoutForecast` di sisi Dart. Ini
  **laten, bukan aktif** hari ini — `lib/core/api/lestar_api.dart:83` selalu
  mengirim `weather_forecast` di setiap panggilan (`'weather_forecast': {'code':
  weatherCode}`, tanpa syarat), jadi jalur OpenWeatherMap di server tidak
  pernah menyala untuk klien Flutter manapun. Ini hanya menggigit pemanggil
  non-Flutter (mis. Postman, script uji) yang sengaja tidak mengirim field
  itu.

---

## 7. Definisi selesai — bukti per butir

| Butir | Status | Bukti |
|---|---|---|
| Generator: surplus rata-rata 2–3 kg/merchant/hari | **Tercapai** | 2,381 kg/merchant/hari dari cetakan generator penuh 120 hari (dicetak ulang sendiri saat menulis dokumen ini); 2,371 kg/merchant/hari kalau dihitung dari `seed_sales_history.csv` 90 hari yang sungguh ada di Supabase — lihat bagian 5 dan 6.1. Satu merchant meleset individual, lihat bagian 6.4 |
| Model terlatih, MAE demand < 15% dari rata-rata | **Tercapai** | 7,73% (`demand_mae_pct`), `target_met: true`, satu kali percobaan |
| `metrics.json` berisi angka akurasi nyata | **Tercapai** | lihat bagian 3, byte-identik di `ml/model/` dan `api/model/` |
| Lima endpoint merespons < 2 detik saat hangat | **Tercapai** | `/health` ~4,8ms · `/triage` ~8,2ms · `/pricing` ~24,5ms · `/esg-narrative` ~7,6ms · `/forecast` hangat ~62ms — angka Tugas 10, diukur reviewer di container yang baru dibangun bersih. Diukur ulang sendiri saat menulis dokumen ini di container yang sudah dipanaskan traffic lain: `/health` ~4,2ms dan `/forecast` hangat ~58ms konsisten dengan angka di atas; `/pricing` justru lebih cepat (~5–10ms, bukan 24,5ms) karena kondisi container berbeda, jadi angka Tugas 10 yang dipertahankan sebagai headline di sini karena diukur dalam kondisi terkontrol |
| Gemini dimatikan → `/forecast` tetap 200 OK dengan `source='lstm_only'` | **Tercapai** | diuji lewat `TestClient` dan lewat `uvicorn` sungguhan tanpa `GEMINI_API_KEY` |
| Model dihapus → `/health` `degraded`, `/forecast` tetap membalas | **Tercapai** | diuji dengan `.keras` dipindahkan sementara, dikembalikan byte-identik sesudahnya |
| `test_parity.py` lulus di Python | **Tercapai** | 18/18, dijalankan ulang saat menulis dokumen ini |
| Image Docker < 1,5 GB, terbukti bisa di-build lokal | **Tidak tercapai** | 1,52 GB, terukur ulang sendiri (`docker images lestar-api:local` masih ada di mesin ini). Lihat bagian 6.4 untuk apa yang sudah dicoba dan kenapa diterima apa adanya |
| `/health` merespons < 300 ms | **Tercapai** | ~4–5ms, jauh di bawah batas |

`api/` **86 passed**, `ml/` **14 passed** — dijalankan ulang penuh saat
menulis dokumen ini, bukan disalin dari laporan tugas manapun.

---

## 8. Berkas yang dibuat/diubah Agent C

```
ml/generate_synthetic.py     ml/train_lstm.py        ml/kalender.py
ml/merchants.py               ml/test_generate.py     ml/test_train.py
ml/requirements.txt           ml/data/seed_sales_history.csv  (train.csv tidak di-commit)
ml/model/metrics.json, ml/model/scalers.json  (di-commit; hanya ml/model/*.keras yang di-gitignore — salinan .keras yang dipakai container ada di api/model/)

api/main.py        api/schemas.py      api/constants.py    api/triage.py
api/pricing.py      api/forecast.py     api/model_runtime.py api/heuristik.py
api/gemini.py        api/weather.py      api/esg.py           api/Dockerfile
api/.dockerignore     api/requirements.txt  api/requirements-dev.txt  api/.env.example
api/model/lestar_lstm.keras (legacy HDF5, bukan .keras v3)  api/model/scalers.json
api/model/metrics.json
api/test_konstanta.py  api/test_parity.py  api/test_api.py  api/test_forecast.py
api/test_gemini.py     api/test_weather.py  api/test_esg.py  api/test_model_golden.py

docs/06-agent-briefs/C-HANDOFF.md   (berkas ini)
```

Tidak ada berkas di luar `ml/`, `api/`, dan `docs/06-agent-briefs/C-HANDOFF.md`
yang disentuh Agent C.
