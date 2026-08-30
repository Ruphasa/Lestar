"""Uji rute /esg-narrative dan template lokal narasi ESG."""
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


def test_body_kosong_tetap_200_karena_semua_field_punya_default(monkeypatch):
    """Dart mengirim map bebas dan `tanpaNull()` membuang field null — tidak
    boleh ada field wajib di EsgRequest atau ini jadi 422."""
    monkeypatch.delenv('GEMINI_API_KEY', raising=False)
    r = TestClient(main.app).post('/esg-narrative', json={})
    assert r.status_code == 200
    b = r.json()
    assert b['source'] == 'template'
    assert b['narrative']


def test_format_angka_konvensi_indonesia():
    assert esg._desimal(128.4) == '128,4'
    assert esg._rupiah(2_450_000) == '2.450.000'


def test_template_memakai_format_rupiah_dan_desimal_indonesia():
    from schemas import EsgRequest
    a = EsgRequest(**AGREGAT)
    teks = esg.template(a)
    assert '128,4 kg' in teks
    assert '32,1 kg' in teks
    assert 'Rp 2.450.000' in teks
    assert 'Rp 2,450,000' not in teks
