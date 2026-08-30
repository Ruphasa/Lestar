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
