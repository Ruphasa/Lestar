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
