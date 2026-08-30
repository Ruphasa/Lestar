# Agent C — ML & API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bangun lapis kecerdasan Lestar — generator data sintetis terkalibrasi, satu model LSTM dua kepala, dan FastAPI stateless empat endpoint dengan rantai fallback jujur — sampai pemilik proyek tinggal `railway up`.

**Architecture:** Dua paket Python terpisah dengan tanggung jawab berbeda. `ml/` adalah pipa offline: `generate_synthetic.py` melahirkan 30 merchant × 120 hari yang dikalibrasi sampai surplus rata-rata masuk 2–3 kg/merchant/hari, `train_lstm.py` melatih satu model dua kepala lalu mengekspor artefaknya ke `api/model/`. `api/` adalah layanan HTTP stateless tanpa koneksi database: rumus deterministik (`triage.py`, `pricing.py`) hidup sebagai fungsi murni yang diuji melawan angka hitungan tangan, sementara `/forecast` menempuh rantai `lstm_gemini → lstm_only → heuristic` dan selalu membalas 200. Model dimuat sekali di `lifespan`; kalau gagal, `/health` mengaku `degraded` dan endpoint turun ke heuristik sisi server.

**Tech Stack:** Python 3.11 · TensorFlow-CPU 2.15.1 + Keras 2.15 · NumPy < 2 · pandas · FastAPI · uvicorn[standard] · pydantic v2 · httpx (klien Gemini + OpenWeatherMap lewat REST, tanpa SDK) · pytest · Docker `python:3.11-slim`

---

## Global Constraints

Setiap tugas di bawah ini mewarisi seluruh daftar ini. Kalau satu tugas
bertabrakan dengan salah satu baris, baris ini yang menang.

### Kepemilikan berkas

- Hanya `ml/` dan `api/` yang boleh dibuat atau diubah. **Dilarang menyentuh**
  `lib/`, `supabase/`, `landing/`, `android/`, `test/`, `tool/`, `pubspec.yaml`.
- Dua pengecualian di luar dua folder itu, keduanya sudah disetujui di rencana ini:
  1. `.gitignore` — satu baris pengecualian untuk `ml/data/seed_sales_history.csv` (Tugas 4).
  2. `docs/06-agent-briefs/C-HANDOFF.md` — serah terima (Tugas 11).
- Migrasi/seed SQL tetap milik Agent A. Agent C hanya **menghasilkan CSV**,
  tidak pernah menulis ke Supabase.

### Konstanta bersama — wajib identik dengan `lib/core/constants.dart`

Sumber: `docs/02-data-model.md` §10. Salin nilainya persis, jangan menghitung ulang.

```
FAKTOR_CO2_PER_KG    = 0.25
GREEN_FEE            = 1000
AMBANG_TRIAGE_B2C    = 70
DISKON_MAKSIMUM      = 0.70
DISKON_DASAR         = 0.30
QR_MASA_BERLAKU_JAM  = 2

SHELF_LIFE_JAM   gorengan 6 · nasi_lauk 8 · roti 24 · kue 72 · seafood 4 · santan_susu 5 · minuman 12
SHELF_LIFE_DEFAULT_JAM = 8          # kategori di luar daftar — samakan dengan Dart
BERAT_PORSI_KG   gorengan 0.15 · nasi_lauk 0.35 · roti 0.08 · kue 0.05 · minuman 0.30 · lainnya 0.20
BERAT_PORSI_DEFAULT_KG = 0.20
```

### Pembulatan lintas bahasa

- **Jangan pernah memakai `round()` bawaan Python** untuk angka yang juga
  dihitung di Dart. Python membulatkan setengah ke genap, Dart menjauhi nol.
  `92.5` jadi `92` di Python dan `93` di Dart.
- Satu-satunya pembulatan yang sah untuk `triage.score` dan pembulatan Rp500 di
  `pricing`:

```python
import math

def round_half_away(x: float) -> int:
    """Bulatkan setengah menjauhi nol — sama dengan `double.round()` di Dart."""
    return int(math.floor(x + 0.5)) if x >= 0 else int(math.ceil(x - 0.5))
```

### Aturan keras layanan

- **Stateless.** Tidak ada koneksi database, tidak ada state antar request,
  tidak ada cache yang mengubah hasil.
- `/triage` dan `/pricing` **deterministik**, tanpa LLM menyentuh `score`,
  `route`, `diskon`, atau `harga`.
- Gemini gagal, timeout, kuota habis, atau keluar dari batas ±20% → turun ke
  `source='lstm_only'`. **Tidak pernah** melempar error ke klien.
- Model gagal dimuat → `/health` melaporkan `degraded`, `/forecast` tetap 200
  dengan `source='heuristic'`.
- Nilai sah `source`: `lstm_gemini` · `lstm_only` · `heuristic`. Tidak ada yang lain.
- Tidak ada angka hardcode yang menyamar sebagai keluaran AI.

### Kunci dan rahasia

- `GEMINI_API_KEY` dan `OPENWEATHER_API_KEY` hanya dibaca dari environment.
  **Dilarang** menulis nilainya ke berkas mana pun yang ter-commit, termasuk
  test, komentar, contoh, dan `C-HANDOFF.md`.
- `api/.env` sudah masuk `.gitignore`. `api/.env.example` berisi nama variabel
  dengan nilai kosong.

### Versi yang dikunci

- TensorFlow **wajib versi yang sama** di venv latih dan di
  `api/requirements.txt` — model `.keras` yang ditulis Keras 2.15 tidak dijamin
  bisa dimuat Keras 3. Pin `tensorflow-cpu==2.15.1` dan `numpy<2` di keduanya.
- Di Docker **wajib** `tensorflow-cpu`, bukan `tensorflow`. Paket penuh membawa
  dependensi CUDA ~2 GB dan menembus batas free tier Railway.
- Python 3.11 di mesin ini dipanggil `py -3.11` (bukan `python`; `python` di
  PATH adalah stub Microsoft Store yang gagal).

### Cara kerja

- Commit setiap potong yang lolos uji. Pesan commit **Bahasa Indonesia**,
  awalan `feat:` / `fix:` / `test:` / `docs:` / `chore:`.
- Keputusan yang tidak tertulis di dokumen: pilih yang paling sederhana, catat
  di `C-HANDOFF.md` §6, lanjut.
- Kalau target metrik tidak tercapai, **laporkan apa adanya**. Jangan naikkan
  klaim akurasi. Posisi proyek ini di depan juri adalah 70% yang jujur.

---

## Fakta yang sudah diverifikasi sebelum rencana ini ditulis

Jangan menguji ulang hal-hal ini, sudah dicek:

| Fakta | Nilai |
|---|---|
| Python 3.11 | `py -3.11` → 3.11.0 ✓ (`py -3.13` juga ada, **jangan dipakai** — TF 2.15 tidak punya wheel cp313) |
| Docker | 29.1.3 ✓ |
| pip jaringan | berfungsi ✓ |
| Merchant di Supabase | 30 baris, `category` ∈ {warung, kafe, bakery, katering} |
| `sales_history` saat ini | 2700 baris, `2026-05-31` … `2026-08-28`, avg porsi 71.10, **avg surplus 1.422 kg** (di bawah target 2–3 — inilah yang generator C perbaiki) |
| `weather_code` di DB | smallint 0..3 (0 cerah, 1 berawan, 2 mendung, 3 hujan) |
| `day_of_week` | **0 = Senin**, 6 = Minggu |

### Kontrak wire yang sudah dibekukan Agent B

Nama field ini datang dari `lib/core/api/lestar_api.dart` dan
`lib/core/api/api_models.dart`. **Salah satu huruf berbeda = app jatuh ke
fallback tanpa pesan error.**

`POST /forecast` — masuk:
```json
{"merchant_id":"uuid",
 "history":[{"date":"2026-08-15","portions_sold":72,"day_of_week":4,
             "is_holiday":false,"weather_code":0,"surplus_kg":2.4}],
 "target_date":"2026-08-30",
 "weather_forecast":{"code":0},
 "merchant_context":{"name":"Verde Kitchen","category":"kafe"}}
```
Catatan: Dart mengirim `history` **terbaru dulu**, contoh di
`04-ai-pipeline.md` §4 menaik. Server wajib mengurutkan sendiri menaik lalu
mengambil 14 baris terakhir. `merchant_context` boleh tidak ada.
`weather_forecast` boleh tidak ada.

`POST /forecast` — keluar (persis nama ini, dibaca `ForecastResult.fromJson`):
```json
{"demand_x":55,"surplus_probability_y":0.34,"surplus_volume_est_kg":2.8,
 "recommended_production":58,"confidence":0.72,"narrative":"…","source":"lstm_gemini"}
```

`POST /triage` — masuk `{"category","hours_since_cooked","ambient_temp"}`,
keluar `{"score","route","reason"}`.

`POST /pricing` — masuk
`{"original_price","hours_left","hours_total","qty_remaining","qty_total"}`,
keluar `{"diskon","harga"}` (Dart menerima alias `discount`/`price`, tapi
**pakai `diskon`/`harga`**).

`POST /esg-narrative` — masuk agregat yang minimal memuat
`total_weight_kg`, `total_co2_kg`, `total_revenue_recovered`, `meals_rescued`;
opsional `period_start`, `period_end`, `merchant_name`. Keluar
`{"narrative": "…"}`.

---

## File Structure

```
ml/
  requirements.txt              deps latih — tensorflow-cpu==2.15.1, numpy<2, pandas
  merchants.py                  30 merchant nyata: uuid, nama, kategori (dari Supabase)
  kalender.py                   libur nasional + jendela Ramadan 2026
  generate_synthetic.py         generator + kalibrasi surplus + cetak statistik
  train_lstm.py                 windowing, model dua kepala, latih, metrics.json, ekspor
  data/train.csv                120 hari — di-gitignore, regenerabel
  data/seed_sales_history.csv   90 hari pertama — DI-COMMIT, diserahkan ke Agent A
  model/lestar_lstm.keras       hasil latih (gitignored di ml/)
  model/scalers.json
  model/metrics.json

api/
  constants.py       konstanta bersama + round_half_away — cermin constants.dart
  schemas.py         seluruh model pydantic request/response
  triage.py          fungsi murni hitung_triage()
  pricing.py         fungsi murni hitung_pricing()
  heuristik.py       port Python dari FallbackEngine.forecast — dipakai saat degraded
  model_runtime.py   muat model + scalers + metrics sekali, status ok/degraded
  forecast.py        rakit fitur, inferensi LSTM, buffer, narasi template
  gemini.py          klien REST Gemini + penjaga batas ±20%
  weather.py         klien REST OpenWeatherMap → kode cuaca 0..3
  esg.py             narasi ESG (Gemini, template kalau gagal)
  main.py            FastAPI app, lifespan, CORS, 5 rute
  model/             salinan artefak untuk image Docker — DI-COMMIT
  requirements.txt   runtime saja, sekecil mungkin
  requirements-dev.txt  pytest + httpx untuk uji lokal
  Dockerfile
  .dockerignore
  .env.example
  test_parity.py     10 kasus triage + 3 kasus pricing, angka hitungan tangan
  test_api.py        uji endpoint, degraded, Gemini mati, latensi
  test_forecast.py   uji perakitan fitur + buffer + urutan history
```

**Kenapa `api/model/` di-commit sementara `ml/model/` di-gitignore:** konteks
build Docker adalah folder `api/`, jadi `Dockerfile` tidak bisa `COPY ../ml`.
Artefaknya kecil (~180 KB model + dua JSON), dan tanpa ini image tidak bisa
dibuild dari clone bersih. `ml/model/` tetap ignored karena itu keluaran kerja,
bukan artefak rilis.

---

## Task 1: Fondasi Python dan konstanta bersama

**Files:**
- Create: `ml/requirements.txt`
- Create: `api/requirements.txt`
- Create: `api/requirements-dev.txt`
- Create: `api/constants.py`
- Create: `api/.env.example`
- Test: `api/test_konstanta.py`

**Interfaces:**
- Consumes: tidak ada — tugas pertama.
- Produces:
  - `api.constants.round_half_away(x: float) -> int`
  - `api.constants.SHELF_LIFE_JAM: dict[str, int]`, `SHELF_LIFE_DEFAULT_JAM: int`
  - `api.constants.shelf_life(kategori: str) -> int`
  - `api.constants.BERAT_PORSI_KG: dict[str, float]`, `BERAT_PORSI_DEFAULT_KG: float`
  - `api.constants.berat_porsi(kategori: str) -> float`
  - `api.constants.FAKTOR_CO2_PER_KG`, `GREEN_FEE`, `AMBANG_TRIAGE_B2C`,
    `DISKON_MAKSIMUM`, `DISKON_DASAR`, `QR_MASA_BERLAKU_JAM`
  - `api.constants.KATEGORI_CEPAT_RUSAK: frozenset[str]` = `{'seafood','santan_susu'}`
  - `api.constants.DOW_MULTIPLIER: list[float]` (indeks 0 = Senin)
  - `api.constants.normalisasi_weather(code: int) -> float`

- [ ] **Step 1: Buat venv latih dan pasang dependensi**

Venv dipakai untuk **seluruh** pekerjaan Python di rencana ini, `ml/` maupun
`api/`. Alasan tidak memakai Python 3.11 global: di mesin ini terpasang
`numpy 2.2.6` yang membuat `import tensorflow` gagal dengan
`ImportError: numpy.core.umath failed to import` — TF 2.15 butuh numpy < 2.

```bash
py -3.11 -m venv ml/.venv
ml/.venv/Scripts/python.exe -m pip install --upgrade pip
```

`ml/requirements.txt`:
```
numpy<2
pandas>=2.0,<3
tensorflow-cpu==2.15.1
```

```bash
ml/.venv/Scripts/python.exe -m pip install -r ml/requirements.txt
```

Kalau `tensorflow-cpu==2.15.1` tidak punya wheel Windows, pasang
`tensorflow==2.15.0` di venv lokal saja dan **tetap** tulis
`tensorflow-cpu==2.15.1` di `api/requirements.txt` (Linux punya wheel-nya).
Catat penyimpangan ini untuk `C-HANDOFF.md` §6.

- [ ] **Step 2: Verifikasi TensorFlow hidup di venv**

```bash
ml/.venv/Scripts/python.exe -c "import tensorflow as tf, numpy as np; print(tf.__version__, np.__version__, tf.keras.__version__)"
```
Expected: `2.15.x 1.26.x 2.15.x` tanpa traceback.

- [ ] **Step 3: Tulis test konstanta yang gagal**

`api/test_konstanta.py`:
```python
"""Konstanta di sini wajib identik dengan lib/core/constants.dart.

Kalau salah satu berubah tanpa yang lain ikut, laporan ESG dan skor triage
akan berselisih antara app dan server tanpa ada yang menyadarinya sampai demo.
"""
from constants import (
    AMBANG_TRIAGE_B2C,
    BERAT_PORSI_DEFAULT_KG,
    DISKON_DASAR,
    DISKON_MAKSIMUM,
    DOW_MULTIPLIER,
    FAKTOR_CO2_PER_KG,
    GREEN_FEE,
    QR_MASA_BERLAKU_JAM,
    SHELF_LIFE_DEFAULT_JAM,
    berat_porsi,
    normalisasi_weather,
    round_half_away,
    shelf_life,
)


def test_angka_bisnis_sama_dengan_dart():
    assert FAKTOR_CO2_PER_KG == 0.25
    assert GREEN_FEE == 1000
    assert AMBANG_TRIAGE_B2C == 70
    assert DISKON_MAKSIMUM == 0.70
    assert DISKON_DASAR == 0.30
    assert QR_MASA_BERLAKU_JAM == 2


def test_shelf_life_lengkap_dan_default_delapan_jam():
    assert shelf_life('gorengan') == 6
    assert shelf_life('nasi_lauk') == 8
    assert shelf_life('roti') == 24
    assert shelf_life('kue') == 72
    assert shelf_life('seafood') == 4
    assert shelf_life('santan_susu') == 5
    assert shelf_life('minuman') == 12
    # Tidak tertulis di 02-data-model.md §10; Agent B memilih 8 jam
    # (sama dengan nasi_lauk). Kalau berbeda, triage kategori tak dikenal
    # berselisih antara app dan server.
    assert SHELF_LIFE_DEFAULT_JAM == 8
    assert shelf_life('kategori_yang_tidak_ada') == 8


def test_berat_porsi_lengkap_dan_default():
    assert berat_porsi('gorengan') == 0.15
    assert berat_porsi('nasi_lauk') == 0.35
    assert berat_porsi('roti') == 0.08
    assert berat_porsi('kue') == 0.05
    assert berat_porsi('minuman') == 0.30
    assert berat_porsi('lainnya') == 0.20
    assert BERAT_PORSI_DEFAULT_KG == 0.20
    assert berat_porsi('seafood') == 0.20


def test_dow_multiplier_indeks_nol_senin():
    assert DOW_MULTIPLIER == [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]


def test_round_half_away_mengikuti_dart_bukan_python():
    # Ini kasus yang menggigit: round() bawaan Python memberi 92.
    assert round_half_away(92.5) == 93
    assert round_half_away(0.5) == 1
    assert round_half_away(1.5) == 2
    assert round_half_away(2.5) == 3
    assert round_half_away(-0.5) == -1
    assert round_half_away(-2.5) == -3
    assert round_half_away(92.4) == 92
    assert round_half_away(92.6) == 93


def test_normalisasi_weather_menerima_dua_skala():
    # Skala sales_history (0..3) dari Agent A
    assert normalisasi_weather(0) == 0.0
    assert normalisasi_weather(3) == 1.0
    # Skala kode cuaca app (>= 60 berarti hujan, sesuai FallbackEngine Dart)
    assert normalisasi_weather(61) >= 0.7
    assert normalisasi_weather(800) == 0.0
    assert normalisasi_weather(500) >= 0.7
```

- [ ] **Step 4: Jalankan test, pastikan gagal**

```bash
ml/.venv/Scripts/python.exe -m pip install -r api/requirements-dev.txt
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_konstanta.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'constants'`.

`api/requirements-dev.txt`:
```
-r requirements.txt
pytest>=8
```

- [ ] **Step 5: Tulis `api/constants.py`**

```python
"""Konstanta bersama Lestar — sisi Python.

Nilai di berkas ini muncul di tiga tempat: Dart (`lib/core/constants.dart`),
Python (di sini), dan SQL (`berat_porsi_kg()` + `faktor_co2_per_kg()` di
`supabase/migrations/0005_intelligence.sql`). **Ketiganya wajib sama.** Kalau
salah satu diubah, ubah dua lainnya di commit yang sama.

Sumber angka: `docs/02-data-model.md` §10.
"""

import math

# ── Angka bisnis ────────────────────────────────────────────────────────
FAKTOR_CO2_PER_KG = 0.25
GREEN_FEE = 1000
AMBANG_TRIAGE_B2C = 70
DISKON_MAKSIMUM = 0.70
DISKON_DASAR = 0.30
QR_MASA_BERLAKU_JAM = 2

# ── Tabel kategori ──────────────────────────────────────────────────────
SHELF_LIFE_JAM: dict[str, int] = {
    'gorengan': 6,
    'nasi_lauk': 8,
    'roti': 24,
    'kue': 72,
    'seafood': 4,
    'santan_susu': 5,
    'minuman': 12,
}

# Tidak tertulis di 02-data-model.md §10, yang hanya menyebut default berat
# porsi. Agent B memilih 8 jam (nilai nasi_lauk, kategori paling umum) dan
# angka ini wajib sama di kedua sisi.
SHELF_LIFE_DEFAULT_JAM = 8

BERAT_PORSI_KG: dict[str, float] = {
    'gorengan': 0.15,
    'nasi_lauk': 0.35,
    'roti': 0.08,
    'kue': 0.05,
    'minuman': 0.30,
    'lainnya': 0.20,
}
BERAT_PORSI_DEFAULT_KG = 0.20

KATEGORI_CEPAT_RUSAK = frozenset({'seafood', 'santan_susu'})

# Pengali permintaan per hari. Indeks 0 = Senin, mengikuti konvensi
# sales_history.day_of_week — bukan datetime.weekday() Python yang juga 0=Senin
# tapi bukan DateTime.weekday Dart yang 1=Senin.
DOW_MULTIPLIER: list[float] = [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]


def shelf_life(kategori: str) -> int:
    return SHELF_LIFE_JAM.get(kategori, SHELF_LIFE_DEFAULT_JAM)


def berat_porsi(kategori: str) -> float:
    return BERAT_PORSI_KG.get(kategori, BERAT_PORSI_DEFAULT_KG)


# ── Pembulatan ──────────────────────────────────────────────────────────
def round_half_away(x: float) -> int:
    """Bulatkan setengah menjauhi nol — sama dengan `double.round()` di Dart.

    `round()` bawaan Python membulatkan setengah ke genap: 92.5 jadi 92,
    sementara Dart memberi 93. Selisih satu itu baru ketahuan saat demo
    sebagai skor triage yang tidak cocok antara layar dan server.
    """
    return int(math.floor(x + 0.5)) if x >= 0 else int(math.ceil(x - 0.5))


# ── Cuaca ───────────────────────────────────────────────────────────────
def normalisasi_weather(code: int | None) -> float:
    """Ubah kode cuaca jadi 0..1 (0 = cerah, 1 = hujan lebat).

    Dua skala masuk ke sistem ini dan keduanya harus dilayani:

    * `sales_history.weather_code` dari Agent A: smallint 0..3
      (0 cerah, 1 berawan, 2 mendung, 3 hujan).
    * kode cuaca dari app: `FallbackEngine` Dart memperlakukan >= 60 sebagai
      hujan, dan OpenWeatherMap memakai id kondisi 2xx–8xx.

    Angka <= 3 dibaca sebagai skala Agent A karena di skala OpenWeatherMap
    tidak ada id kondisi di bawah 200.
    """
    if code is None:
        return 0.0
    c = int(code)
    if 0 <= c <= 3:
        return c / 3.0
    if c >= 200 and c < 600:      # badai, gerimis, hujan
        return 0.9
    if c >= 600 and c < 700:      # salju — tidak relevan di Indonesia
        return 0.9
    if c >= 700 and c < 800:      # kabut, asap
        return 0.5
    if c == 800:                  # cerah
        return 0.0
    if c > 800:                   # 801..804 berawan sampai mendung
        return min((c - 800) / 4.0, 1.0)
    if c >= 60:                   # ambang hujan versi FallbackEngine Dart
        return 0.9
    return 0.3
```

- [ ] **Step 6: Tulis `api/requirements.txt` dan `api/.env.example`**

`api/requirements.txt` — runtime saja, setiap baris menambah ukuran image:
```
fastapi>=0.115,<1
uvicorn[standard]>=0.30,<1
pydantic>=2.7,<3
httpx>=0.27,<1
numpy<2
tensorflow-cpu==2.15.1
```

Catatan yang harus ditulis sebagai komentar di berkas itu: `google-generativeai`
sengaja **tidak** dipakai. Gemini dipanggil lewat REST dengan `httpx` yang sudah
ada — satu dependensi berat lebih sedikit di image, dan kontrol timeout langsung
di tangan kita.

`api/.env.example`:
```
# Salin ke api/.env dan isi. api/.env sudah masuk .gitignore.
# Nilai sungguhannya ada di docs/CREDENTIALS-NEEDED.md (tidak ter-commit).
GEMINI_API_KEY=
OPENWEATHER_API_KEY=
MODEL_PATH=./model/lestar_lstm.keras
ALLOWED_ORIGINS=*
```

- [ ] **Step 7: Jalankan test, pastikan lolos**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_konstanta.py -v
```
Expected: 6 passed.

- [ ] **Step 8: Commit**

```bash
git add ml/requirements.txt api/requirements.txt api/requirements-dev.txt api/constants.py api/.env.example api/test_konstanta.py
git commit -m "feat(api): konstanta bersama + pembulatan menjauhi nol"
```

---

## Task 2: Rumus deterministik dan uji paritas

Ini tugas yang paling menentukan apakah demo terlihat konsisten. Rumus di sini
adalah kembaran persis `FallbackEngine.triage` dan `FallbackEngine.pricing` di
`lib/core/fallback_engine.dart`.

**Files:**
- Create: `api/triage.py`
- Create: `api/pricing.py`
- Test: `api/test_parity.py`

**Interfaces:**
- Consumes: `api.constants` — `round_half_away`, `shelf_life`,
  `AMBANG_TRIAGE_B2C`, `KATEGORI_CEPAT_RUSAK`, `DISKON_DASAR`, `DISKON_MAKSIMUM`
- Produces:
  - `api.triage.hitung_triage(kategori: str, jam_sejak_masak: float, ambient_temp: float) -> dict`
    → `{'score': int, 'route': str, 'reason': str}`
  - `api.pricing.hitung_pricing(original_price: float, jam_tersisa: float, jam_total: float, qty_remaining: int, qty_total: int) -> dict`
    → `{'diskon': float, 'harga': float}`

- [ ] **Step 1: Tulis `api/test_parity.py` — 13 kasus, angka hitungan tangan**

Angka harapan di bawah ini **dihitung tangan dari rumus di
`04-ai-pipeline.md` §4**, bukan diambil dari keluaran Dart maupun Python.
Kalau diambil dari salah satunya, pengujian hanya membuktikan kode cocok
dengan dirinya sendiri. Sumber tabel: `docs/06-agent-briefs/B-HANDOFF.md` §12.

```python
"""Uji paritas rumus deterministik Python <-> Dart.

Rumus `triage` dan `pricing` ada dua kali dengan sengaja: di sini dan di
`lib/core/fallback_engine.dart`. Duplikasi itu yang membuat app tetap
berfungsi penuh tanpa server. Konsekuensinya, kalau satu diubah yang lain
wajib ikut diubah di commit yang sama.

Angka harapan di berkas ini dihitung tangan dari `docs/04-ai-pipeline.md` §4.
Versi Dart diuji melawan angka yang sama di `test/fallback_engine_test.dart`,
jadi keduanya diuji melawan spec — bukan melawan satu sama lain.
"""
import pytest

from pricing import hitung_pricing
from triage import hitung_triage

# kategori, jam sejak masak, suhu, skor, rute, asal angka
KASUS_TRIAGE = [
    ('roti',        6,  28, 85, 'b2c', '100 - 6/24*60'),
    ('gorengan',    3,  28, 70, 'b2c', '100 - 3/6*60, tepat di ambang'),
    ('gorengan',    4,  28, 60, 'b2b', '100 - 40'),
    ('nasi_lauk',   2,  28, 85, 'b2c', '100 - 2/8*60'),
    ('nasi_lauk',   2,  33, 70, 'b2c', '85 - 15 suhu'),
    ('kue',        12,  28, 90, 'b2c', '100 - 12/72*60'),
    ('seafood',     1,  28, 65, 'b2b', '100 - 15 - 20 kategori'),
    ('santan_susu', 1,  28, 68, 'b2b', '100 - 12 - 20'),
    ('minuman',     6,  31, 55, 'b2b', '100 - 30 - 15 suhu'),
    ('lainnya',     1,  28, 93, 'b2c', 'shelf default 8 jam: 100 - 7,5 = 92,5'),
]


@pytest.mark.parametrize('kategori,jam,suhu,skor,rute,asal', KASUS_TRIAGE)
def test_triage_paritas(kategori, jam, suhu, skor, rute, asal):
    hasil = hitung_triage(kategori, jam, suhu)
    assert hasil['score'] == skor, f'{kategori} {jam}j {suhu}C — {asal}'
    assert hasil['route'] == rute
    assert hasil['reason'].strip() != ''


def test_kasus_sepuluh_adalah_jebakan_pembulatan():
    """92,5 harus jadi 93, sama seperti Dart. round() bawaan memberi 92."""
    assert hitung_triage('lainnya', 1, 28)['score'] == 93


def test_triage_dijepit_nol_sampai_seratus():
    assert hitung_triage('seafood', 48, 35)['score'] == 0
    assert hitung_triage('kue', 0, 25)['score'] == 100


# harga asli, jam tersisa, jam total, sisa stok, stok awal, diskon, harga
KASUS_PRICING = [
    (25000, 0, 8, 10, 10, 0.70, 7500),   # 0,80 dijepit ke 0,70
    (20000, 8, 8,  0, 10, 0.30, 14000),
    (30000, 4, 8,  5, 10, 0.55, 13500),
]


@pytest.mark.parametrize('harga_asli,sisa,total,qty_sisa,qty_awal,diskon,harga', KASUS_PRICING)
def test_pricing_paritas(harga_asli, sisa, total, qty_sisa, qty_awal, diskon, harga):
    hasil = hitung_pricing(harga_asli, sisa, total, qty_sisa, qty_awal)
    assert hasil['diskon'] == pytest.approx(diskon, abs=1e-9)
    assert hasil['harga'] == harga


def test_pricing_selalu_kelipatan_lima_ratus():
    for harga_asli in (17300, 23999, 8100, 45500):
        hasil = hitung_pricing(harga_asli, 3, 8, 4, 10)
        assert hasil['harga'] % 500 == 0


def test_pricing_tidak_pernah_melebihi_diskon_maksimum():
    hasil = hitung_pricing(50000, 0, 8, 10, 10)
    assert hasil['diskon'] <= 0.70


def test_pricing_jam_total_nol_tidak_membagi_nol():
    """jam_total 0 berarti jendela sudah habis — perlakukan sebagai rasio penuh."""
    hasil = hitung_pricing(20000, 0, 0, 0, 10)
    assert hasil['diskon'] == pytest.approx(0.65, abs=1e-9)
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_parity.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'triage'`.

- [ ] **Step 3: Tulis `api/triage.py`**

```python
"""Triage keamanan pangan — deterministik, bukan LLM.

Keamanan pangan tidak boleh bergantung pada model probabilistik. `score` dan
`route` di sini tidak pernah disentuh Gemini; hanya `reason` yang boleh
diperkaya, dan itu pun terjadi di lapisan lain.

Kembaran persis `FallbackEngine.triage` di lib/core/fallback_engine.dart.
Rumus: docs/04-ai-pipeline.md §4.
"""

from constants import AMBANG_TRIAGE_B2C, KATEGORI_CEPAT_RUSAK, round_half_away, shelf_life


def hitung_triage(kategori: str, jam_sejak_masak: float, ambient_temp: float) -> dict:
    shelf = shelf_life(kategori)

    score = 100.0
    score -= (jam_sejak_masak / shelf) * 60
    if ambient_temp > 30:
        score -= 15
    if kategori in KATEGORI_CEPAT_RUSAK:
        score -= 20

    skor = max(0, min(100, round_half_away(score)))
    rute = 'b2c' if skor >= AMBANG_TRIAGE_B2C else 'b2b'

    return {'score': skor, 'route': rute, 'reason': _alasan(kategori, jam_sejak_masak, shelf, ambient_temp, skor)}


def _alasan(kategori: str, jam: float, shelf: int, suhu: float, skor: int) -> str:
    bagian = [f'Dimasak {round_half_away(jam)} jam lalu, kategori {kategori} tahan {shelf} jam.']
    bagian.append(
        f'Suhu {round_half_away(suhu)}°C di atas normal.' if suhu > 30 else 'Kondisi suhu normal.'
    )
    if kategori in KATEGORI_CEPAT_RUSAK:
        bagian.append('Kategori ini cepat rusak, skor diturunkan.')
    bagian.append(
        'Masih aman dijual ke konsumen.' if skor >= AMBANG_TRIAGE_B2C else 'Sebaiknya dialihkan ke jalur B2B.'
    )
    return ' '.join(bagian)
```

- [ ] **Step 4: Tulis `api/pricing.py`**

```python
"""Harga dinamis — deterministik, bukan LLM.

Kembaran persis `FallbackEngine.pricing` di lib/core/fallback_engine.dart.
Rumus: docs/04-ai-pipeline.md §4.

    rasio_waktu = 1 - (jam_tersisa / jam_total)
    rasio_stok  = qty_remaining / qty_total
    diskon = 0.30 + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
    diskon = min(diskon, 0.70)
    harga  = round(original_price * (1 - diskon) / 500) * 500

Batas 70% menepati janji "diskon 50-70%" di proposal. Pembulatan ke Rp500
supaya harga terlihat wajar, bukan Rp 31.847.
"""

from constants import DISKON_DASAR, DISKON_MAKSIMUM, round_half_away


def hitung_pricing(
    original_price: float,
    jam_tersisa: float,
    jam_total: float,
    qty_remaining: int,
    qty_total: int,
) -> dict:
    rasio_waktu = 1.0 if jam_total <= 0 else 1 - (jam_tersisa / jam_total)
    rasio_stok = 0.0 if qty_total <= 0 else qty_remaining / qty_total

    diskon = DISKON_DASAR + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
    diskon = min(diskon, DISKON_MAKSIMUM)

    harga = round_half_away(original_price * (1 - diskon) / 500) * 500

    return {'diskon': diskon, 'harga': float(harga)}
```

- [ ] **Step 5: Jalankan test, pastikan lolos**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_parity.py -v
```
Expected: 18 passed (10 parametrize triage + 2 triage tambahan + 3 parametrize
pricing + 3 pricing tambahan).

Kalau kasus ke-10 gagal dengan `92 != 93`, `round()` bawaan Python bocor masuk
ke suatu tempat. Cari `round(` tanpa `_half_away` di `api/`.

- [ ] **Step 6: Commit**

```bash
git add api/triage.py api/pricing.py api/test_parity.py
git commit -m "feat(api): rumus triage dan pricing deterministik + 13 uji paritas"
```

---

## Task 3: Skema, aplikasi FastAPI, dan dua endpoint deterministik

**Files:**
- Create: `api/schemas.py`
- Create: `api/main.py`
- Test: `api/test_api.py`

**Interfaces:**
- Consumes: `api.triage.hitung_triage`, `api.pricing.hitung_pricing`
- Produces:
  - `api.main.app` — instance FastAPI
  - `api.schemas.TriageRequest/TriageResponse`, `PricingRequest/PricingResponse`,
    `HistoryRow`, `ForecastRequest`, `ForecastResponse`, `EsgRequest`,
    `EsgResponse`, `HealthResponse`
  - `api.main.STATUS` — dict status runtime yang diisi `lifespan`

- [ ] **Step 1: Tulis test endpoint yang gagal**

`api/test_api.py`:
```python
"""Uji lapisan HTTP. Tidak menyentuh jaringan luar dan tidak butuh model."""
from fastapi.testclient import TestClient

from main import app

klien = TestClient(app)


def test_health_membalas_dan_menyebut_status_model():
    r = klien.get('/health')
    assert r.status_code == 200
    body = r.json()
    assert body['status'] in ('ok', 'degraded')
    assert 'model_loaded' in body
    assert 'version' in body


def test_triage_kontrak_field_sesuai_dart():
    r = klien.post('/triage', json={
        'category': 'roti', 'hours_since_cooked': 6, 'ambient_temp': 28,
    })
    assert r.status_code == 200
    body = r.json()
    assert body['score'] == 85
    assert body['route'] == 'b2c'
    assert isinstance(body['reason'], str) and body['reason']


def test_triage_kategori_asing_memakai_shelf_default():
    r = klien.post('/triage', json={
        'category': 'entah_apa', 'hours_since_cooked': 1, 'ambient_temp': 28,
    })
    assert r.json()['score'] == 93


def test_pricing_kontrak_field_sesuai_dart():
    r = klien.post('/pricing', json={
        'original_price': 30000, 'hours_left': 4, 'hours_total': 8,
        'qty_remaining': 5, 'qty_total': 10,
    })
    assert r.status_code == 200
    body = r.json()
    assert body['harga'] == 13500
    assert abs(body['diskon'] - 0.55) < 1e-9


def test_body_tidak_valid_dibalas_422_bukan_500():
    r = klien.post('/triage', json={'category': 'roti'})
    assert r.status_code == 422
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_api.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'main'`.

- [ ] **Step 3: Tulis `api/schemas.py`**

Nama field di sini bukan pilihan gaya — datang dari `lib/core/api/lestar_api.dart`.
Salah satu huruf berbeda dan app jatuh ke fallback tanpa pesan error.

```python
"""Kontrak wire empat endpoint.

Nama field mengikuti `lib/core/api/lestar_api.dart` dan
`lib/core/api/api_models.dart` persis. Jangan mengganti nama apa pun di sini
tanpa mengubah Dart di commit yang sama.
"""

from typing import Literal

from pydantic import BaseModel, Field

Source = Literal['lstm_gemini', 'lstm_only', 'heuristic']


class HistoryRow(BaseModel):
    date: str
    portions_sold: int
    day_of_week: int | None = None      # 0 = Senin
    is_holiday: bool = False
    weather_code: int | None = 0
    surplus_kg: float = 0.0


class WeatherForecast(BaseModel):
    code: int = 0
    temp: float | None = None


class MerchantContext(BaseModel):
    name: str | None = None
    category: str | None = None
    lat: float | None = None
    lng: float | None = None


class ForecastRequest(BaseModel):
    merchant_id: str
    history: list[HistoryRow] = Field(default_factory=list)
    target_date: str
    weather_forecast: WeatherForecast | None = None
    merchant_context: MerchantContext | None = None


class ForecastResponse(BaseModel):
    demand_x: int
    surplus_probability_y: float
    surplus_volume_est_kg: float | None
    recommended_production: int
    confidence: float
    narrative: str
    source: Source


class TriageRequest(BaseModel):
    category: str
    hours_since_cooked: float
    ambient_temp: float


class TriageResponse(BaseModel):
    score: int
    route: Literal['b2c', 'b2b']
    reason: str


class PricingRequest(BaseModel):
    original_price: float
    hours_left: float
    hours_total: float
    qty_remaining: int
    qty_total: int


class PricingResponse(BaseModel):
    diskon: float
    harga: float


class EsgRequest(BaseModel):
    total_weight_kg: float
    total_co2_kg: float
    total_revenue_recovered: float = 0.0
    meals_rescued: int = 0
    period_start: str | None = None
    period_end: str | None = None
    merchant_name: str | None = None


class EsgResponse(BaseModel):
    narrative: str
    source: Literal['gemini', 'template']


class HealthResponse(BaseModel):
    status: Literal['ok', 'degraded']
    model_loaded: bool
    model_path: str
    gemini_configured: bool
    weather_configured: bool
    metrics: dict | None = None
    version: str
```

- [ ] **Step 4: Tulis `api/main.py` — versi pertama, tanpa model**

`lifespan` sengaja sudah ada sejak sekarang walaupun isinya baru satu baris.
Tugas 6 mengisinya dengan pemuatan model; strukturnya tidak berubah lagi
setelah itu.

```python
"""Lestar API — stateless, tanpa koneksi database.

Flutter yang menulis hasil ke Supabase. Layanan ini hanya menghitung.
Kontrak endpoint: docs/04-ai-pipeline.md §4.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from pricing import hitung_pricing
from schemas import (
    HealthResponse,
    PricingRequest,
    PricingResponse,
    TriageRequest,
    TriageResponse,
)
from triage import hitung_triage

VERSI = '1.0'

# Status runtime, diisi sekali di lifespan dan hanya dibaca setelahnya.
# /health membacanya tanpa I/O supaya balasannya di bawah 300 ms.
STATUS: dict = {
    'model_loaded': False,
    'model_path': os.getenv('MODEL_PATH', './model/lestar_lstm.keras'),
    'metrics': None,
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Tugas 6 memuat model di sini, sekali saat startup — bukan per request.
    yield


app = FastAPI(title='Lestar API', version=VERSI, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in os.getenv('ALLOWED_ORIGINS', '*').split(',')],
    allow_methods=['*'],
    allow_headers=['*'],
)


@app.get('/health', response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status='ok' if STATUS['model_loaded'] else 'degraded',
        model_loaded=STATUS['model_loaded'],
        model_path=STATUS['model_path'],
        gemini_configured=bool(os.getenv('GEMINI_API_KEY')),
        weather_configured=bool(os.getenv('OPENWEATHER_API_KEY')),
        metrics=STATUS['metrics'],
        version=VERSI,
    )


@app.post('/triage', response_model=TriageResponse)
def triage(req: TriageRequest) -> TriageResponse:
    return TriageResponse(**hitung_triage(req.category, req.hours_since_cooked, req.ambient_temp))


@app.post('/pricing', response_model=PricingResponse)
def pricing(req: PricingRequest) -> PricingResponse:
    return PricingResponse(
        **hitung_pricing(
            req.original_price, req.hours_left, req.hours_total, req.qty_remaining, req.qty_total
        )
    )
```

- [ ] **Step 5: Jalankan test, pastikan lolos**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_api.py test_parity.py test_konstanta.py -v
```
Expected: semua lolos. `/health` melaporkan `degraded` — benar, modelnya memang
belum ada.

- [ ] **Step 6: Commit**

```bash
git add api/schemas.py api/main.py api/test_api.py
git commit -m "feat(api): kerangka FastAPI, /health, /triage, /pricing"
```

---

## Task 4: Generator sintetis terkalibrasi

Ini tugas yang angkanya akan ditanya juri. Target **surplus rata-rata 2–3 kg
per merchant per hari** dikutip dari riset Aksamala Foundation di Bab I
proposal, dan seluruh proyeksi ESG bertumpu padanya. Seed yang ada sekarang
(buatan Agent A sebagai penambal) memberi 1,422 kg — di bawah rentang. Inilah
yang diperbaiki di sini.

**Files:**
- Create: `ml/merchants.py`
- Create: `ml/kalender.py`
- Create: `ml/generate_synthetic.py`
- Modify: `.gitignore` (satu baris pengecualian)
- Test: `ml/test_generate.py`

**Interfaces:**
- Consumes: tidak ada dari tugas sebelumnya (paket `ml/` berdiri sendiri).
- Produces:
  - `ml.merchants.MERCHANTS: list[dict]` — 30 entri
    `{'id': str, 'nama': str, 'kategori': str}`
  - `ml.kalender.LIBUR_NASIONAL: set[datetime.date]`
  - `ml.kalender.is_ramadan(d: datetime.date) -> bool`
  - `ml.generate_synthetic.generate() -> pandas.DataFrame` dengan kolom
    `merchant_id, date, portions_sold, revenue, day_of_week, is_holiday, weather_code, surplus_kg`
  - Berkas `ml/data/train.csv` dan `ml/data/seed_sales_history.csv`

### Keputusan yang dikunci sebelum menulis kode

**Jendela tanggal.** 120 hari dimulai `2026-05-31`, berakhir `2026-09-27`.
90 hari pertama jatuh tepat di `2026-05-31` … `2026-08-28` — persis jendela
2700 baris yang sudah ada di Supabase menurut `A-HANDOFF.md` §3. Jadi
"90 hari pertama" di spec dan "jendela yang dipakai Agent A" adalah rentang
yang sama, tanpa perlu memilih salah satu. Konsekuensi yang harus ditulis di
handoff: 30 hari terakhir `train.csv` bertanggal setelah hari demo. Itu tidak
apa-apa — tanggal hanya jadi fitur pola, bukan klaim historis, dan barisnya
tidak pernah masuk database.

**Merchant nyata, bukan UUID karangan.** `A-HANDOFF.md` §3 menuntut
`merchant_id` ada di tabel `merchants`. 30 UUID di `ml/merchants.py` disalin
dari project sungguhan, lengkap dengan kategorinya, jadi
`seed_sales_history.csv` bisa langsung di-`insert ... on conflict` tanpa
pemetaan.

**Berat surplus per porsi.** `KATEGORI` di `04-ai-pipeline.md` §3 adalah
kategori *merchant* (warung/kafe/bakery/katering), sedangkan `BERAT_PORSI_KG`
di `02-data-model.md` §10 adalah kategori *listing*. Pemetaannya dipilih
lewat dagangan dominan: warung → `nasi_lauk` 0,35 · katering → `nasi_lauk`
0,35 · kafe → `lainnya` 0,20 · bakery → `roti` 0,08. Tidak ada konstanta baru
yang lahir; semuanya nilai §10 yang dipakai ulang.

**Kalibrasi otomatis.** `faktor_kepercayaan` tidak diundi lalu diharap benar.
Untuk setiap merchant, target surplus diundi seragam di 2,0–3,0 kg/hari, lalu
`faktor_kepercayaan` dicari dengan bagi dua (binary search) di rentang
0,90–1,30 sampai rata-rata surplus merchant itu menyentuh targetnya. Rentang
0,90–1,30 adalah batas yang tertulis di `04-ai-pipeline.md` §3 dan tidak boleh
dilebarkan; kalau ada merchant yang tidak bisa mencapai target di dalam
rentang itu, faktornya dijepit di batas dan kasusnya **dicetak sebagai
peringatan**, bukan disembunyikan.

**Determinisme.** Seluruh generator berjalan di atas
`numpy.random.default_rng(20260902)`. Menjalankan ulang menghasilkan berkas
yang identik — jadi hasil forecast tidak berubah antar gladi resik.

- [ ] **Step 1: Tulis `ml/merchants.py`**

30 baris ini disalin dari `select id, store_name, category from merchants` di
project `vhauffhtjckzmqomcgrl`.

```python
"""30 merchant nyata dari project Supabase Lestar.

Disalin dari `select id, store_name, category from merchants order by store_name`.
`merchant_id` di seed CSV wajib ada di tabel `merchants` (A-HANDOFF.md §3),
jadi UUID di sini bukan karangan.
"""

MERCHANTS: list[dict] = [
    {'id': 'c2eb2fe4-5966-4807-8579-b3ae972e171c', 'nama': 'Ayam Geprek Sawojajar', 'kategori': 'warung'},
    {'id': '8098243b-6252-474a-8b7b-048d44523c87', 'nama': 'Bakery Malang Manis', 'kategori': 'bakery'},
    {'id': '613e0ea4-31e8-4a6c-b860-e8817315eee1', 'nama': 'Bakery Sari Ijen', 'kategori': 'bakery'},
    {'id': 'feb3b93f-b163-4a00-9798-815a285003b2', 'nama': 'Bakso Malang Cak Har', 'kategori': 'warung'},
    {'id': '3a045379-34e3-4d46-b265-c912de04860a', 'nama': 'Dapur Mama Tumpang', 'kategori': 'katering'},
    {'id': '16434861-9af1-480f-b1d7-0dda3b0d2226', 'nama': 'Dapur Nusantara Blimbing', 'kategori': 'katering'},
    {'id': '67576246-c4ae-4875-baa7-3da595716252', 'nama': 'Donat Kentang Mbak Sri', 'kategori': 'bakery'},
    {'id': '8be26573-8c80-4383-a522-022a93c0f33b', 'nama': 'Gorengan Pak Slamet', 'kategori': 'warung'},
    {'id': 'f6d844b6-95fa-4933-bf27-70d108a17154', 'nama': 'Kafe Buku Ijen', 'kategori': 'kafe'},
    {'id': 'd57be047-c5c4-4ed7-948c-a63b05b7ac49', 'nama': 'Kafe Suhat Corner', 'kategori': 'kafe'},
    {'id': 'c4f68991-e71e-4c56-b01b-1641506b4ce2', 'nama': 'Kafe Taman Krida', 'kategori': 'kafe'},
    {'id': '75f85503-df45-46ce-b7f2-4cbadb1949af', 'nama': 'Katering Amanah Singosari', 'kategori': 'katering'},
    {'id': '7f36ef74-fea3-4084-af76-8183b23c2ed1', 'nama': 'Katering Barokah Lowokwaru', 'kategori': 'katering'},
    {'id': '242f8acd-70bd-40df-8dbd-6fa8fd2d74bd', 'nama': 'Katering Sedap Rasa', 'kategori': 'katering'},
    {'id': 'a8657a00-f7a0-4c70-ae03-da4c05687c3b', 'nama': 'Katering Sehat Griya Shanta', 'kategori': 'katering'},
    {'id': '979bf43d-028e-4269-8294-8e31769db8eb', 'nama': 'Kedai Kopi Klojen', 'kategori': 'kafe'},
    {'id': '08820f15-2c6b-4aab-9fb4-7664984d952e', 'nama': 'Kopi Bulan Sabit', 'kategori': 'kafe'},
    {'id': '5976bc40-907c-4214-a14d-c2392637674b', 'nama': 'Kopi Tugu Ijen', 'kategori': 'kafe'},
    {'id': '301e3721-e022-49fb-9985-86095ec8877a', 'nama': 'Martabak Manis Dieng', 'kategori': 'warung'},
    {'id': '613ef555-5f36-43de-abdf-dd8ebc52d1c5', 'nama': 'Pastry Corner Batu', 'kategori': 'bakery'},
    {'id': '2abf4576-d383-4e76-8609-51131597a45a', 'nama': 'RM Padang Sederhana Kawi', 'kategori': 'warung'},
    {'id': '34e8b816-e464-499a-b51c-a6f5bb86d493', 'nama': 'Roti Bakar Soehat', 'kategori': 'bakery'},
    {'id': '3d958ebe-7815-418a-89fa-4fc5ae2be55f', 'nama': 'Roti Gembong Blimbing', 'kategori': 'bakery'},
    {'id': '861a56af-aa52-4cda-8feb-649e2433e8bc', 'nama': 'Toko Kue Lestari', 'kategori': 'bakery'},
    {'id': '4104d7ec-c72e-4113-a8f4-73e1d11423b1', 'nama': 'Verde Kitchen', 'kategori': 'kafe'},
    {'id': '50538e17-de71-47ab-9704-a0c0be6d16af', 'nama': 'Warung Bu Tin', 'kategori': 'warung'},
    {'id': 'e4ee4ec9-d7d3-40f4-b858-98dd4c0a5bc9', 'nama': 'Warung Lalapan Bu Yuli', 'kategori': 'warung'},
    {'id': 'c7ee61aa-5471-403c-8a19-78c5a8c737a3', 'nama': 'Warung Pecel Kawi', 'kategori': 'warung'},
    {'id': 'a280b225-e9df-49c0-9e53-0e247b9a66b4', 'nama': 'Warung Rawon Nguling', 'kategori': 'warung'},
    {'id': 'a0541ed4-ef73-47e3-b60a-b02df5c260f3', 'nama': 'Warung Soto Ayam Lombok', 'kategori': 'warung'},
]
```

- [ ] **Step 2: Tulis `ml/kalender.py`**

```python
"""Hari libur nasional dan jendela Ramadan yang menyentuh rentang generator.

Tanggal Hijriah di bawah adalah perkiraan hisab. SKB tiga menteri bisa
menggeser satu hari, dan untuk data sintetis pergeseran itu tidak berpengaruh
pada pola yang dipelajari model.
"""

from datetime import date

LIBUR_NASIONAL: set[date] = {
    date(2026, 6, 1),    # Hari Lahir Pancasila
    date(2026, 6, 16),   # Tahun Baru Islam 1448 H (perkiraan)
    date(2026, 8, 17),   # Hari Kemerdekaan
    date(2026, 8, 25),   # Maulid Nabi Muhammad SAW (perkiraan)
}

# Ramadan 1447 H jatuh sekitar 17 Februari - 19 Maret 2026, seluruhnya di luar
# jendela generator (31 Mei - 27 September 2026). Pengalinya tetap ditulis dan
# diterapkan supaya generator benar kalau jendelanya digeser, tapi pada data
# yang dihasilkan sekarang faktor ini tidak pernah aktif. Ini dicatat di
# C-HANDOFF.md, bukan disembunyikan.
RAMADAN_MULAI = date(2026, 2, 17)
RAMADAN_SELESAI = date(2026, 3, 19)


def is_libur(d: date) -> bool:
    return d in LIBUR_NASIONAL


def is_ramadan(d: date) -> bool:
    return RAMADAN_MULAI <= d <= RAMADAN_SELESAI


def is_payday(d: date) -> bool:
    """Tanggal 25 sampai 5 bulan berikutnya."""
    return d.day >= 25 or d.day <= 5
```

- [ ] **Step 3: Tulis test generator yang gagal**

`ml/test_generate.py`:
```python
"""Uji generator. Ini tempat angka aneh ketahuan — bukan saat demo."""
from datetime import date

import pandas as pd

from generate_synthetic import HARI, MULAI, generate, ringkasan


def test_bentuk_dan_jendela_tanggal():
    df = generate()
    assert len(df) == 30 * HARI
    assert df['merchant_id'].nunique() == 30
    assert df['date'].min() == MULAI
    assert (df['date'].max() - MULAI).days == HARI - 1
    # Sembilan puluh hari pertama harus jatuh tepat di jendela Agent A.
    assert MULAI == date(2026, 5, 31)
    assert MULAI + pd.Timedelta(days=89) == pd.Timestamp(date(2026, 8, 28))


def test_kolom_persis_kontrak_agent_a():
    df = generate()
    assert list(df.columns) == [
        'merchant_id', 'date', 'portions_sold', 'revenue',
        'day_of_week', 'is_holiday', 'weather_code', 'surplus_kg',
    ]


def test_domain_setiap_kolom():
    df = generate()
    assert (df['portions_sold'] >= 0).all()
    assert (df['revenue'] >= 0).all()
    assert df['day_of_week'].between(0, 6).all()
    assert df['weather_code'].between(0, 3).all()
    assert (df['surplus_kg'] >= 0).all()
    assert df['is_holiday'].dtype == bool
    assert not df.duplicated(subset=['merchant_id', 'date']).any()


def test_day_of_week_nol_adalah_senin():
    df = generate()
    baris = df.iloc[0]
    assert baris['day_of_week'] == baris['date'].weekday()


def test_kalibrasi_surplus_masuk_rentang_riset():
    """2-3 kg/merchant/hari, dikutip dari riset Aksamala Foundation."""
    df = generate()
    assert 2.0 <= df['surplus_kg'].mean() <= 3.0


def test_setiap_merchant_juga_masuk_rentang():
    df = generate()
    per_merchant = df.groupby('merchant_id')['surplus_kg'].mean()
    assert per_merchant.between(2.0, 3.0).all(), per_merchant[~per_merchant.between(2.0, 3.0)]


def test_akhir_pekan_lebih_ramai_daripada_senin():
    df = generate()
    per_hari = df.groupby('day_of_week')['portions_sold'].mean()
    assert per_hari[5] > per_hari[0]      # Sabtu > Senin


def test_deterministik():
    a, b = generate(), generate()
    pd.testing.assert_frame_equal(a, b)


def test_ringkasan_mengembalikan_angka_bukan_none():
    r = ringkasan(generate())
    assert r['avg_porsi'] > 0
    assert 2.0 <= r['avg_surplus'] <= 3.0
    assert set(r['per_kategori']) == {'warung', 'kafe', 'bakery', 'katering'}
```

- [ ] **Step 4: Jalankan test, pastikan gagal**

```bash
cd ml && .venv/Scripts/python.exe -m pytest test_generate.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'generate_synthetic'`.

- [ ] **Step 5: Tulis `ml/generate_synthetic.py`**

```python
"""Generator data sintetis Lestar — 30 merchant x 120 hari.

Bukan angka acak. Dibangun dari pola operasional F&B Indonesia: pengali
harian, hari gajian, libur nasional, Ramadan, cuaca, derau gaussian.
Parameter: docs/04-ai-pipeline.md §3.

Kalibrasi wajib: surplus rata-rata jatuh di 2-3 kg/merchant/hari, sesuai riset
Aksamala Foundation yang dikutip di Bab I proposal. Seluruh proyeksi ESG
bertumpu pada angka itu, jadi `faktor_kepercayaan` per merchant dicari dengan
bagi dua sampai targetnya tersentuh — bukan diundi lalu diharap benar.

Jalankan:  ml/.venv/Scripts/python.exe ml/generate_synthetic.py
"""

from __future__ import annotations

import argparse
from datetime import date, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

from kalender import is_libur, is_payday, is_ramadan
from merchants import MERCHANTS

# ── Parameter (04-ai-pipeline.md §3) ────────────────────────────────────
KATEGORI: dict[str, tuple[int, int]] = {
    'warung': (40, 90),
    'kafe': (60, 120),
    'bakery': (80, 150),
    'katering': (100, 180),
}

WEEKLY = [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]   # indeks 0 = Senin
PAYDAY = 1.12
HOLIDAY = 1.25
RAMADAN = 0.40
HUJAN = 0.88
NOISE = 0.08

FAKTOR_MIN, FAKTOR_MAX = 0.90, 1.30

# Kategori merchant -> berat porsi dominannya, diambil dari BERAT_PORSI_KG
# di 02-data-model.md §10. Tidak ada konstanta baru yang lahir di sini.
BERAT_PER_PORSI = {
    'warung': 0.35,      # nasi_lauk
    'katering': 0.35,    # nasi_lauk
    'kafe': 0.20,        # lainnya
    'bakery': 0.08,      # roti
}

HARGA_PORSI = {'warung': 15000, 'kafe': 22000, 'bakery': 12000, 'katering': 25000}

MULAI = pd.Timestamp(date(2026, 5, 31))
HARI = 120
HARI_SEED = 90

SURPLUS_TARGET_MIN, SURPLUS_TARGET_MAX = 2.0, 3.0
SEED = 20260902

AKAR = Path(__file__).resolve().parent


def _tanggal() -> list[pd.Timestamp]:
    return [MULAI + timedelta(days=i) for i in range(HARI)]


def _cuaca(rng: np.random.Generator, n: int) -> np.ndarray:
    """0 cerah, 1 berawan, 2 mendung, 3 hujan — skala Agent A.

    Bobotnya condong ke cerah/berawan; Malang di Juni-September musim kemarau.
    """
    return rng.choice([0, 1, 2, 3], size=n, p=[0.42, 0.30, 0.16, 0.12])


def _demand_harian(base: float, tanggal: list[pd.Timestamp], cuaca: np.ndarray,
                   rng: np.random.Generator) -> np.ndarray:
    """Permintaan sungguhan hari itu, sebelum merchant memutuskan produksi."""
    out = np.empty(len(tanggal))
    derau = rng.normal(1.0, NOISE, len(tanggal))
    for i, ts in enumerate(tanggal):
        d = ts.date()
        f = WEEKLY[ts.weekday()]
        if is_payday(d):
            f *= PAYDAY
        if is_libur(d):
            f *= HOLIDAY
        if is_ramadan(d):
            f *= RAMADAN
        if cuaca[i] == 3:
            f *= HUJAN
        out[i] = base * f * derau[i]
    return np.clip(out, 0, None)


def _produksi(base: float, tanggal: list[pd.Timestamp], faktor: float) -> np.ndarray:
    """Merchant mengikuti pola mingguan, dikali kepercayaan dirinya sendiri."""
    return np.array([base * WEEKLY[ts.weekday()] * faktor for ts in tanggal])


def _rata_surplus_kg(base, tanggal, demand, faktor, berat) -> float:
    prod = _produksi(base, tanggal, faktor)
    return float(np.maximum(0.0, prod - demand).mean() * berat)


def _cari_faktor(base, tanggal, demand, berat, target) -> tuple[float, bool]:
    """Bagi dua di [0.90, 1.30] sampai rata-rata surplus menyentuh target.

    Mengembalikan (faktor, tercapai). `tercapai=False` berarti target berada di
    luar jangkauan rentang yang ditetapkan 04-ai-pipeline.md §3; faktornya
    dijepit di batas dan pemanggil wajib mencetak peringatan.
    """
    lo, hi = FAKTOR_MIN, FAKTOR_MAX
    if _rata_surplus_kg(base, tanggal, demand, hi, berat) < target:
        return hi, False
    if _rata_surplus_kg(base, tanggal, demand, lo, berat) > target:
        return lo, False
    for _ in range(60):
        mid = (lo + hi) / 2
        if _rata_surplus_kg(base, tanggal, demand, mid, berat) < target:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2, True


def generate() -> pd.DataFrame:
    rng = np.random.default_rng(SEED)
    tanggal = _tanggal()
    baris = []
    peringatan = []

    for m in MERCHANTS:
        lo, hi = KATEGORI[m['kategori']]
        base = float(rng.integers(lo, hi + 1))
        berat = BERAT_PER_PORSI[m['kategori']]
        harga = HARGA_PORSI[m['kategori']] * float(rng.uniform(0.9, 1.1))

        cuaca = _cuaca(rng, HARI)
        demand = _demand_harian(base, tanggal, cuaca, rng)

        target = float(rng.uniform(SURPLUS_TARGET_MIN + 0.15, SURPLUS_TARGET_MAX - 0.15))
        faktor, tercapai = _cari_faktor(base, tanggal, demand, berat, target)
        if not tercapai:
            peringatan.append((m['nama'], m['kategori'], round(faktor, 3), round(target, 2)))

        prod = _produksi(base, tanggal, faktor)
        terjual = np.minimum(prod, demand)
        surplus_kg = np.maximum(0.0, prod - demand) * berat

        for i, ts in enumerate(tanggal):
            porsi = int(round(float(terjual[i])))
            baris.append({
                'merchant_id': m['id'],
                'date': ts,
                'portions_sold': porsi,
                'revenue': float(round(porsi * harga, 0)),
                'day_of_week': ts.weekday(),          # 0 = Senin
                'is_holiday': is_libur(ts.date()),
                'weather_code': int(cuaca[i]),
                'surplus_kg': round(float(surplus_kg[i]), 3),
            })

    if peringatan:
        print('\n  PERINGATAN — merchant yang tidak mencapai target surplus di dalam '
              f'rentang faktor {FAKTOR_MIN}-{FAKTOR_MAX}:')
        for nama, kat, f, t in peringatan:
            print(f'    {nama:32s} {kat:9s} faktor={f} target={t} kg')

    return pd.DataFrame(baris).sort_values(['merchant_id', 'date']).reset_index(drop=True)


def ringkasan(df: pd.DataFrame) -> dict:
    kat = {m['id']: m['kategori'] for m in MERCHANTS}
    d = df.assign(kategori=df['merchant_id'].map(kat))
    per_kategori = (
        d.groupby('kategori')
        .agg(avg_porsi=('portions_sold', 'mean'), avg_surplus=('surplus_kg', 'mean'))
        .round(3)
        .to_dict('index')
    )
    return {
        'baris': len(df),
        'merchant': df['merchant_id'].nunique(),
        'hari': df['date'].nunique(),
        'avg_porsi': round(float(df['portions_sold'].mean()), 2),
        'avg_surplus': round(float(df['surplus_kg'].mean()), 3),
        'avg_revenue': round(float(df['revenue'].mean()), 0),
        'hari_libur': int(df['is_holiday'].sum() / df['merchant_id'].nunique()),
        'per_kategori': per_kategori,
    }


def cetak_ringkasan(r: dict) -> None:
    print('\n─── Ringkasan generator ' + '─' * 40)
    print(f"  baris            {r['baris']}  ({r['merchant']} merchant x {r['hari']} hari)")
    print(f"  rata porsi/hari  {r['avg_porsi']}")
    print(f"  rata revenue     Rp {r['avg_revenue']:,.0f}")
    print(f"  hari libur       {r['hari_libur']} dalam jendela")
    status = 'MASUK RENTANG' if 2.0 <= r['avg_surplus'] <= 3.0 else 'DI LUAR RENTANG — PERBAIKI'
    print(f"  rata surplus     {r['avg_surplus']} kg/merchant/hari   [{status} 2-3 kg]")
    print('\n  Sebaran per kategori merchant')
    print(f"  {'kategori':10s} {'avg porsi':>10s} {'avg surplus kg':>16s}")
    for k, v in sorted(r['per_kategori'].items()):
        print(f"  {k:10s} {v['avg_porsi']:>10.2f} {v['avg_surplus']:>16.3f}")
    print('─' * 63 + '\n')


def main() -> int:
    p = argparse.ArgumentParser(description='Generator data sintetis Lestar')
    p.add_argument('--out', default=str(AKAR / 'data'), help='folder keluaran')
    args = p.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    df = generate()
    r = ringkasan(df)
    cetak_ringkasan(r)

    train = df.copy()
    train['date'] = train['date'].dt.strftime('%Y-%m-%d')
    train.to_csv(out / 'train.csv', index=False)

    batas = MULAI + timedelta(days=HARI_SEED - 1)
    seed = df[df['date'] <= batas].copy()
    seed['date'] = seed['date'].dt.strftime('%Y-%m-%d')
    seed.to_csv(out / 'seed_sales_history.csv', index=False)

    print(f"  train.csv                {len(train)} baris  "
          f"{train['date'].min()} .. {train['date'].max()}")
    print(f"  seed_sales_history.csv   {len(seed)} baris  "
          f"{seed['date'].min()} .. {seed['date'].max()}  -> Agent A\n")

    if not (2.0 <= r['avg_surplus'] <= 3.0):
        print('  GAGAL: surplus rata-rata di luar 2-3 kg. Berkas tetap ditulis '
              'supaya bisa diperiksa, tapi jangan diserahkan ke Agent A.')
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
```

- [ ] **Step 6: Jalankan test, pastikan lolos**

```bash
cd ml && .venv/Scripts/python.exe -m pytest test_generate.py -v
```
Expected: 9 passed.

Kalau `test_setiap_merchant_juga_masuk_rentang` gagal untuk merchant bakery,
lihat peringatan yang dicetak `generate()`. Bakery punya berat porsi paling
ringan (0,08 kg) sehingga butuh `faktor_kepercayaan` paling tinggi. Kalau
faktornya menabrak 1,30, **jangan lebarkan rentangnya** — `04-ai-pipeline.md`
§3 yang menetapkannya. Yang boleh disesuaikan: turunkan target per merchant
untuk kategori itu ke sisi bawah rentang (2,0–2,3) dan catat di handoff.

- [ ] **Step 7: Hasilkan berkas dan periksa cetakan statistiknya**

```bash
cd ml && .venv/Scripts/python.exe generate_synthetic.py
```
Expected: exit code 0, `rata surplus` di antara 2,0 dan 3,0 dengan penanda
`[MASUK RENTANG 2-3 kg]`, `train.csv` 3600 baris `2026-05-31 .. 2026-09-27`,
`seed_sales_history.csv` 2700 baris `2026-05-31 .. 2026-08-28`.

Bandingkan `rata porsi/hari` dengan angka seed lama (71,10). Kalau melenceng
jauh — di bawah 45 atau di atas 110 — periksa `KATEGORI` sebelum lanjut.

- [ ] **Step 8: Buka pengecualian gitignore untuk seed CSV**

`ml/data/*.csv` ada di `.gitignore`, sementara Agent A butuh
`seed_sales_history.csv` lewat git. Tambahkan **satu baris** tepat di bawah
baris `ml/data/*.csv`:

```
ml/data/*.csv
!ml/data/seed_sales_history.csv
```

`train.csv` tetap diabaikan — ukurannya lebih besar dan bisa dihasilkan ulang
dengan satu perintah.

Verifikasi:
```bash
git check-ignore -v ml/data/train.csv ml/data/seed_sales_history.csv
```
Expected: hanya `train.csv` yang tercetak.

- [ ] **Step 9: Commit**

```bash
git add ml/merchants.py ml/kalender.py ml/generate_synthetic.py ml/test_generate.py .gitignore ml/data/seed_sales_history.csv
git commit -m "feat(ml): generator sintetis terkalibrasi 2-3 kg surplus per merchant"
```

---

## Task 5: Latih model LSTM dua kepala

**Files:**
- Create: `ml/train_lstm.py`
- Test: `ml/test_train.py`

**Interfaces:**
- Consumes: `ml/data/train.csv` dari Tugas 4
- Produces:
  - `ml.train_lstm.FITUR: int` = 11, `ml.train_lstm.WINDOW: int` = 14
  - `ml.train_lstm.bangun_window(df, scalers) -> tuple[np.ndarray, np.ndarray, np.ndarray]`
    → `(X shape (n,14,11), y_demand shape (n,), y_surplus shape (n,))`
  - `ml.train_lstm.hitung_scalers(df) -> dict` →
    `{'per_merchant': {id: {'porsi': float, 'surplus': float}}, 'global': {'porsi': float, 'surplus': float}}`
  - `ml.train_lstm.bangun_model() -> keras.Model`
  - Artefak: `ml/model/lestar_lstm.keras`, `ml/model/scalers.json`,
    `ml/model/metrics.json`, dan salinan ketiganya di `api/model/`

### Keputusan yang dikunci

**Split 80/20 kronologis, bukan acak.** Window yang bertetangga di waktu
berbagi 13 dari 14 harinya. Split acak menaruh kembaran itu di dua sisi dan
melahirkan MAE yang terlihat bagus tapi bocor. Untuk setiap merchant, 80%
window pertama masuk latih, 20% terakhir masuk validasi.

**`scale_factor` = rata-rata `portions_sold` merchant itu**, sesuai
`04-ai-pipeline.md` §2. Surplus dinormalisasi dengan rata-rata surplus merchant
itu, dijaga minimal 0,01 supaya tidak membagi nol. Keduanya disimpan di
`scalers.json` bersama satu entri `global` yang dipakai API kalau merchant-nya
tidak dikenal.

**MAE dilaporkan dalam porsi dan sebagai persen dari rata-rata.** Target
< 15%. Kalau tiga percobaan hyperparameter tidak mencapainya, tulis apa adanya
di `metrics.json` dengan `target_met: false` dan catat di handoff. **Jangan
naikkan klaimnya.**

- [ ] **Step 1: Tulis test yang gagal**

`ml/test_train.py`:
```python
"""Uji perakitan data latih. Melatih model sungguhan tidak diuji di sini —
itu terlalu lambat untuk test; buktinya ada di metrics.json.
"""
import numpy as np

from generate_synthetic import generate
from train_lstm import FITUR, WINDOW, bangun_model, bangun_window, hitung_scalers


def test_bentuk_window_dan_jumlah_fitur():
    df = generate()
    scalers = hitung_scalers(df)
    X, yd, ys = bangun_window(df, scalers)
    assert X.shape[1:] == (WINDOW, FITUR)
    assert X.shape[0] == yd.shape[0] == ys.shape[0]
    # 120 hari, window 14, target hari ke-15 -> 106 sampel per merchant
    assert X.shape[0] == 30 * (120 - WINDOW)


def test_one_hot_hari_tepat_satu_yang_menyala():
    df = generate()
    X, _, _ = bangun_window(df, hitung_scalers(df))
    onehot = X[:, :, 1:8]
    assert np.allclose(onehot.sum(axis=2), 1.0)


def test_fitur_ternormalisasi_tidak_meledak():
    df = generate()
    X, yd, ys = bangun_window(df, hitung_scalers(df))
    assert np.isfinite(X).all()
    assert X[:, :, 0].max() < 5.0        # porsi ternormalisasi
    assert X[:, :, 9].max() <= 1.0       # cuaca 0..1
    assert set(np.unique(ys)) <= {0.0, 1.0}
    assert np.isfinite(yd).all()


def test_scalers_punya_setiap_merchant_dan_entri_global():
    df = generate()
    s = hitung_scalers(df)
    assert len(s['per_merchant']) == 30
    assert s['global']['porsi'] > 0
    assert s['global']['surplus'] > 0
    for v in s['per_merchant'].values():
        assert v['porsi'] > 0 and v['surplus'] > 0


def test_model_punya_dua_kepala_bernama():
    m = bangun_model()
    assert m.input_shape == (None, WINDOW, FITUR)
    nama = [o.node.layer.name if hasattr(o, 'node') else o.name for o in m.outputs]
    assert any('demand' in str(n) for n in nama)
    assert any('surplus' in str(n) for n in nama)
    assert len(m.outputs) == 2
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd ml && .venv/Scripts/python.exe -m pytest test_train.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'train_lstm'`.

- [ ] **Step 3: Tulis `ml/train_lstm.py`**

```python
"""Latih model peramalan Lestar — satu model, dua kepala.

Arsitektur: docs/04-ai-pipeline.md §2.

    Input(14, 11) -> LSTM(64, return_sequences) -> LSTM(32) -> Dense(16, relu)
                  -> Dense(1, linear)  name='demand'    X
                  -> Dense(1, sigmoid) name='surplus'   Y

Satu model dua kepala, bukan dua model terpisah. X dan Y berbagi pola temporal
yang sama, jadi melatihnya bersama membuat keduanya saling menguatkan.

Jalankan:  ml/.venv/Scripts/python.exe ml/train_lstm.py
"""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

WINDOW = 14
FITUR = 11
SEED = 20260902

AKAR = Path(__file__).resolve().parent
DATA = AKAR / 'data' / 'train.csv'
MODEL_DIR = AKAR / 'model'
API_MODEL_DIR = AKAR.parent / 'api' / 'model'


def _norm_weather(code: int) -> float:
    """Skala Agent A: 0 cerah .. 3 hujan, dipetakan ke 0..1."""
    return float(min(max(int(code), 0), 3)) / 3.0


def hitung_scalers(df: pd.DataFrame) -> dict:
    """Rata-rata per merchant, dipakai ulang saat inferensi.

    Warung 40 porsi/hari dan katering 180 porsi/hari harus dipelajari sebagai
    pola yang sama bentuknya, bukan skala yang berbeda.
    """
    per = {}
    for mid, g in df.groupby('merchant_id'):
        per[str(mid)] = {
            'porsi': max(float(g['portions_sold'].mean()), 1.0),
            'surplus': max(float(g['surplus_kg'].mean()), 0.01),
        }
    return {
        'per_merchant': per,
        'global': {
            'porsi': max(float(df['portions_sold'].mean()), 1.0),
            'surplus': max(float(df['surplus_kg'].mean()), 0.01),
        },
    }


def _baris_fitur(r, sp: float, ss: float) -> list[float]:
    onehot = [0.0] * 7
    onehot[int(r['day_of_week'])] = 1.0
    return [
        float(r['portions_sold']) / sp,
        *onehot,
        1.0 if bool(r['is_holiday']) else 0.0,
        _norm_weather(r['weather_code']),
        float(r['surplus_kg']) / ss,
    ]


def bangun_window(df: pd.DataFrame, scalers: dict):
    """Window 14 hari -> target hari ke-15, dikelompokkan per merchant."""
    Xs, yd, ys = [], [], []
    for mid, g in df.groupby('merchant_id', sort=True):
        g = g.sort_values('date').reset_index(drop=True)
        s = scalers['per_merchant'].get(str(mid), scalers['global'])
        sp, ss = s['porsi'], s['surplus']
        fitur = np.array([_baris_fitur(r, sp, ss) for _, r in g.iterrows()], dtype='float32')
        for i in range(len(g) - WINDOW):
            Xs.append(fitur[i:i + WINDOW])
            target = g.iloc[i + WINDOW]
            yd.append(float(target['portions_sold']) / sp)
            ys.append(1.0 if float(target['surplus_kg']) > 0 else 0.0)
    return (
        np.asarray(Xs, dtype='float32'),
        np.asarray(yd, dtype='float32'),
        np.asarray(ys, dtype='float32'),
    )


def bangun_window_terpisah(df: pd.DataFrame, scalers: dict, rasio_latih: float = 0.8):
    """Split kronologis per merchant.

    Window yang bertetangga di waktu berbagi 13 dari 14 harinya. Split acak
    menaruh kembaran itu di dua sisi dan melahirkan MAE yang terlihat bagus
    tapi bocor.
    """
    latih, validasi = [], []
    for mid, g in df.groupby('merchant_id', sort=True):
        g = g.sort_values('date')
        batas = int(len(g) * rasio_latih)
        latih.append(g.iloc[:batas])
        validasi.append(g.iloc[max(batas - WINDOW, 0):])
    return (
        bangun_window(pd.concat(latih), scalers),
        bangun_window(pd.concat(validasi), scalers),
    )


def bangun_model(unit1: int = 64, unit2: int = 32, dense: int = 16) -> keras.Model:
    inputs = keras.Input(shape=(WINDOW, FITUR))
    x = layers.LSTM(unit1, return_sequences=True)(inputs)
    x = layers.LSTM(unit2)(x)
    x = layers.Dense(dense, activation='relu')(x)

    demand = layers.Dense(1, activation='linear', name='demand')(x)
    surplus = layers.Dense(1, activation='sigmoid', name='surplus')(x)

    model = keras.Model(inputs, [demand, surplus])
    model.compile(
        optimizer='adam',
        loss={'demand': 'mse', 'surplus': 'binary_crossentropy'},
        loss_weights={'demand': 1.0, 'surplus': 0.5},
        metrics={'demand': ['mae'], 'surplus': ['accuracy']},
    )
    return model


def main() -> int:
    p = argparse.ArgumentParser(description='Latih LSTM Lestar')
    p.add_argument('--epochs', type=int, default=120)
    p.add_argument('--batch', type=int, default=32)
    p.add_argument('--unit1', type=int, default=64)
    p.add_argument('--unit2', type=int, default=32)
    args = p.parse_args()

    keras.utils.set_random_seed(SEED)
    tf.config.experimental.enable_op_determinism()

    if not DATA.exists():
        print(f'GAGAL: {DATA} tidak ada. Jalankan generate_synthetic.py dulu.')
        return 1

    df = pd.read_csv(DATA, parse_dates=['date'])
    scalers = hitung_scalers(df)
    (Xtr, ydtr, ystr), (Xva, ydva, ysva) = bangun_window_terpisah(df, scalers)
    print(f'  window latih {Xtr.shape}  validasi {Xva.shape}')

    model = bangun_model(args.unit1, args.unit2)
    hist = model.fit(
        Xtr, {'demand': ydtr, 'surplus': ystr},
        validation_data=(Xva, {'demand': ydva, 'surplus': ysva}),
        epochs=args.epochs,
        batch_size=args.batch,
        callbacks=[keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=8, restore_best_weights=True)],
        verbose=2,
    )

    # MAE dikembalikan ke satuan porsi. Nilai ternormalisasi tidak berarti apa-apa
    # bagi merchant maupun juri.
    pd_norm, ps_norm = model.predict(Xva, verbose=0)

    # Skala per sampel dirakit ulang dengan urutan yang sama seperti
    # bangun_window_terpisah menyusunnya.
    skala_list = []
    for mid, g in df.groupby('merchant_id', sort=True):
        g = g.sort_values('date')
        batas = int(len(g) * 0.8)
        potong = g.iloc[max(batas - WINDOW, 0):]
        n = max(len(potong) - WINDOW, 0)
        skala_list.extend([scalers['per_merchant'][str(mid)]['porsi']] * n)
    skala = np.asarray(skala_list, dtype='float32')

    demand_pred = pd_norm.reshape(-1) * skala
    demand_asli = ydva * skala
    mae = float(np.mean(np.abs(demand_pred - demand_asli)))
    rata = float(demand_asli.mean())
    mae_pct = mae / rata if rata else 1.0

    surplus_pred = (ps_norm.reshape(-1) >= 0.5).astype('float32')
    surplus_acc = float((surplus_pred == ysva).mean())

    metrics = {
        'trained_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
        'n_merchant': int(df['merchant_id'].nunique()),
        'n_hari': int(df['date'].nunique()),
        'n_window_latih': int(Xtr.shape[0]),
        'n_window_validasi': int(Xva.shape[0]),
        'epoch_berjalan': len(hist.history['loss']),
        'demand_mae_porsi': round(mae, 3),
        'demand_mae_pct': round(mae_pct, 4),
        'demand_akurasi': round(1 - mae_pct, 4),
        'rata_porsi_validasi': round(rata, 2),
        'surplus_akurasi': round(surplus_acc, 4),
        'target_mae_pct': 0.15,
        'target_met': bool(mae_pct < 0.15),
        'klaim_publik': 0.70,
        'catatan': (
            'demand_akurasi = 1 - MAE/rata-rata pada 20% window terakhir tiap merchant '
            '(split kronologis, bukan acak). klaim_publik sengaja ditahan di 0,70 sesuai '
            'docs/04-ai-pipeline.md §3 — angka yang bisa dipertanggungjawabkan lebih '
            'meyakinkan daripada angka tinggi yang tidak bisa dibuktikan. '
            'Model dilatih pada data sintetis Fase 1.'
        ),
    }

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    API_MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model.save(MODEL_DIR / 'lestar_lstm.keras')
    (MODEL_DIR / 'scalers.json').write_text(json.dumps(scalers, indent=2), encoding='utf-8')
    (MODEL_DIR / 'metrics.json').write_text(json.dumps(metrics, indent=2), encoding='utf-8')

    # Konteks build Docker adalah folder api/, jadi Dockerfile tidak bisa
    # COPY ../ml. Artefaknya disalin ke sana dan ikut ter-commit.
    for nama in ('lestar_lstm.keras', 'scalers.json', 'metrics.json'):
        shutil.copy2(MODEL_DIR / nama, API_MODEL_DIR / nama)

    ukuran_kb = (MODEL_DIR / 'lestar_lstm.keras').stat().st_size / 1024
    print('\n─── Metrik model ' + '─' * 45)
    print(f"  epoch berjalan     {metrics['epoch_berjalan']}")
    print(f"  MAE demand         {metrics['demand_mae_porsi']} porsi "
          f"({metrics['demand_mae_pct'] * 100:.1f}% dari rata-rata "
          f"{metrics['rata_porsi_validasi']})")
    print(f"  akurasi surplus    {metrics['surplus_akurasi'] * 100:.1f}%")
    print(f"  ukuran model       {ukuran_kb:.0f} KB")
    if metrics['target_met']:
        print('  target < 15%       TERCAPAI')
    else:
        print('  target < 15%       TIDAK TERCAPAI — laporkan apa adanya, '
              'jangan naikkan klaim akurasi')
    print('─' * 62 + '\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
```

Catatan implementasi: urutan `skala_list` **wajib** mengikuti urutan yang
dipakai `bangun_window_terpisah` — `groupby('merchant_id', sort=True)` lalu
`sort_values('date')`. Kalau urutannya bergeser, MAE yang dilaporkan salah
tanpa ada yang gagal.

- [ ] **Step 4: Jalankan test, pastikan lolos**

```bash
cd ml && .venv/Scripts/python.exe -m pytest test_train.py -v
```
Expected: 5 passed.

- [ ] **Step 5: Latih model**

```bash
cd ml && .venv/Scripts/python.exe train_lstm.py
```
Expected: selesai di bawah ~5 menit di CPU, mencetak blok metrik, menulis
`ml/model/` dan `api/model/` masing-masing tiga berkas.

Kalau `target_met` false, ini **tiga** percobaan hyperparameter yang boleh
dilakukan, tidak lebih:
1. `--epochs 200 --batch 16`
2. `--unit1 96 --unit2 48`
3. `--batch 64 --epochs 200`

Setelah percobaan ketiga, ambil hasil terbaik dan **tulis apa adanya**.
`metrics.json` tetap merekam `target_met: false` dan `C-HANDOFF.md` §3
menyebutkannya terus terang. Jangan mengubah definisi metrik supaya angkanya
terlihat lebih bagus.

- [ ] **Step 6: Periksa artefak**

```bash
ls -l ml/model api/model && cat ml/model/metrics.json
```
Expected: `lestar_lstm.keras` ada di keduanya dengan ukuran yang sama
(~180–400 KB), `metrics.json` memuat `demand_mae_pct` dan `target_met`.

- [ ] **Step 7: Commit**

```bash
git add ml/train_lstm.py ml/test_train.py api/model/
git commit -m "feat(ml): latih LSTM dua kepala + ekspor artefak ke api/model"
```

---

## Task 6: Runtime model, heuristik server, dan `/forecast`

**Files:**
- Create: `api/model_runtime.py`
- Create: `api/heuristik.py`
- Create: `api/forecast.py`
- Modify: `api/main.py` (isi `lifespan`, tambah rute `/forecast`)
- Test: `api/test_forecast.py`

**Interfaces:**
- Consumes: `api.constants` (`DOW_MULTIPLIER`, `normalisasi_weather`,
  `BERAT_PORSI_DEFAULT_KG`, `round_half_away`), `api.schemas.ForecastRequest`,
  artefak di `api/model/`
- Produces:
  - `api.model_runtime.Runtime` dengan atribut `model`, `scalers`, `metrics`,
    `loaded: bool`, `path: str`; fungsi `api.model_runtime.muat(path: str) -> Runtime`
  - `api.heuristik.forecast_heuristik(history: list[dict], target_date: date, weather_code: int) -> dict`
  - `api.forecast.rakit_window(history: list[dict], scalers: dict) -> tuple[np.ndarray, float]`
  - `api.forecast.hitung_forecast(req, runtime) -> dict` dengan kunci persis
    `demand_x, surplus_probability_y, surplus_volume_est_kg,
    recommended_production, confidence, narrative, source`
  - `api.forecast.rekomendasi_produksi(demand_x: float, surplus_y: float) -> int`

### Keputusan yang dikunci

**Urutan `history`.** Dart mengirim terbaru dulu, contoh spec menaik. Server
mengurutkan sendiri berdasarkan `date` menaik lalu mengambil 14 baris terakhir.
Kedua arah dilayani tanpa klien perlu tahu.

**`scale_factor` saat inferensi diambil dari request, bukan dari
`scalers.json`.** Layanan ini stateless dan merchant bisa saja belum pernah
dilihat model. Rata-rata `portions_sold` dari 14 baris yang dikirim adalah
skala yang benar untuk merchant itu hari ini. `scalers.json` tetap dimuat dan
dipakai untuk satu hal: entri `global` sebagai jaring pengaman kalau history
kosong atau nol semua.

**`surplus_volume_est_kg = demand_x × y × 0.20`** — rumus yang sama dengan
`FallbackEngine.forecast` di Dart, memakai `BERAT_PORSI_DEFAULT_KG`. Angka
server dan angka app jadi setara, bukan dua estimasi yang berbeda diam-diam.

**`confidence` diturunkan dari metrik nyata**, bukan angka enak.
`confidence = clamp(metrics['demand_akurasi'], 0.30, 0.95)` saat model hidup;
`0.45` saat jatuh ke heuristik, sama persis dengan Dart. Tidak ada nilai
hardcode yang menyamar sebagai keluaran AI.

**Model tidak ada → `source='heuristic'`.** Enum `forecast_source` hanya punya
tiga nilai, dan `lstm_only` akan berbohong soal asal angka. `heuristic` di
sini berarti "tidak ada model yang menghasilkan angka ini", bukan "dihitung di
dalam APK". Catat perbedaan makna itu di handoff.

- [ ] **Step 1: Tulis test yang gagal**

`api/test_forecast.py`:
```python
"""Uji perakitan fitur, heuristik server, dan rute /forecast."""
from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient

import main
from forecast import rekomendasi_produksi
from heuristik import forecast_heuristik


def _history(n=14, mulai=date(2026, 8, 15), porsi=70):
    return [
        {
            'date': (mulai + timedelta(days=i)).isoformat(),
            'portions_sold': porsi + (i % 5),
            'day_of_week': (mulai + timedelta(days=i)).weekday(),
            'is_holiday': False,
            'weather_code': 0,
            'surplus_kg': 2.4,
        }
        for i in range(n)
    ]


def test_rekomendasi_produksi_memakai_ceil_dan_buffer():
    # buffer = 0.15 * (1 - y); y = 0 -> ceil(100 * 1.15) = 115
    assert rekomendasi_produksi(100.0, 0.0) == 115
    # y = 1 -> tidak ada buffer -> ceil(100) = 100
    assert rekomendasi_produksi(100.0, 1.0) == 100
    # pembulatan ke atas, bukan ke terdekat
    assert rekomendasi_produksi(10.0, 0.5) == 11


def test_heuristik_selalu_membalas_walau_history_kosong():
    h = forecast_heuristik([], date(2026, 9, 1), 0)
    assert h['demand_x'] == 0
    assert h['source'] == 'heuristic'
    assert h['confidence'] == 0.45
    assert h['narrative']


def test_heuristik_cocok_dengan_fallback_engine_dart():
    """avg7 x pengali hari x cuaca, dengan avg7 dari 7 baris terbaru."""
    hist = _history(porsi=70)               # 70..74, tujuh terbaru = 72..74,70..
    hasil = forecast_heuristik(hist, date(2026, 8, 29), 0)   # Sabtu -> 1.35
    assert hasil['source'] == 'heuristic'
    assert hasil['demand_x'] > 80           # 1.35 x ~72
    assert 0.0 <= hasil['surplus_probability_y'] <= 1.0


def test_heuristik_hujan_menurunkan_permintaan():
    hist = _history()
    cerah = forecast_heuristik(hist, date(2026, 8, 29), 0)
    hujan = forecast_heuristik(hist, date(2026, 8, 29), 61)
    assert hujan['demand_x'] < cerah['demand_x']


def test_forecast_membalas_200_dan_kontrak_field_lengkap():
    klien = TestClient(main.app)
    r = klien.post('/forecast', json={
        'merchant_id': '4104d7ec-c72e-4113-a8f4-73e1d11423b1',
        'history': _history(),
        'target_date': '2026-08-29',
        'weather_forecast': {'code': 0},
        'merchant_context': {'name': 'Verde Kitchen', 'category': 'kafe'},
    })
    assert r.status_code == 200
    b = r.json()
    for k in ('demand_x', 'surplus_probability_y', 'surplus_volume_est_kg',
              'recommended_production', 'confidence', 'narrative', 'source'):
        assert k in b
    assert b['source'] in ('lstm_gemini', 'lstm_only', 'heuristic')
    assert isinstance(b['demand_x'], int)
    assert 0.0 <= b['surplus_probability_y'] <= 1.0
    assert b['recommended_production'] >= 0


def test_forecast_menerima_history_terbaru_dulu():
    """Dart mengirim terbaru dulu. Hasilnya harus sama dengan urutan menaik."""
    klien = TestClient(main.app)
    naik = _history()
    turun = list(reversed(naik))
    body = {
        'merchant_id': 'x', 'target_date': '2026-08-29',
        'weather_forecast': {'code': 0},
    }
    a = klien.post('/forecast', json={**body, 'history': naik}).json()
    b = klien.post('/forecast', json={**body, 'history': turun}).json()
    assert a['demand_x'] == b['demand_x']


def test_forecast_history_kurang_dari_empat_belas_tetap_200():
    klien = TestClient(main.app)
    r = klien.post('/forecast', json={
        'merchant_id': 'x', 'history': _history(n=3), 'target_date': '2026-08-29',
    })
    assert r.status_code == 200
    assert r.json()['source'] == 'heuristic'


def test_model_gagal_dimuat_membuat_health_degraded(monkeypatch):
    import model_runtime
    rt = model_runtime.muat('./model/tidak-ada.keras')
    assert rt.loaded is False
    monkeypatch.setitem(main.STATUS, 'model_loaded', False)
    klien = TestClient(main.app)
    assert klien.get('/health').json()['status'] == 'degraded'
    r = klien.post('/forecast', json={
        'merchant_id': 'x', 'history': _history(), 'target_date': '2026-08-29',
    })
    assert r.status_code == 200
    assert r.json()['source'] == 'heuristic'
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_forecast.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'forecast'`.

- [ ] **Step 3: Tulis `api/model_runtime.py`**

```python
"""Pemuatan model sekali di startup.

Model dimuat lewat `lifespan`, bukan per request — memuat ulang `.keras` di
setiap panggilan menambah detik yang langsung terlihat saat demo.

Kegagalan memuat bukan alasan untuk mati. Runtime yang gagal tetap sah;
`loaded=False` membuat /health mengaku `degraded` dan /forecast turun ke
heuristik sisi server.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Runtime:
    path: str
    loaded: bool = False
    model: object | None = None
    scalers: dict = field(default_factory=dict)
    metrics: dict | None = None
    error: str | None = None


def _baca_json(p: Path) -> dict | None:
    try:
        return json.loads(p.read_text(encoding='utf-8'))
    except Exception:
        return None


def muat(path: str) -> Runtime:
    rt = Runtime(path=path)
    berkas = Path(path)
    folder = berkas.parent

    rt.scalers = _baca_json(folder / 'scalers.json') or {'per_merchant': {}, 'global': {'porsi': 70.0, 'surplus': 2.5}}
    rt.metrics = _baca_json(folder / 'metrics.json')

    if not berkas.exists():
        rt.error = f'berkas model tidak ada: {path}'
        return rt

    try:
        from tensorflow import keras     # impor di sini supaya kegagalan TF tidak mematikan proses
        rt.model = keras.models.load_model(berkas, compile=False)
        rt.loaded = True
    except Exception as e:               # noqa: BLE001 — apa pun yang gagal, layanan tetap hidup
        rt.error = f'{type(e).__name__}: {e}'
    return rt
```

- [ ] **Step 4: Tulis `api/heuristik.py`**

Port persis dari `FallbackEngine.forecast` di `lib/core/fallback_engine.dart`.
Kalau salah satu diubah, yang lain wajib ikut.

```python
"""Heuristik sisi server — dipakai saat model tidak bisa dimuat.

Port persis dari `FallbackEngine.forecast` di lib/core/fallback_engine.dart,
supaya angka server dan angka app tidak berselisih saat keduanya jatuh ke
lapisan yang sama. Kalau salah satu diubah, yang lain wajib ikut diubah.

Kasar, tapi masuk akal — dan tidak pernah gagal. `confidence` sengaja rendah
(0.45) supaya UI menampilkan keyakinan yang jujur.
"""

from __future__ import annotations

import math
from datetime import date

from constants import BERAT_PORSI_DEFAULT_KG, DOW_MULTIPLIER, round_half_away

NAMA_HARI = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']


def rekomendasi_produksi(demand_x: float, surplus_y: float) -> int:
    """ceil(demand_x x (1 + 0.15 x (1 - y))).

    Inti Buffer Intelligence: semakin rendah probabilitas surplus, semakin
    besar buffer yang aman ditambahkan — merchant berani memproduksi lebih
    karena setiap surplus punya jalur keluar.
    """
    return int(math.ceil(demand_x * (1 + 0.15 * (1 - surplus_y))))


def forecast_heuristik(history: list[dict], target_date: date, weather_code: int) -> dict:
    if not history:
        return {
            'demand_x': 0,
            'surplus_probability_y': 0.0,
            'surplus_volume_est_kg': 0.0,
            'recommended_production': 0,
            'confidence': 0.45,
            'narrative': (
                'Belum ada riwayat penjualan yang cukup untuk membuat perkiraan. '
                'Angka akan muncul setelah beberapa hari penjualan tercatat.'
            ),
            'source': 'heuristic',
        }

    # history di sini sudah menaik; tujuh terbaru ada di ekor.
    tujuh = history[-7:]
    avg7 = sum(float(h['portions_sold']) for h in tujuh) / len(tujuh)

    dow = DOW_MULTIPLIER[target_date.weekday()]
    cuaca = 0.88 if weather_code >= 60 or weather_code == 3 else 1.0
    demand_x = avg7 * dow * cuaca

    terakhir = history[-1]
    last_prod = float(terakhir['portions_sold']) + float(terakhir.get('surplus_kg') or 0) / 0.2
    surplus_y = 0.0 if last_prod <= 0 else min(max((last_prod - demand_x) / last_prod, 0.0), 1.0)

    return {
        'demand_x': round_half_away(demand_x),
        'surplus_probability_y': surplus_y,
        'surplus_volume_est_kg': demand_x * surplus_y * BERAT_PORSI_DEFAULT_KG,
        'recommended_production': rekomendasi_produksi(demand_x, surplus_y),
        'confidence': 0.45,
        'narrative': _narasi(demand_x, target_date, weather_code, surplus_y),
        'source': 'heuristic',
    }


def _narasi(demand_x: float, target_date: date, weather_code: int, surplus_y: float) -> str:
    hari = NAMA_HARI[target_date.weekday()]
    cuaca = 'hujan' if weather_code >= 60 or weather_code == 3 else 'cerah'
    risiko = 'cukup besar' if surplus_y >= 0.3 else 'kecil'
    return (
        f'Perkiraan untuk {hari}, cuaca {cuaca}: permintaan sekitar '
        f'{round_half_away(demand_x)} porsi. Risiko surplus {risiko}. Angka ini '
        'dihitung tanpa model — pakai sebagai ancar-ancar, bukan patokan.'
    )
```

- [ ] **Step 5: Tulis `api/forecast.py`**

```python
"""Buffer Intelligence — inferensi LSTM dan rakitan hasilnya.

Rantai: LSTM (+ Gemini di lapisan atas, Tugas 7) -> heuristik server.
Setiap lapis menulis `source` dengan jujur.
"""

from __future__ import annotations

from datetime import date, datetime

import numpy as np

from constants import BERAT_PORSI_DEFAULT_KG, normalisasi_weather, round_half_away
from heuristik import NAMA_HARI, forecast_heuristik, rekomendasi_produksi

WINDOW = 14
FITUR = 11


def urutkan_history(rows: list[dict]) -> list[dict]:
    """Dart mengirim terbaru dulu, contoh spec menaik. Layani keduanya."""
    return sorted(rows, key=lambda r: str(r.get('date') or ''))


def _tanggal(s: str) -> date:
    return datetime.strptime(s[:10], '%Y-%m-%d').date()


def _dow(row: dict) -> int:
    d = row.get('day_of_week')
    if d is not None and 0 <= int(d) <= 6:
        return int(d)
    return _tanggal(str(row['date'])).weekday()


def rakit_window(history: list[dict], scalers: dict) -> tuple[np.ndarray, float]:
    """Bangun tensor (1, 14, 11) dan kembalikan skala porsi yang dipakai.

    Skala diambil dari request, bukan dari scalers.json: layanan ini stateless
    dan merchant-nya bisa saja belum pernah dilihat model. Rata-rata 14 baris
    yang dikirim adalah skala yang benar untuk merchant itu hari ini.
    """
    rows = urutkan_history(history)[-WINDOW:]
    if len(rows) < WINDOW:
        raise ValueError(f'butuh {WINDOW} baris history, dapat {len(rows)}')

    porsi = [float(r['portions_sold']) for r in rows]
    surplus = [float(r.get('surplus_kg') or 0.0) for r in rows]

    g = scalers.get('global', {'porsi': 70.0, 'surplus': 2.5})
    sp = max(sum(porsi) / len(porsi), 1.0) if max(porsi) > 0 else float(g['porsi'])
    ss = max(sum(surplus) / len(surplus), 0.01) if max(surplus) > 0 else float(g['surplus'])

    X = np.zeros((1, WINDOW, FITUR), dtype='float32')
    for i, r in enumerate(rows):
        X[0, i, 0] = porsi[i] / sp
        X[0, i, 1 + _dow(r)] = 1.0
        X[0, i, 8] = 1.0 if r.get('is_holiday') else 0.0
        X[0, i, 9] = normalisasi_weather(r.get('weather_code'))
        X[0, i, 10] = surplus[i] / ss
    return X, sp


def _confidence(metrics: dict | None) -> float:
    """Diturunkan dari metrik nyata, bukan angka enak.

    Badge akurasi di UI merchant memakai angka yang sama, jadi badge itu
    mencerminkan hasil validasi model — bukan nilai karangan.
    """
    if not metrics:
        return 0.60
    akurasi = metrics.get('demand_akurasi')
    if akurasi is None:
        return 0.60
    return round(min(max(float(akurasi), 0.30), 0.95), 3)


def narasi_template(demand_x: int, target_date: date, weather_code: int,
                    surplus_y: float, produksi: int, nama: str | None) -> str:
    """Kalimat lapis `lstm_only` — dipakai kalau Gemini tidak tersedia."""
    hari = NAMA_HARI[target_date.weekday()]
    cuaca = 'hujan' if normalisasi_weather(weather_code) >= 0.7 else 'cerah'
    subjek = nama or 'Merchant'
    risiko = 'cukup besar' if surplus_y >= 0.3 else 'kecil'
    return (
        f'{subjek}: {hari} dengan cuaca {cuaca}, permintaan diprediksi {demand_x} porsi. '
        f'Produksi {produksi} porsi memberi ruang aman dengan risiko surplus {risiko}; '
        'surplus yang terbentuk sudah punya jalur keluar.'
    )


def hitung_forecast(req, runtime) -> dict:
    """Hasil lapis LSTM, atau heuristik server kalau model tidak hidup."""
    target = _tanggal(req.target_date)
    kode_cuaca = req.weather_forecast.code if req.weather_forecast else 0
    history = [h.model_dump() for h in req.history]

    if not runtime.loaded or len(history) < WINDOW:
        return forecast_heuristik(urutkan_history(history), target, kode_cuaca)

    try:
        X, sp = rakit_window(history, runtime.scalers)
        # Hari target menggantikan cuaca terakhir supaya ramalan besok ikut terbaca.
        X[0, -1, 9] = normalisasi_weather(kode_cuaca)
        pred_demand, pred_surplus = runtime.model.predict(X, verbose=0)
        demand = float(pred_demand.reshape(-1)[0]) * sp
        surplus_y = float(pred_surplus.reshape(-1)[0])
    except Exception:                    # noqa: BLE001 — model bermasalah bukan alasan 500
        return forecast_heuristik(urutkan_history(history), target, kode_cuaca)

    demand = max(demand, 0.0)
    surplus_y = min(max(surplus_y, 0.0), 1.0)
    demand_x = round_half_away(demand)
    produksi = rekomendasi_produksi(demand, surplus_y)
    nama = req.merchant_context.name if req.merchant_context else None

    return {
        'demand_x': demand_x,
        'surplus_probability_y': round(surplus_y, 4),
        'surplus_volume_est_kg': round(demand * surplus_y * BERAT_PORSI_DEFAULT_KG, 3),
        'recommended_production': produksi,
        'confidence': _confidence(runtime.metrics),
        'narrative': narasi_template(demand_x, target, kode_cuaca, surplus_y, produksi, nama),
        'source': 'lstm_only',
    }
```

- [ ] **Step 6: Sambungkan ke `api/main.py`**

Ganti `lifespan` dan tambahkan rute. Sisanya tidak berubah.

```python
# tambahan impor
import model_runtime
from forecast import hitung_forecast
from schemas import ForecastRequest, ForecastResponse

RUNTIME: model_runtime.Runtime | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global RUNTIME
    RUNTIME = model_runtime.muat(STATUS['model_path'])
    STATUS['model_loaded'] = RUNTIME.loaded
    STATUS['metrics'] = RUNTIME.metrics
    if not RUNTIME.loaded:
        print(f'  model tidak dimuat ({RUNTIME.error}) — layanan jalan dalam mode degraded')
    yield


@app.post('/forecast', response_model=ForecastResponse)
def forecast(req: ForecastRequest) -> ForecastResponse:
    rt = RUNTIME or model_runtime.Runtime(path=STATUS['model_path'])
    return ForecastResponse(**hitung_forecast(req, rt))
```

`STATUS['model_path']` sudah membaca `MODEL_PATH` dari environment di Tugas 3,
dengan default `./model/lestar_lstm.keras` — relatif terhadap folder kerja
`api/`, sama seperti di dalam image Docker.

- [ ] **Step 7: Jalankan seluruh test**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -v
```
Expected: semua lolos. `/health` sekarang `ok` karena `api/model/` sudah terisi
dari Tugas 5.

- [ ] **Step 8: Buktikan mode degraded secara nyata**

```bash
cd api && mv model/lestar_lstm.keras model/_lestar_lstm.keras.bak
MODEL_PATH=./model/lestar_lstm.keras ../ml/.venv/Scripts/python.exe -m pytest test_forecast.py -v
mv model/_lestar_lstm.keras.bak model/lestar_lstm.keras
```
Expected: seluruh test tetap lolos, `/forecast` tetap 200 dengan
`source='heuristic'`.

- [ ] **Step 9: Commit**

```bash
git add api/model_runtime.py api/heuristik.py api/forecast.py api/main.py api/test_forecast.py
git commit -m "feat(api): /forecast dengan inferensi LSTM dan heuristik saat degraded"
```

---

## Task 7: Klien Gemini dan penjaga batas ±20%

**Files:**
- Create: `api/gemini.py`
- Modify: `api/forecast.py` (satu fungsi pembungkus)
- Modify: `api/main.py` (rute `/forecast` memanggil pembungkus)
- Test: `api/test_gemini.py`

**Interfaces:**
- Consumes: `api.forecast.hitung_forecast`, `api.forecast.narasi_template`
- Produces:
  - `api.gemini.tersedia() -> bool`
  - `api.gemini.kalibrasi(lstm_demand: float, konteks: dict) -> tuple[float, str, str]`
    → `(demand, narasi, source)` dengan `source` ∈ `{'lstm_gemini', 'lstm_only'}`
  - `api.gemini.minta_teks(prompt: str, timeout: float) -> str | None`
  - `api.gemini.json_pertama(teks: str) -> dict | None` — dipakai juga oleh `esg.py`
  - `api.forecast.hitung_forecast_dengan_gemini(req, runtime) -> dict`

### Keputusan yang dikunci

**REST, bukan SDK.** `04-ai-pipeline.md` §7 menyebut `google-generativeai`.
Paket itu dilewati dan Gemini dipanggil lewat `httpx` yang sudah ada di
requirements: satu dependensi berat lebih sedikit di image Docker, kontrol
timeout langsung, dan tidak terpapar pergantian SDK. Endpoint:
`POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`.

**Batas ±20% ditegakkan tanpa pengecualian.** Di luar batas, keluaran Gemini
dibuang seluruhnya — angka **dan** kalimatnya — dan hasilnya jadi `lstm_only`
dengan narasi template. Kalimat yang lahir dari angka yang ditolak tidak boleh
ikut dipakai.

**Timeout 3 detik.** `/forecast` punya anggaran 4 detik di sisi Dart
(`01-architecture.md` §6). Gemini mendapat 3 detik supaya inferensi LSTM dan
perakitan respons masih muat sebelum klien menyerah.

- [ ] **Step 1: Tulis test yang gagal**

`api/test_gemini.py`:
```python
"""Penjaga batas Gemini. Tidak ada test di sini yang menyentuh jaringan."""
import pytest

import gemini


def test_tanpa_kunci_langsung_lstm_only(monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    demand, narasi, source = gemini.kalibrasi(100.0, {'narasi_template': 'template'})
    assert demand == 100.0
    assert source == 'lstm_only'
    assert narasi == 'template'


def test_geseran_di_dalam_batas_diterima(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks',
                        lambda *a, **k: '{"demand": 115, "narasi": "Besok Jumat, permintaan naik."}')
    demand, narasi, source = gemini.kalibrasi(100.0, {'narasi_template': 'template'})
    assert demand == 115
    assert source == 'lstm_gemini'
    assert narasi == 'Besok Jumat, permintaan naik.'


def test_geseran_tepat_dua_puluh_persen_masih_diterima(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks',
                        lambda *a, **k: '{"demand": 120, "narasi": "n"}')
    _, _, source = gemini.kalibrasi(100.0, {'narasi_template': 't'})
    assert source == 'lstm_gemini'


def test_di_luar_batas_ditolak_beserta_kalimatnya(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks',
                        lambda *a, **k: '{"demand": 180, "narasi": "kalimat dari angka yang ditolak"}')
    demand, narasi, source = gemini.kalibrasi(100.0, {'narasi_template': 'template'})
    assert demand == 100.0
    assert source == 'lstm_only'
    assert narasi == 'template'


def test_respons_tidak_valid_jatuh_ke_lstm_only(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    for balasan in (None, '', 'bukan json', '{"narasi": "tanpa angka"}', '{"demand": "abc"}'):
        monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: balasan)
        demand, narasi, source = gemini.kalibrasi(100.0, {'narasi_template': 'template'})
        assert (demand, source) == (100.0, 'lstm_only'), balasan


def test_gemini_meledak_tidak_melempar_ke_pemanggil(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')

    def meledak(*a, **k):
        raise RuntimeError('koneksi putus')

    monkeypatch.setattr(gemini, 'minta_teks', meledak)
    demand, _, source = gemini.kalibrasi(100.0, {'narasi_template': 't'})
    assert (demand, source) == (100.0, 'lstm_only')


def test_lstm_demand_nol_tidak_membagi_nol(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: '{"demand": 5, "narasi": "n"}')
    demand, _, source = gemini.kalibrasi(0.0, {'narasi_template': 't'})
    assert (demand, source) == (0.0, 'lstm_only')


def test_forecast_heuristik_tidak_dikirim_ke_gemini(monkeypatch):
    """Kalau model mati, Gemini tidak boleh mengarang angka di atas heuristik."""
    from types import SimpleNamespace

    import forecast
    import model_runtime

    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    dipanggil = []
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: dipanggil.append(1) or '{"demand":1}')

    req = SimpleNamespace(
        merchant_id='x', history=[], target_date='2026-08-29',
        weather_forecast=None, merchant_context=None,
    )
    hasil = forecast.hitung_forecast_dengan_gemini(req, model_runtime.Runtime(path='x'))
    assert hasil['source'] == 'heuristic'
    assert dipanggil == []
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_gemini.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'gemini'`.

- [ ] **Step 3: Tulis `api/gemini.py`**

```python
"""Gemini 2.5 Flash — kalibrasi konteks dan narasi.

Dua tugas, bukan pajangan: menggeser angka LSTM dalam batas sempit, dan
mengubah angka jadi kalimat Bahasa Indonesia.

**Gemini tidak pernah mengarang angka dari nol dan tidak pernah menyentuh
keputusan keamanan pangan.** Batas geseran ±20% dari angka LSTM ditegakkan di
`kalibrasi()`; di luar batas, seluruh keluarannya dibuang — angka dan
kalimatnya sekaligus, karena kalimat yang lahir dari angka yang ditolak tidak
boleh ikut dipakai.

Dipanggil lewat REST dengan httpx, bukan lewat SDK `google-generativeai`.
Satu dependensi berat lebih sedikit di image, dan kontrol timeout langsung di
tangan kita.
"""

from __future__ import annotations

import json
import os
import re

import httpx

MODEL = 'gemini-2.5-flash'
URL = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent'
BATAS_GESERAN = 0.20
TIMEOUT = 3.0


def tersedia() -> bool:
    return bool(os.getenv('GEMINI_API_KEY'))


def minta_teks(prompt: str, timeout: float = TIMEOUT) -> str | None:
    """Satu panggilan generateContent. Mengembalikan None kalau apa pun gagal."""
    kunci = os.getenv('GEMINI_API_KEY')
    if not kunci:
        return None
    try:
        r = httpx.post(
            URL,
            params={'key': kunci},
            json={
                'contents': [{'parts': [{'text': prompt}]}],
                'generationConfig': {'temperature': 0.4, 'responseMimeType': 'application/json'},
            },
            timeout=timeout,
        )
        if r.status_code != 200:
            return None
        return r.json()['candidates'][0]['content']['parts'][0]['text']
    except Exception:      # noqa: BLE001 — timeout, kuota habis, DNS: semuanya lstm_only
        return None


def json_pertama(teks: str) -> dict | None:
    try:
        return json.loads(teks)
    except Exception:
        pass
    m = re.search(r'\{.*\}', teks, re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except Exception:
        return None


def _prompt(lstm_demand: float, k: dict) -> str:
    return (
        'Kamu asisten peramalan permintaan untuk warung dan kafe di Indonesia.\n'
        f'Model LSTM memprediksi permintaan besok {lstm_demand:.0f} porsi.\n'
        f"Tanggal target: {k.get('target_date')} ({k.get('nama_hari')}).\n"
        f"Cuaca: {k.get('cuaca')}. Hari libur nasional: {k.get('is_holiday')}.\n"
        f"Merchant: {k.get('nama') or 'tidak disebut'}, kategori {k.get('kategori') or 'umum'}.\n"
        f"Probabilitas surplus dari model: {k.get('surplus_y')}.\n\n"
        'Tugasmu: sesuaikan angka LSTM itu berdasarkan konteks di atas, '
        f'maksimal {int(BATAS_GESERAN * 100)}% naik atau turun. '
        'Jangan menghitung angka dari nol — angka LSTM adalah titik awalnya.\n'
        'Balas JSON saja: {"demand": <angka>, "narasi": "<satu-dua kalimat '
        'Bahasa Indonesia untuk pemilik warung>"}'
    )


def kalibrasi(lstm_demand: float, konteks: dict) -> tuple[float, str, str]:
    """Kembalikan (demand, narasi, source).

    `source` 'lstm_gemini' hanya kalau Gemini menjawab, angkanya terbaca, dan
    geserannya <= 20%. Semua jalur lain 'lstm_only'.
    """
    template = konteks.get('narasi_template', '')

    if not tersedia() or lstm_demand <= 0:
        return lstm_demand, template, 'lstm_only'

    try:
        teks = minta_teks(_prompt(lstm_demand, konteks))
    except Exception:      # noqa: BLE001
        return lstm_demand, template, 'lstm_only'

    if not teks:
        return lstm_demand, template, 'lstm_only'

    data = json_pertama(teks)
    if not isinstance(data, dict):
        return lstm_demand, template, 'lstm_only'

    try:
        demand = float(data['demand'])
    except (KeyError, TypeError, ValueError):
        return lstm_demand, template, 'lstm_only'

    if demand <= 0 or abs(demand - lstm_demand) / lstm_demand > BATAS_GESERAN:
        return lstm_demand, template, 'lstm_only'

    narasi = str(data.get('narasi') or '').strip()
    if not narasi:
        return demand, template, 'lstm_gemini'
    return demand, narasi, 'lstm_gemini'
```

- [ ] **Step 4: Tambahkan pembungkus di `api/forecast.py`**

```python
import gemini


def hitung_forecast_dengan_gemini(req, runtime) -> dict:
    """Lapis 1 di atas Lapis 2. Heuristik tidak pernah dikirim ke Gemini —
    LLM tidak boleh mengarang angka di atas angka yang bukan dari model.
    """
    hasil = hitung_forecast(req, runtime)
    if hasil['source'] != 'lstm_only':
        return hasil

    target = _tanggal(req.target_date)
    kode_cuaca = req.weather_forecast.code if req.weather_forecast else 0
    ctx = req.merchant_context
    konteks = {
        'target_date': req.target_date,
        'nama_hari': NAMA_HARI[target.weekday()],
        'cuaca': 'hujan' if normalisasi_weather(kode_cuaca) >= 0.7 else 'cerah',
        'is_holiday': any(h.is_holiday for h in req.history[-1:]),
        'nama': ctx.name if ctx else None,
        'kategori': ctx.category if ctx else None,
        'surplus_y': hasil['surplus_probability_y'],
        'narasi_template': hasil['narrative'],
    }

    demand, narasi, source = gemini.kalibrasi(float(hasil['demand_x']), konteks)
    if source != 'lstm_gemini':
        return hasil

    surplus_y = hasil['surplus_probability_y']
    return {
        **hasil,
        'demand_x': round_half_away(demand),
        'surplus_volume_est_kg': round(demand * surplus_y * BERAT_PORSI_DEFAULT_KG, 3),
        'recommended_production': rekomendasi_produksi(demand, surplus_y),
        'narrative': narasi,
        'source': 'lstm_gemini',
    }
```

- [ ] **Step 5: Arahkan rute ke pembungkus**

Di `api/main.py`, ganti `hitung_forecast` jadi `hitung_forecast_dengan_gemini`
pada impor dan pada badan rute `/forecast`. Tidak ada perubahan lain.

- [ ] **Step 6: Jalankan seluruh test**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -v
```
Expected: semua lolos.

- [ ] **Step 7: Buktikan dengan kunci sungguhan, lalu tanpa kunci**

Kunci diambil dari `docs/CREDENTIALS-NEEDED.md`. **Jangan menempelkan nilainya
ke berkas mana pun** — hanya ke shell.

```bash
cd api
GEMINI_API_KEY=<kunci> ../ml/.venv/Scripts/python.exe -m uvicorn main:app --port 8000
# di terminal lain:
curl -s -X POST localhost:8000/forecast -H 'Content-Type: application/json' -d @../docs/../api/contoh_forecast.json | head -20
```
Kalau berkas contoh belum ada, kirim body inline yang sama dengan yang dipakai
`test_forecast.py`. Expected: `source` bernilai `lstm_gemini`.

Lalu ulangi tanpa `GEMINI_API_KEY`. Expected: 200 OK, `source='lstm_only'`,
narasi template. **Ini butir daftar periksa "Gemini dimatikan → /forecast tetap
200 OK".** Catat hasilnya untuk handoff.

- [ ] **Step 8: Commit**

```bash
git add api/gemini.py api/forecast.py api/main.py api/test_gemini.py
git commit -m "feat(api): klien Gemini via REST + penjaga batas geseran 20 persen"
```

---

## Task 8: Klien cuaca OpenWeatherMap

**Files:**
- Create: `api/weather.py`
- Modify: `api/forecast.py` (pakai cuaca terambil kalau request tidak membawanya)
- Test: `api/test_weather.py`

**Interfaces:**
- Consumes: `api.constants`
- Produces:
  - `api.weather.tersedia() -> bool`
  - `api.weather.kode_dari_owm(owm_id: int) -> int` → 0..3, skala `sales_history`
  - `api.weather.ramalan_besok(lat: float, lng: float, timeout: float = 2.0) -> int | None`

Spec hanya menyebut empat endpoint, jadi cuaca **tidak** mendapat rute
sendiri. `weather.py` dipakai di dalam `/forecast`: kalau `weather_forecast`
tidak dikirim dan `merchant_context` membawa `lat`/`lng`, kode cuaca diambil
dari OpenWeatherMap. Gagal atau tanpa kunci → jatuh ke 0 (cerah), tidak pernah
melempar error.

- [ ] **Step 1: Tulis test yang gagal**

`api/test_weather.py`:
```python
"""Pemetaan kode cuaca. Tidak ada test di sini yang menyentuh jaringan."""
import weather


def test_pemetaan_id_owm_ke_skala_agent_a():
    assert weather.kode_dari_owm(800) == 0       # cerah
    assert weather.kode_dari_owm(801) == 1       # sedikit berawan
    assert weather.kode_dari_owm(802) == 1
    assert weather.kode_dari_owm(803) == 2       # mendung
    assert weather.kode_dari_owm(804) == 2
    assert weather.kode_dari_owm(500) == 3       # hujan
    assert weather.kode_dari_owm(202) == 3       # badai petir
    assert weather.kode_dari_owm(301) == 3       # gerimis
    assert weather.kode_dari_owm(741) == 2       # kabut


def test_id_asing_dianggap_cerah():
    assert weather.kode_dari_owm(0) == 0
    assert weather.kode_dari_owm(99999) == 0


def test_tanpa_kunci_mengembalikan_none(monkeypatch):
    monkeypatch.delenv('OPENWEATHER_API_KEY', raising=False)
    assert weather.ramalan_besok(-7.98, 112.63) is None


def test_jaringan_gagal_mengembalikan_none_bukan_lempar(monkeypatch):
    monkeypatch.setenv('OPENWEATHER_API_KEY', 'kunci-uji')

    def meledak(*a, **k):
        raise RuntimeError('putus')

    monkeypatch.setattr(weather.httpx, 'get', meledak)
    assert weather.ramalan_besok(-7.98, 112.63) is None
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_weather.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'weather'`.

- [ ] **Step 3: Tulis `api/weather.py`**

```python
"""Cuaca besok dari OpenWeatherMap.

Keluarannya dipetakan ke skala `sales_history.weather_code` milik Agent A
(0 cerah, 1 berawan, 2 mendung, 3 hujan) supaya satu skala saja yang beredar
di dalam sistem.

Tidak punya rute sendiri: `04-ai-pipeline.md` §4 hanya menetapkan empat
endpoint. Dipakai di dalam /forecast ketika klien tidak mengirim
`weather_forecast`.
"""

from __future__ import annotations

import os

import httpx

URL = 'https://api.openweathermap.org/data/2.5/forecast'


def tersedia() -> bool:
    return bool(os.getenv('OPENWEATHER_API_KEY'))


def kode_dari_owm(owm_id: int) -> int:
    """id kondisi OpenWeatherMap -> 0..3."""
    i = int(owm_id)
    if 200 <= i < 600:          # badai, gerimis, hujan
        return 3
    if 600 <= i < 700:          # salju
        return 3
    if 700 <= i < 800:          # kabut, asap, debu
        return 2
    if i == 800:
        return 0
    if 801 <= i <= 802:
        return 1
    if 803 <= i <= 804:
        return 2
    return 0


def ramalan_besok(lat: float, lng: float, timeout: float = 2.0) -> int | None:
    """Kode cuaca 0..3 untuk ~24 jam ke depan, atau None kalau tidak bisa."""
    kunci = os.getenv('OPENWEATHER_API_KEY')
    if not kunci:
        return None
    try:
        r = httpx.get(
            URL,
            params={'lat': lat, 'lon': lng, 'appid': kunci, 'units': 'metric', 'cnt': 8},
            timeout=timeout,
        )
        if r.status_code != 200:
            return None
        blok = r.json().get('list') or []
        if not blok:
            return None
        # Ambil kondisi terburuk dalam 24 jam — merchant memutuskan produksi
        # untuk seharian, bukan untuk satu jam.
        return max(kode_dari_owm(b['weather'][0]['id']) for b in blok)
    except Exception:      # noqa: BLE001 — cuaca tidak pernah mematikan /forecast
        return None
```

- [ ] **Step 4: Sambungkan ke `api/forecast.py`**

Di `hitung_forecast_dengan_gemini` dan `hitung_forecast`, ganti baris pengambil
kode cuaca dengan pemanggilan helper berikut, ditulis sekali di modul yang sama:

```python
import weather


def _kode_cuaca(req) -> int:
    """Prioritas: yang dikirim klien, lalu OpenWeatherMap, lalu cerah."""
    if req.weather_forecast is not None:
        return int(req.weather_forecast.code)
    ctx = req.merchant_context
    if ctx and ctx.lat is not None and ctx.lng is not None:
        kode = weather.ramalan_besok(ctx.lat, ctx.lng)
        if kode is not None:
            return kode
    return 0
```

- [ ] **Step 5: Jalankan seluruh test**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -v
```
Expected: semua lolos.

- [ ] **Step 6: Commit**

```bash
git add api/weather.py api/forecast.py api/test_weather.py
git commit -m "feat(api): klien cuaca OpenWeatherMap dengan pemetaan skala 0-3"
```

---

## Task 9: `/esg-narrative`

**Files:**
- Create: `api/esg.py`
- Modify: `api/main.py` (rute `/esg-narrative`)
- Test: `api/test_esg.py`

**Interfaces:**
- Consumes: `api.gemini.minta_teks`, `api.gemini.tersedia`,
  `api.schemas.EsgRequest`
- Produces: `api.esg.narasi_esg(req) -> dict` → `{'narrative': str, 'source': str}`

Gemini menerima **angka yang sudah dihitung**, bukan data mentah. LLM tidak
pernah menghitung di sini; tugasnya hanya mengubah angka jadi kalimat. Kalau
Gemini gagal, template lokal tetap menyebut angka yang sama, jadi laporan
tetap benar meski kalimatnya kaku.

- [ ] **Step 1: Tulis test yang gagal**

`api/test_esg.py`:
```python
from fastapi.testclient import TestClient

import esg
import gemini
import main

AGREGAT = {
    'total_weight_kg': 128.4,
    'total_co2_kg': 32.1,
    'total_revenue_recovered': 2_450_000,
    'meals_rescued': 642,
    'period_start': '2026-08-01',
    'period_end': '2026-08-31',
    'merchant_name': 'Verde Kitchen',
}


def test_tanpa_gemini_tetap_membalas_paragraf_bernomor_benar(monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    b = r.json()
    assert b['source'] == 'template'
    assert '128,4' in b['narrative'] or '128.4' in b['narrative']
    assert '642' in b['narrative']


def test_dengan_gemini_memakai_kalimatnya(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks',
                        lambda *a, **k: '{"narasi": "Sepanjang Agustus, Verde Kitchen menyelamatkan 128,4 kg."}')
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.json()['source'] == 'gemini'
    assert 'Verde Kitchen' in r.json()['narrative']


def test_gemini_gagal_jatuh_ke_template(monkeypatch):
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: None)
    r = TestClient(main.app).post('/esg-narrative', json=AGREGAT)
    assert r.status_code == 200
    assert r.json()['source'] == 'template'


def test_agregat_nol_tidak_meledak(monkeypatch):
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json={
        'total_weight_kg': 0, 'total_co2_kg': 0,
    })
    assert r.status_code == 200
    assert r.json()['narrative']
```

- [ ] **Step 2: Jalankan test, pastikan gagal**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest test_esg.py -v
```
Expected: FAIL — `ModuleNotFoundError: No module named 'esg'`.

- [ ] **Step 3: Tulis `api/esg.py`**

```python
"""Narasi laporan ESG.

Gemini menerima angka yang **sudah dihitung**, bukan data mentah. LLM tidak
pernah menghitung di sini — tugasnya hanya mengubah angka jadi kalimat.
Laporan tidak boleh memuat angka yang tidak bisa ditelusuri ke baris
`esg_events` (00-PRD.md §6.5), jadi template dan prompt memakai angka yang
sama persis.
"""

from __future__ import annotations

import gemini


def _rupiah(n: float) -> str:
    return f'{int(round(n)):,}'.replace(',', '.')


def _desimal(n: float) -> str:
    return f'{n:.1f}'.replace('.', ',')


def template(a) -> str:
    subjek = a.merchant_name or 'Merchant ini'
    periode = ''
    if a.period_start and a.period_end:
        periode = f' pada periode {a.period_start} sampai {a.period_end}'
    return (
        f'{subjek} menahan {_desimal(a.total_weight_kg)} kg surplus pangan dari TPA'
        f'{periode}. Setara {_desimal(a.total_co2_kg)} kg CO2eq yang tidak terlepas '
        f'ke udara, {a.meals_rescued} porsi yang tetap dimakan orang, dan '
        f'Rp {_rupiah(a.total_revenue_recovered)} nilai yang kembali berputar. '
        'Seluruh angka di paragraf ini bisa ditelusuri ke baris esg_events.'
    )


def _prompt(a, dasar: str) -> str:
    return (
        'Tulis satu paragraf Bahasa Indonesia untuk materi green branding sebuah '
        'usaha kuliner. Nada percaya diri tapi tidak berlebihan, 3-4 kalimat.\n\n'
        'Angka yang WAJIB dipakai apa adanya, jangan diubah dan jangan ditambah '
        'angka baru:\n'
        f'- surplus pangan diselamatkan: {a.total_weight_kg} kg\n'
        f'- emisi dihindari: {a.total_co2_kg} kg CO2eq\n'
        f'- porsi diselamatkan: {a.meals_rescued}\n'
        f'- nilai ekonomi dipulihkan: Rp {_rupiah(a.total_revenue_recovered)}\n'
        f"- periode: {a.period_start or '-'} sampai {a.period_end or '-'}\n"
        f"- nama usaha: {a.merchant_name or 'tidak disebut'}\n\n"
        f'Sebagai acuan gaya, ini versi datarnya: {dasar}\n\n'
        'Balas JSON saja: {"narasi": "<paragraf>"}'
    )


def narasi_esg(a) -> dict:
    dasar = template(a)
    if not gemini.tersedia():
        return {'narrative': dasar, 'source': 'template'}

    try:
        teks = gemini.minta_teks(_prompt(a, dasar), timeout=6.0)
    except Exception:      # noqa: BLE001
        return {'narrative': dasar, 'source': 'template'}

    if not teks:
        return {'narrative': dasar, 'source': 'template'}

    data = gemini.json_pertama(teks)
    narasi = str((data or {}).get('narasi') or '').strip()
    if not narasi:
        return {'narrative': dasar, 'source': 'template'}
    return {'narrative': narasi, 'source': 'gemini'}
```

- [ ] **Step 4: Tambahkan rute di `api/main.py`**

```python
from esg import narasi_esg
from schemas import EsgRequest, EsgResponse


@app.post('/esg-narrative', response_model=EsgResponse)
def esg_narrative(req: EsgRequest) -> EsgResponse:
    return EsgResponse(**narasi_esg(req))
```

- [ ] **Step 5: Jalankan seluruh test**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -v
```
Expected: semua lolos, kelima rute hidup.

- [ ] **Step 6: Commit**

```bash
git add api/esg.py api/main.py api/test_esg.py
git commit -m "feat(api): /esg-narrative dengan template lokal sebagai jaring pengaman"
```

---

## Task 10: Docker dan kesiapan deploy

**Files:**
- Create: `api/Dockerfile`
- Create: `api/.dockerignore`
- Test: verifikasi manual — build, ukuran image, `/health`, latensi

**Interfaces:**
- Consumes: seluruh `api/`, termasuk `api/model/` dari Tugas 5
- Produces: image `lestar-api:local` siap `railway up`

- [ ] **Step 1: Tulis `api/.dockerignore`**

Tanpa ini, venv dan cache pytest ikut masuk konteks build dan image
menggelembung melewati batas free tier.

```
__pycache__/
*.pyc
.pytest_cache/
.venv/
.env
test_*.py
requirements-dev.txt
```

- [ ] **Step 2: Tulis `api/Dockerfile`**

```dockerfile
# tensorflow-cpu, BUKAN tensorflow. Paket penuh membawa dependensi CUDA ~2 GB
# dan menembus batas free tier Railway. Target image < 1,5 GB.
FROM python:3.11-slim

WORKDIR /app

# Layer dependensi dipisah supaya perubahan kode tidak memicu unduh ulang
# TensorFlow di setiap build.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV MODEL_PATH=./model/lestar_lstm.keras \
    PYTHONUNBUFFERED=1 \
    TF_CPP_MIN_LOG_LEVEL=2

EXPOSE 8000

# Railway menyuntikkan PORT. Default 8000 supaya `docker run -p 8000:8000`
# tetap jalan tanpa environment tambahan.
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

- [ ] **Step 3: Build image**

```bash
cd api && docker build -t lestar-api:local .
```
Expected: sukses. Kalau `tensorflow-cpu==2.15.1` tidak ditemukan, cari versi
terdekat yang ada dengan `pip index versions tensorflow-cpu` dan **ubah pin di
`ml/requirements.txt` juga, lalu latih ulang model** — versi Keras di kedua
sisi harus sama.

- [ ] **Step 4: Periksa ukuran image**

```bash
docker images lestar-api:local --format '{{.Size}}'
```
Expected: di bawah 1,5 GB.

Kalau melebihi: pastikan `requirements.txt` memakai `tensorflow-cpu`, bukan
`tensorflow`; pastikan `.dockerignore` benar-benar terbaca
(`docker build` mencetak ukuran konteks di baris pertama). Catat angka
sungguhannya untuk handoff apa pun hasilnya.

- [ ] **Step 5: Jalankan dan uji /health serta latensi**

```bash
docker run -d --name lestar-api-uji -p 8000:8000 lestar-api:local
sleep 12
curl -s localhost:8000/health
curl -s -o /dev/null -w 'health: %{time_total}s\n' localhost:8000/health
```
Expected: `{"status":"ok","model_loaded":true,...}`, dan `time_total` di bawah
0,3 detik. Kalau `model_loaded` false, `MODEL_PATH` atau `api/model/` tidak
ikut ter-COPY — periksa `.dockerignore`.

- [ ] **Step 6: Uji keempat endpoint di dalam container dan catat waktunya**

Kirim body yang sama dengan yang dipakai `test_forecast.py`, `test_parity.py`,
dan `test_esg.py`. Ukur dengan
`curl -o /dev/null -w '%{time_total}\n'`. Panggil `/forecast` **dua kali** —
panggilan pertama memanaskan grafik TensorFlow dan waktunya tidak mewakili
keadaan hangat.

Expected: keempat endpoint di bawah 2 detik saat hangat. Catat angka
sungguhannya untuk `C-HANDOFF.md`.

- [ ] **Step 7: Bersihkan**

```bash
docker rm -f lestar-api-uji
```

- [ ] **Step 8: Commit**

```bash
git add api/Dockerfile api/.dockerignore
git commit -m "chore(api): Dockerfile tensorflow-cpu + dockerignore, image di bawah 1,5 GB"
```

---

## Task 11: Serah terima `C-HANDOFF.md`

**Files:**
- Create: `docs/06-agent-briefs/C-HANDOFF.md`

Ini berkas yang dibaca pemilik proyek saat deploy dan dibaca Agent B dan D saat
menyambungkan pekerjaannya. Setiap angka di dalamnya harus datang dari keluaran
sungguhan yang sudah dijalankan, bukan dari rencana ini.

- [ ] **Step 1: Kumpulkan angka nyata**

```bash
cd ml && .venv/Scripts/python.exe generate_synthetic.py     # salin blok ringkasan
cat model/metrics.json                                       # salin metrik
cd ../api && ../ml/.venv/Scripts/python.exe -m pytest -q     # salin jumlah test
docker images lestar-api:local --format '{{.Size}}'          # salin ukuran image
```

- [ ] **Step 2: Tulis `docs/06-agent-briefs/C-HANDOFF.md`**

Struktur wajib, urutan ini, sesuai `docs/prompts/C.md`:

1. **Langkah deploy Railway** — persis, supaya pemilik proyek tinggal
   mengikuti. Minimal: `railway login`, `railway init`, `railway up` dari
   folder `api/`, cara mengisi environment variable lewat dashboard, cara
   memasang domain publik, dan perintah `curl` untuk memastikan
   `/health` menjawab `ok` setelah deploy. Sebutkan juga bahwa Railway
   menyuntikkan `PORT` sendiri dan `Dockerfile` sudah membacanya.
2. **Environment variable** yang harus diisi di Railway — nama saja:
   `GEMINI_API_KEY`, `OPENWEATHER_API_KEY`, `MODEL_PATH`, `ALLOWED_ORIGINS`.
   **Tanpa nilainya.** Sebutkan sumber nilainya:
   `docs/CREDENTIALS-NEEDED.md` yang tidak ter-commit.
3. **Metrik model nyata** dari `metrics.json` — Agent D memakainya untuk badge
   akurasi di kartu forecast. Sebutkan `demand_mae_porsi`, `demand_mae_pct`,
   `demand_akurasi`, `surplus_akurasi`, `target_met`, dan tegaskan bahwa klaim
   publik tetap 70%. Kalau `target_met` false, **tulis terus terang** apa yang
   sudah dicoba dan berapa hasil terbaiknya.
4. **Lokasi `test_parity.py` dan cara menjalankannya** — untuk Agent B:
   ```
   cd api && ../ml/.venv/Scripts/python.exe -m pytest test_parity.py -v
   ```
   Sertakan tabel 10 kasus triage + 3 kasus pricing dengan hasil Python di
   kolom terakhir, supaya Agent B bisa membandingkan baris demi baris dengan
   `test/fallback_engine_test.dart`. Sebutkan eksplisit bahwa kasus
   `lainnya · 1 jam · 28°C` memberi **93**, bukan 92, karena
   `round_half_away` dipakai — inilah butir 11.1 di `B-HANDOFF.md` yang
   sekarang terjawab.
5. **Format `seed_sales_history.csv`** — kolom persis, jendela tanggal,
   jumlah baris, dan perintah insert yang aman untuk Agent A:
   ```sql
   -- on conflict, bukan delete, supaya FK yang sudah ada tidak putus
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
   Sebutkan bahwa seed lama memberi surplus rata-rata 1,422 kg — di bawah
   rentang riset — dan berkas baru inilah yang memperbaikinya. Sebutkan juga
   berapa avg porsi berubah, supaya Agent D tidak kaget kalau angka di layar
   bergeser.
6. **Keputusan yang diambil sendiri, dan apa pun yang gagal atau dilewati.**
   Minimal daftar berikut, masing-masing dengan alasannya:
   - jendela 120 hari `2026-05-31`…`2026-09-27` dan kenapa 30 hari terakhir
     bertanggal setelah hari demo
   - kalibrasi `faktor_kepercayaan` lewat bagi dua, bukan undian
   - pemetaan kategori merchant → berat porsi (warung/katering 0,35 · kafe 0,20
     · bakery 0,08) dan kenapa tidak ada konstanta baru yang lahir
   - split kronologis 80/20, bukan acak, dan kebocoran yang dihindarinya
   - `scale_factor` inferensi diambil dari request, bukan dari `scalers.json`
   - Gemini dipanggil lewat REST `httpx`, bukan SDK `google-generativeai`
   - model tidak ada → `source='heuristic'`, dan bahwa `heuristic` di server
     berarti "tidak ada model yang menghasilkan angka ini", bukan "dihitung di
     dalam APK"
   - `confidence` diturunkan dari `metrics.json`, bukan angka tetap
   - pengali Ramadan diterapkan tapi tidak pernah aktif di jendela ini
     (Ramadan 1447 H jatuh Februari–Maret 2026)
   - tanggal Hijriah di `kalender.py` adalah perkiraan hisab, SKB bisa
     menggeser satu hari
   - `weather.py` tidak punya rute sendiri
   - satu baris pengecualian di `.gitignore` untuk `seed_sales_history.csv`
   - `api/model/` di-commit karena konteks build Docker adalah folder `api/`
   - **belum di-deploy** — pemilik proyek yang menjalankan `railway up` lalu
     mengisi `RAILWAY_API_URL`; Agent B menerimanya lewat
     `--dart-define=API_BASE_URL=...`

- [ ] **Step 3: Jalankan seluruh test sekali lagi sebagai bukti akhir**

```bash
cd api && ../ml/.venv/Scripts/python.exe -m pytest -q
cd ../ml && .venv/Scripts/python.exe -m pytest -q
```
Expected: semuanya lolos. Kalau ada yang gagal, perbaiki sebelum commit —
handoff yang menyebut angka dari test yang gagal lebih buruk daripada tidak
ada handoff.

- [ ] **Step 4: Periksa daftar "Selesai berarti" satu per satu**

Tandai di handoff, dengan bukti untuk masing-masing:

- [ ] Generator: surplus rata-rata 2–3 kg/merchant/hari — cetakan statistik
- [ ] Model terlatih, MAE demand < 15% dari rata-rata — atau dilaporkan apa adanya
- [ ] `metrics.json` berisi angka akurasi nyata
- [ ] Empat endpoint merespons < 2 detik saat hangat
- [ ] Gemini dimatikan → `/forecast` tetap 200 OK dengan `source='lstm_only'`
- [ ] Model dihapus → `/health` `degraded`, `/forecast` tetap membalas
- [ ] `test_parity.py` lulus di Python
- [ ] Image Docker < 1,5 GB, terbukti bisa di-build lokal
- [ ] `/health` merespons < 300 ms

Butir yang tidak tercapai ditulis sebagai tidak tercapai, dengan angka
sungguhannya. Jangan ada centang yang tidak punya bukti.

- [ ] **Step 5: Pastikan tidak ada rahasia yang ikut ter-commit**

```bash
git diff --cached | grep -nE 'AIza|sb_secret|eyJ[A-Za-z0-9_-]{20,}|service_role'
```
Expected: tidak ada keluaran. Kalau ada, hapus dari berkasnya sebelum commit.

- [ ] **Step 6: Commit**

```bash
git add docs/06-agent-briefs/C-HANDOFF.md
git commit -m "docs(core): serah terima Agent C — deploy Railway, metrik model, uji paritas"
```

---

## Self-Review

**Cakupan `docs/prompts/C.md`:**

| Yang diminta | Tugas |
|---|---|
| `ml/generate_synthetic.py`, 30×120, parameter §3 | 4 |
| Kalibrasi surplus 2–3 kg + cetak statistik | 4 (Step 5–7) |
| `train.csv` + `seed_sales_history.csv` | 4 (Step 7) |
| `ml/train_lstm.py`, arsitektur §2, scalers, 80/20, EarlyStopping 8 | 5 |
| Target MAE < 15%, tiga percobaan, lapor apa adanya | 5 (Step 5) |
| `metrics.json` | 5 |
| `/forecast` | 6 + 7 |
| `/triage`, `/pricing` deterministik | 2 + 3 |
| `/esg-narrative` | 9 |
| `/health` | 3 (+ status model di 6) |
| Stateless, tanpa DB | Global Constraints + 3 |
| Gemini gagal → `lstm_only` | 7 |
| Model gagal → `degraded` + heuristik server | 6 |
| Penjaga batas Gemini ±20% | 7 |
| Dockerfile `tensorflow-cpu`, < 1,5 GB, `lifespan` | 10 (+ 6) |
| `test_parity.py`, 10 kasus dari B-HANDOFF §12 | 2 |
| Jebakan pembulatan `round_half_away` | 1 + 2 |
| Shelf life default 8 jam | 1 |
| Rahasia hanya di environment | Global Constraints + 1 + 11 |
| Commit Bahasa Indonesia | Global Constraints |
| `C-HANDOFF.md` enam bagian | 11 |

**Yang sengaja tidak dikerjakan:** deploy ke Railway. `docs/prompts/C.md`
menyatakan pemilik proyek yang melakukannya; Tugas 11 menyiapkan langkahnya.

**Yang perlu diperhatikan saat eksekusi:** urutan `skala_list` di Tugas 5
Step 3 harus persis mengikuti urutan window validasi, kalau tidak MAE yang
dilaporkan salah tanpa ada test yang gagal.
