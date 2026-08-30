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
    for balasan in (None, '', 'bukan json', '{"narasi": "tanpa angka"}', '{"demand": "abc"}', '42'):
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


def test_kalibrasi_narasi_kosong_tetap_lstm_gemini_pakai_template(monkeypatch):
    """Angka diterima (dalam batas) tapi narasi kosong -- source tetap
    'lstm_gemini' (angkanya sah), kalimatnya jatuh balik ke template karena
    tidak ada kalimat lain yang bisa dipakai."""
    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: '{"demand": 105, "narasi": ""}')
    demand, narasi, source = gemini.kalibrasi(100.0, {'narasi_template': 'template'})
    assert demand == 105
    assert source == 'lstm_gemini'
    assert narasi == 'template'


def test_json_pertama_menerima_json_berpagar_markdown():
    """Gemini kadang membalas di dalam pagar markdown (json fenced code
    block) walau diminta JSON polos -- json_pertama harus tetap menemukan
    objeknya."""
    teks = '```json\n{"demand": 90, "narasi": "Naik dikit."}\n```'
    assert gemini.json_pertama(teks) == {'demand': 90, 'narasi': 'Naik dikit.'}


def test_json_pertama_menerima_json_diikuti_prosa():
    teks = '{"demand": 90, "narasi": "Naik dikit."}\n\nSemoga membantu!'
    assert gemini.json_pertama(teks) == {'demand': 90, 'narasi': 'Naik dikit.'}


def test_json_pertama_angka_polos_bukan_dict():
    """json_pertama mem-parse JSON apa adanya -- angka polos jadi int Python
    yang sah, bukan None. Penolakan "bukan dict" adalah tanggung jawab
    kalibrasi() (dites di atas lewat test_respons_tidak_valid_jatuh_ke_lstm_only,
    kasus balasan '42'), bukan tanggung jawab json_pertama sendiri."""
    assert gemini.json_pertama('42') == 42


def test_forecast_heuristik_history_kosong_tidak_dikirim_ke_gemini(monkeypatch):
    """Kasus degenerate dari brief asli. History kosong -> forecast_heuristik
    menghasilkan demand_x=0, dan kalibrasi() sendiri punya short-circuit
    independen untuk lstm_demand<=0 (lihat test_lstm_demand_nol_tidak_membagi_nol).
    Karena itu tes ini SENDIRIAN tidak membuktikan guard "heuristik tidak
    dikirim ke Gemini" di forecast.hitung_forecast_dengan_gemini -- kedua
    guard itu kebetulan tumpang tindih pada input ini. Bukti yang genuinely
    falsifiable ada di test_forecast_heuristik_demand_taknol_tidak_dikirim_ke_gemini
    di bawah. Kasus history kosong tetap dipertahankan di sini karena ia
    tetap kasus nyata yang layak diuji (merchant baru tanpa riwayat)."""
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


def test_forecast_heuristik_demand_taknol_tidak_dikirim_ke_gemini(monkeypatch):
    """Bukti yang genuinely falsifiable bahwa guard
    `if hasil['source'] != 'lstm_only': return hasil` di
    hitung_forecast_dengan_gemini benar-benar mencegah panggilan ke Gemini --
    bukan cuma kebetulan tertutup oleh short-circuit lain.

    History-nya pendek (< WINDOW) dan model mati (Runtime(path='x') belum
    dimuat), jadi jalurnya tetap 'heuristic'. Tapi portions_sold-nya nyata
    (bukan nol), sehingga forecast_heuristik menghasilkan demand_x > 0. Itu
    artinya short-circuit lstm_demand<=0 milik kalibrasi() TIDAK bisa ikut
    menyelamatkan tes ini kalau guard di hitung_forecast_dengan_gemini
    dicabut -- kalau guard-nya hilang, minta_teks akan sungguh terpanggil dan
    tes ini gagal. (Diverifikasi manual: lihat catatan falsifiability di
    task-7-report.md.)"""
    import forecast
    import model_runtime
    from schemas import ForecastRequest, HistoryRow

    monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
    dipanggil = []
    monkeypatch.setattr(gemini, 'minta_teks', lambda *a, **k: dipanggil.append(1) or '{"demand":1}')

    history = [
        HistoryRow(date=f'2026-08-{20 + i:02d}', portions_sold=50 + i, day_of_week=i,
                   is_holiday=False, weather_code=0, surplus_kg=1.0)
        for i in range(5)
    ]
    req = ForecastRequest(
        merchant_id='x', history=history, target_date='2026-08-29',
        weather_forecast=None, merchant_context=None,
    )
    hasil = forecast.hitung_forecast_dengan_gemini(req, model_runtime.Runtime(path='x'))
    assert hasil['source'] == 'heuristic'
    assert hasil['demand_x'] > 0     # kunci: demand taknol, jadi short-circuit gemini tidak relevan
    assert dipanggil == []
