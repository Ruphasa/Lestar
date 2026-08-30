# Lestar — AI Pipeline

**Versi** 1.0 · 29 Agustus 2026 · **Pemilik dokumen** Agent C (ML & API)

---

## 1. Prinsip

Ini bagian yang paling sering dilebih-lebihkan orang di lomba, dan paling sering ketahuan saat sesi tanya jawab. Tiga aturan:

1. **Setiap angka bisa ditelusuri.** Tidak ada nilai hardcode yang disamarkan sebagai output AI.
2. **Tugas dipisah ke model yang tepat.** LSTM untuk pola numerik. LLM untuk konteks dan bahasa. Rumus deterministik untuk keamanan pangan dan harga.
3. **Sistem mengaku saat jatuh ke fallback.** `forecasts.source` selalu mencerminkan asal angka yang sebenarnya.

## 2. Model LSTM

### Arsitektur — satu model, dua kepala

```python
inputs = Input(shape=(14, 11))          # window 14 hari, 11 fitur per hari
x = LSTM(64, return_sequences=True)(inputs)
x = LSTM(32)(x)
x = Dense(16, activation='relu')(x)

demand  = Dense(1, activation='linear',  name='demand')(x)   # X
surplus = Dense(1, activation='sigmoid', name='surplus')(x)  # Y

model = Model(inputs, [demand, surplus])
model.compile(
    optimizer='adam',
    loss={'demand': 'mse', 'surplus': 'binary_crossentropy'},
    loss_weights={'demand': 1.0, 'surplus': 0.5},
)
```

Satu model dengan dua output head, bukan dua model terpisah. X dan Y berbagi pola temporal yang sama — hari dalam seminggu, musim, cuaca. Melatihnya bersama membuat keduanya saling menguatkan.

**Ukuran model: ~180 KB. Waktu latih: ~2 menit di CPU laptop.** Tidak perlu GPU.

### 11 fitur per hari

| # | Fitur | Bentuk |
|---|---|---|
| 1 | `portions_sold` | dinormalisasi per merchant (dibagi rata-rata merchant itu) |
| 2–8 | `day_of_week` | one-hot 7 dimensi |
| 9 | `is_holiday` | 0 / 1 |
| 10 | `weather_code` | dinormalisasi 0..1 (0 = cerah, 1 = hujan lebat) |
| 11 | `surplus_kg` | dinormalisasi per merchant |

Normalisasi per merchant penting: warung 40 porsi/hari dan katering 180 porsi/hari harus dipelajari sebagai pola yang sama bentuknya, bukan skala yang berbeda. Nilai rata-rata per merchant disimpan sebagai `scale_factor` dan dipakai ulang saat inferensi.

### Target

- `demand` — `portions_sold` hari ke-15 (dinormalisasi)
- `surplus` — `1` kalau `surplus_kg > 0` pada hari ke-15, `0` kalau tidak

## 3. Data latih — cold start dan cara jujur menyelesaikannya

Proposal Bab 2.7.1 sudah menetapkan strategi tiga tahap. Dipakai persis:

| Tahap | Data | Model |
|---|---|---|
| **Fase 1** (sekarang) | Sintetis dari pola operasional F&B Indonesia + dataset publik | v0 |
| Fase 2 | Fine-tune dengan transaksi merchant awal | v1 |
| Fase 3 | Model personal per merchant | v2 |

### Generator sintetis — `ml/generate_synthetic.py`

30 merchant × 120 hari. **Bukan angka acak.** Dibangun dari pola nyata:

```python
KATEGORI = {
    'warung':   (40,  90),    # rentang base porsi/hari
    'kafe':     (60, 120),
    'bakery':   (80, 150),
    'katering': (100, 180),
}

WEEKLY = {                    # pengali per hari (0=Senin)
    0: 0.85, 1: 0.95, 2: 1.00, 3: 1.05,
    4: 1.20, 5: 1.35, 6: 1.15,             # Jum-Sab-Min naik
}

PAYDAY   = 1.12               # tanggal 25 s/d 5
HOLIDAY  = 1.25               # hari libur nasional
RAMADAN  = 0.40               # siang hari Ramadan
HUJAN    = 0.88               # dine-in turun saat hujan
NOISE    = 0.08               # gaussian, sigma 8% dari base

# produksi merchant = base × faktor_kepercayaan (0.9 – 1.3, acak per merchant)
# surplus = max(0, produksi − demand_aktual)
```

**Kalibrasi wajib:** `surplus_kg` rata-rata hasil generator harus jatuh di rentang **2–3 kg per merchant per hari**, sesuai riset Aksamala Foundation yang dikutip di Bab I proposal. Kalau meleset, sesuaikan `faktor_kepercayaan`. Angka ini yang membuat seluruh proyeksi ESG bisa dipertanggungjawabkan.

**90 hari pertama** masuk `sales_history` sebagai riwayat yang terlihat di app.
**120 hari penuh** dipakai melatih model.

### Kalimat yang bisa diucapkan ke juri

> *"Model ini dilatih pada data sintetis yang dibangun dari pola musiman F&B Indonesia — hari gajian, akhir pekan, hari libur nasional, cuaca. Di Fase 2, model di-fine-tune dengan data transaksi merchant sungguhan. Akurasi awal kami klaim 70%, bukan 95%."*

Klaim rendah yang bisa dibuktikan lebih meyakinkan daripada klaim tinggi yang tidak bisa dipertanggungjawabkan. Kalau juri menekan soal akurasi, jawaban jujur ini yang menyelamatkan.

## 4. Empat endpoint FastAPI

Semua stateless. **Tidak ada yang menyentuh database.**

### `POST /forecast`

**Masuk**
```json
{
  "merchant_id": "uuid",
  "history": [{"date":"2026-08-15","portions_sold":72,"day_of_week":4,
               "is_holiday":false,"weather_code":0,"surplus_kg":2.4}, ...14 baris],
  "target_date": "2026-08-30",
  "weather_forecast": {"code": 0, "temp": 31},
  "merchant_context": {"name":"Verde Kitchen","category":"kafe"}
}
```

**Keluar**
```json
{
  "demand_x": 55,
  "surplus_probability_y": 0.34,
  "surplus_volume_est_kg": 2.8,
  "recommended_production": 58,
  "confidence": 0.72,
  "narrative": "Besok Jumat dan cuaca cerah — permintaan diprediksi naik 18%. Produksi 58 porsi aman; surplus yang terbentuk sudah punya jalur keluar.",
  "source": "lstm_gemini"
}
```

**Rumus rekomendasi produksi:**
```
recommended_production = ceil(demand_x × (1 + buffer))
buffer = 0.15 × (1 − surplus_probability_y)
```

Semakin rendah probabilitas surplus, semakin besar buffer yang aman ditambahkan. Inilah inti Buffer Intelligence: merchant berani memproduksi lebih karena Lestar adalah jalur keluar yang pasti bagi setiap surplus.

### `POST /triage`

**Deterministik. Bukan LLM.** Keamanan pangan tidak boleh bergantung pada model probabilistik.

```python
score = 100
score -= (jam_sejak_masak / SHELF_LIFE[kategori]) * 60
if ambient_temp > 30: score -= 15
if kategori in ('seafood', 'santan_susu'): score -= 20
score = clamp(round(score), 0, 100)

route = 'b2c' if score >= 70 else 'b2b'
```

`SHELF_LIFE` (jam): gorengan 6 · nasi_lauk 8 · roti 24 · kue 72 · seafood 4 · santan_susu 5 · minuman 12

**Keluar:** `{"score": 82, "route": "b2c", "reason": "Dimasak 6 jam lalu, kategori roti tahan 24 jam. Kondisi suhu normal."}`

Kolom `reason` boleh diperkaya Gemini, tapi `score` dan `route` **tidak pernah** disentuh LLM.

### `POST /pricing`

Deterministik juga.

```python
rasio_waktu  = 1 - (jam_tersisa / jam_total)
rasio_stok   = qty_remaining / qty_total
diskon = 0.30 + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
diskon = min(diskon, 0.70)
harga  = round(original_price * (1 - diskon) / 500) * 500
```

Batas 70% menepati janji "diskon 50–70%" di proposal. Pembulatan ke Rp500 supaya harga terlihat wajar, bukan `Rp 31.847`.

### `POST /esg-narrative`

**Masuk:** agregat `esg_events` satu periode — total kg, total CO₂, total rupiah dipulihkan, jumlah porsi diselamatkan, rentang tanggal, nama merchant.

**Keluar:** paragraf Bahasa Indonesia siap pakai untuk materi green branding.

Gemini menerima **angka yang sudah dihitung**, bukan data mentah. LLM tidak pernah menghitung. Tugasnya hanya mengubah angka jadi kalimat.

## 5. Fallback chain

```
Lapis 1  LSTM + Gemini 2.5 Flash        source='lstm_gemini'
           ↓ Gemini timeout / kuota habis / respons tidak valid
Lapis 2  LSTM saja + template kalimat    source='lstm_only'
           ↓ Railway mati / timeout 4 detik / tidak ada koneksi
Lapis 3  Heuristik Dart di dalam app     source='heuristic'
```

### Lapis 3 — `lib/core/fallback_engine.dart`

Ada **di dalam APK**, bukan di server. Kalau internet mati total, app tetap memberi rekomendasi.

```dart
class FallbackEngine {
  static const dowMultiplier = [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15];

  static ForecastResult forecast({
    required List<SalesHistory> history,   // 14 hari terakhir
    required DateTime targetDate,
    required int weatherCode,
  }) {
    final avg7 = history.take(7)
        .map((e) => e.portionsSold).reduce((a, b) => a + b) / 7;

    final dow = dowMultiplier[targetDate.weekday - 1];
    final weather = weatherCode >= 60 ? 0.88 : 1.0;   // 60+ = hujan

    final demandX = avg7 * dow * weather;

    final lastProd = history.first.portionsSold + history.first.surplusKg / 0.2;
    final surplusY = ((lastProd - demandX) / lastProd).clamp(0.0, 1.0);

    return ForecastResult(
      demandX: demandX.round(),
      surplusProbabilityY: surplusY,
      recommendedProduction: (demandX * (1 + 0.15 * (1 - surplusY))).ceil(),
      confidence: 0.45,
      narrative: _template(demandX, targetDate, weatherCode),
      source: ForecastSource.heuristic,
    );
  }
}
```

Kasar, tapi masuk akal — dan **tidak pernah gagal**. Confidence sengaja ditulis rendah (0.45) supaya UI menampilkan tingkat keyakinan yang jujur.

### Rumus yang sengaja digandakan

`triage` dan `pricing` diimplementasikan **dua kali** — di Python dan di Dart — dengan rumus identik. Keduanya deterministik, jadi hasilnya sama persis. Ini yang membuat aplikasi tetap berfungsi penuh tanpa server.

Kalau salah satu diubah, **yang lain harus ikut diubah**. Konstantanya hidup di `lib/core/constants.dart` dan `api/constants.py`.

## 6. Peran Gemini 2.5 Flash

Dua tugas, bukan pajangan.

**1. Kalibrasi konteks + narasi** pada `/forecast`

Prompt menerima: angka LSTM mentah, cuaca besok, hari dalam minggu, hari libur nasional, kategori merchant. Mengembalikan angka final terkalibrasi + satu kalimat Bahasa Indonesia.

Batas yang harus ditegakkan: **Gemini hanya boleh mengubah angka LSTM dalam rentang ±20%.** Kalau keluarannya di luar rentang itu, tolak dan pakai angka LSTM apa adanya dengan `source='lstm_only'`. LLM tidak boleh mengarang angka dari nol.

**2. Laporan ESG** pada `/esg-narrative`

Mengubah agregat angka jadi paragraf green branding.

Gemini **tidak pernah** dipakai untuk menentukan angka dari nol, dan tidak pernah menyentuh keputusan keamanan pangan. Pemisahan tugas inilah yang membuat sistem tidak rapuh — kalau Gemini mati, LSTM tetap memberi angka; kalau keduanya mati, heuristik tetap memberi angka.

## 7. Deploy

**Railway**, `api/Dockerfile`:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

`requirements.txt`:
```
fastapi
uvicorn[standard]
tensorflow-cpu          # BUKAN tensorflow — 400 MB vs 2 GB
numpy
pydantic
httpx
google-generativeai
```

`tensorflow-cpu` wajib. Paket `tensorflow` penuh membawa dependensi CUDA ~2 GB dan akan menembus batas free tier Railway.

Model `.keras` ikut di dalam image, dimuat sekali saat startup lewat `lifespan`, bukan per request.

### Mencegah cold start saat demo

Endpoint `/health` dipanggil dari app tiap 10 menit selama aplikasi terbuka. Pada hari demo, panggil manual 15 menit sebelum presentasi.

## 8. Environment variable (Railway)

```
GEMINI_API_KEY=
OPENWEATHER_API_KEY=
MODEL_PATH=./model/lestar_lstm.keras
ALLOWED_ORIGINS=*
```

Kunci ini **hanya** ada di environment Railway. Tidak pernah masuk ke APK.

## 9. Daftar periksa Agent C

- [ ] Generator sintetis menghasilkan surplus rata-rata 2–3 kg/merchant/hari
- [ ] Model latih selesai, MAE demand < 15% dari rata-rata
- [ ] Empat endpoint merespons < 2 detik saat warm
- [ ] Gemini gagal → otomatis `lstm_only`, tidak error ke klien
- [ ] Model gagal dimuat → `/health` melaporkan `degraded`, endpoint tetap balas dengan heuristik server
- [ ] Rumus triage dan pricing di Python identik dengan versi Dart — diuji dengan 10 input yang sama
- [ ] Image Docker < 1,5 GB
- [ ] `/health` merespons < 300 ms

---

## 10. Akurasi vs confidence — dua besaran, jangan disatukan

**Keputusan 30 Agustus 2026**, setelah Agent C mengukur `demand_akurasi = 0,9227` pada split kronologis data sintetis.

### Masalahnya bukan memilih angka, tapi memilih label

`0,70` di proposal (Tabel 2.5.1) **bukan hasil pengukuran** — itu proyeksi. Menahan 0,9227 turun ke 0,70 tidak membuat sistem lebih jujur; itu mengganti angka terukur dengan angka yang tidak mengukur apa pun, lalu kehilangan dasarnya.

Yang benar: **cantumkan dasar pengukurannya**, jangan tahan angkanya.

### Badge akurasi merchant

```
92% · data sintetis
```

Terukur, berlabel, pertahanannya ada di layar sebelum juri bertanya. Slot label ini tetap benar setelah produksi — `92% · data sintetis` menjadi `88% · 90 hari data Anda`.

Sumber: `ml/model/metrics.json` → `demand_akurasi`. **Jangan hardcode.**

### `confidence` per ramalan

Besaran berbeda. Badge mengukur mutu model; `confidence` mengukur seberapa dipercaya **ramalan ini**, dan berubah tiap permintaan.

```
confidence = demand_akurasi × faktor_situasi

lstm_gemini, riwayat 14 hari penuh   0.92 × 1.00 = 0.92
lstm_only                            0.92 × 0.90 = 0.83
riwayat < 14 hari                    dikali (n_hari / 14)
heuristic (fallback_engine.dart)     0.45   ← milik Agent B, jangan diubah
```

**Jangan dibatasi 0,70.** Menahannya di angka proposal membuat lapisan `lstm_gemini` dan `lstm_only` terlihat sama padahal tidak — dan `confidence` adalah satu-satunya sinyal yang membedakan keduanya di UI.

### Di mana 0,70 tetap dipakai

Sebagai **klaim ke depan untuk merchant sungguhan**, bukan metrik model. Tempatnya:
- deck slide 7
- jawaban lisan saat juri menekan soal akurasi
- `metrics.json` → `klaim_publik` (sudah ada, biarkan)

Kalimat yang disiapkan:

> *"92% diukur pada split kronologis data sintetis Fase 1. Untuk merchant sungguhan kami klaim 70% — dan jarak itulah alasan Fase 2 melakukan fine-tuning dengan data transaksi nyata."*
