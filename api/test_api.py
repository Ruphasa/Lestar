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
