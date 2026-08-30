"""Buffer Intelligence — inferensi LSTM dan rakitan hasilnya.

Rantai: LSTM (+ Gemini di lapisan atas, Tugas 7) -> heuristik server.
Setiap lapis menulis `source` dengan jujur.
"""

from __future__ import annotations

import math
from datetime import date, datetime

import numpy as np

import gemini
from constants import BERAT_PORSI_DEFAULT_KG, normalisasi_weather, round_half_away
from heuristik import NAMA_HARI, forecast_heuristik, rekomendasi_produksi
from model_runtime import SCALER_GLOBAL_DEFAULT

WINDOW = 14
FITUR = 11

# confidence = demand_akurasi x faktor_situasi (docs/04-ai-pipeline.md §10).
# lstm_gemini baru bisa dicapai di Tugas 7 -- masuk di sini sekarang supaya
# Tugas 7 tidak perlu menyentuh rumus ini lagi. `heuristic` tidak lewat sini
# sama sekali; confidence-nya tetap 0.45 milik Agent B (lihat heuristik.py).
FAKTOR_SITUASI: dict[str, float] = {
    'lstm_gemini': 1.00,
    'lstm_only': 0.90,
}


def _bulat_n(x: float, n: int) -> float:
    """Bulatkan ke n desimal, setengah menjauhi nol — bukan `round()` bawaan.

    `round_half_away` hanya membulatkan ke integer; nilai desimal di sini
    (probabilitas, volume kg, confidence) dibulatkan lewat skala 10**n supaya
    layanan ini tidak pernah memanggil `round()` bawaan Python di mana pun,
    sama seperti `demand_x`.
    """
    faktor = 10 ** n
    return round_half_away(x * faktor) / faktor


def urutkan_history(rows: list[dict]) -> list[dict]:
    """Dart mengirim terbaru dulu, contoh spec menaik. Layani keduanya."""
    return sorted(rows, key=lambda r: str(r.get('date') or ''))


def _tanggal(s: str) -> date:
    """Parse 'YYYY-MM-DD...'. Tanggal yang rusak tidak boleh menjatuhkan
    permintaan jadi 500 -- balas dengan tanggal hari ini, jawaban yang cukup
    masuk akal untuk sebuah ramalan yang tanggalnya sendiri tidak terbaca.

    Dipakai untuk `target_date` di request maupun `date` di tiap baris
    history (lewat `_dow`) -- keduanya sama-sama data yang datang dari luar
    dan sama-sama tidak boleh membuat endpoint gagal.
    """
    try:
        return datetime.strptime(str(s)[:10], '%Y-%m-%d').date()
    except (ValueError, TypeError, IndexError):
        return date.today()


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

    g = scalers.get('global', SCALER_GLOBAL_DEFAULT)
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


def _confidence(metrics: dict | None, source: str, n_hari: int = WINDOW) -> float:
    """confidence = demand_akurasi x faktor_situasi (docs/04-ai-pipeline.md §10).

    Keputusan pemilik proyek 30 Agustus 2026 menggantikan aturan lama
    ("clamp ke [0.30, 0.95]"): 0,70 adalah proyeksi proposal, bukan hasil
    ukur, dan menahan angka terukur turun ke situ menghapus satu-satunya
    sinyal yang membedakan `lstm_gemini` dari `lstm_only` di UI. **Jangan
    dibatasi ke `klaim_publik`.**

    `faktor_situasi` tergantung lapisan mana yang menghasilkan angka ini
    (1.00 untuk lstm_gemini dengan riwayat 14 hari penuh, 0.90 untuk
    lstm_only), dikalikan lagi dengan `n_hari / WINDOW` kalau riwayat yang
    dipakai kurang dari 14 hari. Jalur `heuristic` tidak pernah lewat sini;
    confidence-nya tetap 0.45 milik Agent B, tidak disentuh di sini.
    """
    if not metrics:
        return 0.60
    akurasi = metrics.get('demand_akurasi')
    if akurasi is None:
        return 0.60
    faktor = FAKTOR_SITUASI.get(source, 0.90)
    if n_hari < WINDOW:
        faktor *= n_hari / WINDOW
    return _bulat_n(float(akurasi) * faktor, 3)


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

        # Prediksi NaN/inf bukan angka yang bisa dipakai -- perlakukan sebagai
        # model gagal dan jatuh ke heuristik, bukan 500. Semua aritmetika di
        # bawah baris ini ada di dalam try yang sama supaya kalau ada yang
        # meledak, jalurnya tetap turun ke heuristik, bukan naik jadi 500.
        if not (math.isfinite(demand) and math.isfinite(surplus_y)):
            raise ValueError(f'prediksi model tidak valid: demand={demand!r} surplus={surplus_y!r}')

        demand = max(demand, 0.0)
        surplus_y = min(max(surplus_y, 0.0), 1.0)
        demand_x = round_half_away(demand)
        produksi = rekomendasi_produksi(demand, surplus_y)
        nama = req.merchant_context.name if req.merchant_context else None

        return {
            'demand_x': demand_x,
            'surplus_probability_y': _bulat_n(surplus_y, 4),
            'surplus_volume_est_kg': _bulat_n(demand * surplus_y * BERAT_PORSI_DEFAULT_KG, 3),
            'recommended_production': produksi,
            'confidence': _confidence(runtime.metrics, 'lstm_only', len(history)),
            'narrative': narasi_template(demand_x, target, kode_cuaca, surplus_y, produksi, nama),
            'source': 'lstm_only',
        }
    except Exception:                    # noqa: BLE001 — model bermasalah bukan alasan 500
        return forecast_heuristik(urutkan_history(history), target, kode_cuaca)


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
        'surplus_volume_est_kg': _bulat_n(demand * surplus_y * BERAT_PORSI_DEFAULT_KG, 3),
        'recommended_production': rekomendasi_produksi(demand, surplus_y),
        # Faktor situasi lstm_gemini (x1.00), bukan lstm_only (x0.90) --
        # kalau tidak, badge confidence lstm_gemini dan lstm_only sama saja
        # di UI, padahal itulah satu-satunya sinyal yang membedakan keduanya
        # (docs/04-ai-pipeline.md §10). n_hari dikirim apa adanya (bukan
        # WINDOW yang di-hardcode) supaya skala riwayat < 14 hari ikut jalan
        # kalau suatu saat jalurnya bisa dicapai dengan riwayat sependek itu.
        'confidence': _confidence(runtime.metrics, 'lstm_gemini', len(req.history)),
        'narrative': narasi,
        'source': 'lstm_gemini',
    }
