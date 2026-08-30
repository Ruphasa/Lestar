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
