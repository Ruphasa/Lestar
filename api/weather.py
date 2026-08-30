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
