"""Uji perakitan fitur, heuristik server, dan rute /forecast."""
from datetime import date, timedelta

import numpy as np
import pytest
from fastapi.testclient import TestClient

import forecast
import gemini
import main
import weather
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


@pytest.fixture
def lifespan_asli():
    """Simpan dan kembalikan `main.RUNTIME` / `main.STATUS`.

    `with TestClient(main.app) as klien:` menjalankan `lifespan` sungguhan,
    yang menulis `main.RUNTIME`/`main.STATUS` global -- dan lifespan tidak
    membersihkannya lagi setelah `yield`. Tanpa fixture ini, tes yang
    memakai `with` di sini akan membocorkan model yang benar-benar hidup ke
    tes lain di berkas ini yang sengaja memalsukan `STATUS['model_loaded']`
    ke False, membuat hasilnya tergantung urutan eksekusi.
    """
    runtime_asli = main.RUNTIME
    status_asli = dict(main.STATUS)
    yield
    main.RUNTIME = runtime_asli
    main.STATUS.clear()
    main.STATUS.update(status_asli)


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


# ─── Tugas 12 item 1: heuristik.py wajib memakai normalisasi_weather, bukan
# ambang sendiri (`weather_code >= 60 or weather_code == 3`). Ambang lama itu
# salah untuk id OpenWeatherMap 800 (cerah): 800 >= 60 bernilai True, padahal
# normalisasi_weather(800) == 0.0.


def test_heuristik_kode_0_sampai_3_tidak_berubah_setelah_perbaikan_item_1():
    """Kode 0..3 adalah skala Agent A yang beredar sungguhan hari ini lewat
    sales_history.weather_code. Perbaikan Item 1 tidak boleh mengubah hasil
    untuk kode-kode ini -- hanya id OpenWeatherMap yang berubah."""
    hist = _history()
    hasil = {c: forecast_heuristik(hist, date(2026, 8, 29), c) for c in (0, 1, 2, 3)}
    # 0, 1, 2 tetap dibaca "cerah" (perbandingan lama juga False untuk ketiganya)
    assert hasil[0]['demand_x'] == hasil[1]['demand_x'] == hasil[2]['demand_x']
    for c in (0, 1, 2):
        assert 'cerah' in hasil[c]['narrative']
    # 3 tetap satu-satunya kode 0..3 yang dibaca "hujan" (perbandingan lama
    # juga True lewat cabang `== 3`)
    assert hasil[3]['demand_x'] < hasil[0]['demand_x']
    assert 'hujan' in hasil[3]['narrative']


def test_heuristik_owm_800_kini_cerah_bukan_hujan():
    """Regresi Item 1: id OWM 800 (cerah) dulu dibaca "hujan" oleh ambang
    inline (`800 >= 60`) di heuristik.py, berbeda dari jalur LSTM yang lewat
    normalisasi_weather(800) == 0.0. Sekarang keduanya sepakat: 800 == cerah,
    sama seperti kode 0."""
    hist = _history()
    cerah_kanonik = forecast_heuristik(hist, date(2026, 8, 29), 0)
    owm_800 = forecast_heuristik(hist, date(2026, 8, 29), 800)
    assert owm_800['demand_x'] == cerah_kanonik['demand_x']
    assert 'cerah' in owm_800['narrative']


# ─── Tugas 12 item 2: weather_forecast.code >= 60 (skala FallbackEngine
# Dart, BUKAN id OWM asli yang mulai dari 200) didokumentasikan tapi belum
# pernah dites ujung-ke-ujung lewat /forecast sungguhan.


def test_forecast_endpoint_menerima_kode_cuaca_skala_fallback_engine():
    """History < WINDOW memaksa jalur heuristik supaya hasilnya deterministik
    dan tidak bergantung pada model LSTM yang mungkin/tidak termuat."""
    klien = TestClient(main.app)
    body = {'merchant_id': 'x', 'history': _history(n=5), 'target_date': '2026-08-29'}
    cerah = klien.post('/forecast', json={**body, 'weather_forecast': {'code': 0}})
    hujan = klien.post('/forecast', json={**body, 'weather_forecast': {'code': 65}})
    assert cerah.status_code == 200
    assert hujan.status_code == 200
    assert cerah.json()['source'] == 'heuristic'
    assert hujan.json()['source'] == 'heuristic'
    assert hujan.json()['demand_x'] < cerah.json()['demand_x']
    assert 'hujan' in hujan.json()['narrative']
    assert 'cerah' in cerah.json()['narrative']


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


# ─── Tes berikut memakai `with TestClient(...)` supaya `lifespan` benar-benar
# jalan dan model asli termuat -- jalur lstm_only baru bisa diuji lewat sini.


def _lewati_jika_model_tidak_termuat():
    """Tes lapis LSTM butuh model asli untuk sungguh-sungguh menguji apa
    pun -- kalau berkas model sedang sengaja disingkirkan (pembuktian mode
    degraded), lewati alih-alih gagal. Jalur heuristik yang membuktikan
    endpoint tetap 200 saat model tidak ada diuji di tes-tes lain di atas.
    """
    if main.RUNTIME is None or not main.RUNTIME.loaded:
        pytest.skip('model tidak termuat di lingkungan ini -- lihat tes mode degraded')


def test_health_ok_saat_lifespan_benar_benar_memuat_model(lifespan_asli):
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        h = klien.get('/health').json()
        assert h['status'] == 'ok'
        assert h['model_loaded'] is True


def test_forecast_source_lstm_only_saat_model_nyala_dan_riwayat_penuh(lifespan_asli):
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        r = klien.post('/forecast', json={
            'merchant_id': '4104d7ec-c72e-4113-a8f4-73e1d11423b1',
            'history': _history(),
            'target_date': '2026-08-29',
            'weather_forecast': {'code': 0},
            'merchant_context': {'name': 'Verde Kitchen', 'category': 'kafe'},
        })
        assert r.status_code == 200
        body = r.json()
        assert body['source'] == 'lstm_only'          # kesetaraan, bukan keanggotaan
        assert isinstance(body['demand_x'], int)
        assert 0.0 <= body['surplus_probability_y'] <= 1.0


def test_forecast_lstm_only_urutan_history_tidak_masalah(lifespan_asli):
    """Sama seperti test_forecast_menerima_history_terbaru_dulu, tapi di jalur
    LSTM sungguhan, bukan cuma heuristik."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        naik = _history()
        turun = list(reversed(naik))
        body = {'merchant_id': 'x', 'target_date': '2026-08-29', 'weather_forecast': {'code': 0}}
        a = klien.post('/forecast', json={**body, 'history': naik}).json()
        b = klien.post('/forecast', json={**body, 'history': turun}).json()
        assert a['source'] == 'lstm_only'
        assert b['source'] == 'lstm_only'
        assert a['demand_x'] == b['demand_x']


def test_forecast_confidence_lstm_only_ikuti_rumus_faktor_situasi(lifespan_asli):
    """docs/04-ai-pipeline.md §10: confidence = demand_akurasi x 0.90 untuk
    lstm_only. Bukti utamanya: TIDAK dibatasi ke klaim_publik (0.70)."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        assert main.RUNTIME.metrics is not None
        akurasi = float(main.RUNTIME.metrics['demand_akurasi'])
        r = klien.post('/forecast', json={
            'merchant_id': 'x', 'history': _history(), 'target_date': '2026-08-29',
        })
        body = r.json()
        assert body['source'] == 'lstm_only'
        harapan = akurasi * 0.90
        assert abs(body['confidence'] - harapan) < 0.001
        assert body['confidence'] > 0.70   # bukti tidak dibatasi ke klaim_publik


def test_confidence_faktor_situasi_lstm_gemini_lebih_tinggi_dari_lstm_only():
    """docs/04-ai-pipeline.md §10: faktor 1.00 untuk lstm_gemini, 0.90 untuk
    lstm_only -- Tugas 6 menghitungnya benar tapi tidak pernah dipanggil
    dengan source='lstm_gemini'. Regresi Tugas 7: buktikan langsung lewat
    `_confidence`, sumber kebenarannya, terlepas dari apakah endpoint
    sungguhan sedang bisa mencapai jalur itu."""
    metrics = {'demand_akurasi': 0.9227}
    gemini_ = forecast._confidence(metrics, 'lstm_gemini', 14)
    only = forecast._confidence(metrics, 'lstm_only', 14)
    assert gemini_ > only
    assert abs(gemini_ - 0.9227) < 0.001         # x1.00
    assert abs(only - 0.9227 * 0.90) < 0.001     # x0.90


def test_confidence_riwayat_kurang_dari_14_hari_diskalakan():
    """docs/04-ai-pipeline.md §10: riwayat < 14 hari dikali (n_hari / 14)."""
    metrics = {'demand_akurasi': 0.9227}
    penuh = forecast._confidence(metrics, 'lstm_only', 14)
    tujuh_hari = forecast._confidence(metrics, 'lstm_only', 7)
    assert tujuh_hari < penuh
    assert abs(tujuh_hari - 0.9227 * 0.90 * (7 / 14)) < 0.001

    # >= 14 hari tidak boleh mengalikan faktor di atas 1.00 (bukan "n_hari/14
    # selalu dikalikan", hanya kalau riwayatnya KURANG dari 14 hari).
    lebih_dari_14 = forecast._confidence(metrics, 'lstm_only', 30)
    assert abs(lebih_dari_14 - penuh) < 0.001


def test_forecast_lstm_gemini_confidence_lebih_tinggi_dari_lstm_only(monkeypatch, lifespan_asli):
    """Bukti ujung-ke-ujung: request yang sama, satu lolos kalibrasi Gemini
    dan satu jatuh ke lstm_only, harus membawa confidence yang berbeda --
    itulah satu-satunya sinyal yang membedakan keduanya di UI."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        monkeypatch.delenv('GEMINI_API_KEY', raising=False)
        body = {
            'merchant_id': 'x', 'history': _history(), 'target_date': '2026-08-29',
            'weather_forecast': {'code': 0},
        }
        r_only = klien.post('/forecast', json=body)
        assert r_only.json()['source'] == 'lstm_only'
        conf_only = r_only.json()['confidence']
        demand_only = r_only.json()['demand_x']

        monkeypatch.setenv('GEMINI_API_KEY', 'kunci-uji')
        geseran = int(demand_only * 1.05) or 1
        monkeypatch.setattr(
            gemini, 'minta_teks',
            lambda *a, **k: f'{{"demand": {geseran}, "narasi": "Kalibrasi uji."}}',
        )
        r_gemini = klien.post('/forecast', json=body)
        assert r_gemini.json()['source'] == 'lstm_gemini'
        assert r_gemini.json()['confidence'] > conf_only


def test_forecast_target_date_rusak_tetap_200_bukan_500():
    """Regresi finding 1: tanggal yang tidak bisa di-parse tidak boleh 500.
    Jalur heuristik cukup untuk regresi ini -- perbaikannya ada di `_tanggal`,
    dipakai di kedua jalur."""
    klien = TestClient(main.app)
    r = klien.post('/forecast', json={
        'merchant_id': 'x', 'history': _history(), 'target_date': 'bukan-tanggal',
    })
    assert r.status_code == 200
    assert r.json()['demand_x'] >= 0


def test_forecast_prediksi_nan_jatuh_ke_heuristik_bukan_500(monkeypatch, lifespan_asli):
    """Regresi finding 2: NaN dari model.predict() harus jatuh ke heuristik,
    bukan menjatuhkan endpoint dengan 500."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()

        def _predict_nan(X, verbose=0):
            return (
                np.array([[float('nan')]], dtype='float32'),
                np.array([[0.5]], dtype='float32'),
            )

        monkeypatch.setattr(main.RUNTIME.model, 'predict', _predict_nan)
        r = klien.post('/forecast', json={
            'merchant_id': 'x', 'history': _history(), 'target_date': '2026-08-29',
        })
        assert r.status_code == 200
        assert r.json()['source'] == 'heuristic'


# ─── Tugas 8: prioritas cuaca (klien -> OpenWeatherMap -> cerah). Tidak ada
# tes di sini yang menyentuh jaringan -- weather.ramalan_besok selalu
# dipalsukan lewat monkeypatch.


def test_kode_cuaca_mengutamakan_yang_dikirim_klien(monkeypatch):
    """Kalau klien mengirim weather_forecast, OpenWeatherMap tidak boleh
    ditanya sama sekali -- Dart adalah sumber yang lebih baru."""
    dipanggil = []
    monkeypatch.setattr(weather, 'ramalan_besok', lambda *a, **k: dipanggil.append(1) or 3)

    class _Req:
        weather_forecast = type('W', (), {'code': 2})()
        merchant_context = type('C', (), {'lat': -7.98, 'lng': 112.63})()

    assert forecast._kode_cuaca(_Req()) == 2
    assert dipanggil == []


def test_kode_cuaca_jatuh_ke_openweathermap_saat_klien_tidak_kirim(monkeypatch):
    """Tanpa weather_forecast tapi merchant_context membawa lat/lng ->
    dipetakan dari OpenWeatherMap."""
    monkeypatch.setattr(weather, 'ramalan_besok', lambda lat, lng, **k: 3)

    class _Req:
        weather_forecast = None
        merchant_context = type('C', (), {'lat': -7.98, 'lng': 112.63})()

    assert forecast._kode_cuaca(_Req()) == 3


def test_kode_cuaca_cerah_kalau_tidak_ada_apa_apa(monkeypatch):
    """Tanpa weather_forecast, tanpa lat/lng, atau OpenWeatherMap gagal ->
    jatuh ke 0 (cerah), bukan error."""
    monkeypatch.setattr(weather, 'ramalan_besok', lambda *a, **k: None)

    class _Req:
        weather_forecast = None
        merchant_context = None

    assert forecast._kode_cuaca(_Req()) == 0

    class _ReqGagal:
        weather_forecast = None
        merchant_context = type('C', (), {'lat': -7.98, 'lng': 112.63})()

    assert forecast._kode_cuaca(_ReqGagal()) == 0


def test_forecast_endpoint_memakai_openweathermap_saat_klien_tidak_kirim_cuaca(monkeypatch, lifespan_asli):
    """Ujung-ke-ujung lewat /forecast: tanpa weather_forecast tapi dengan
    lat/lng, endpoint memanggil weather.ramalan_besok, bukan diam-diam
    memakai 0."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        monkeypatch.setattr(weather, 'ramalan_besok', lambda lat, lng, **k: 3)
        r = klien.post('/forecast', json={
            'merchant_id': 'x',
            'history': _history(),
            'target_date': '2026-08-29',
            'merchant_context': {'lat': -7.98, 'lng': 112.63},
        })
        assert r.status_code == 200
        assert r.json()['source'] == 'lstm_only'


def test_forecast_dengan_gemini_memanggil_openweathermap_sekali_saja(monkeypatch, lifespan_asli):
    """Regresi: `hitung_forecast_dengan_gemini` memanggil `hitung_forecast`
    di dalamnya. Kalau kode cuaca dihitung ulang di kedua tempat, permintaan
    yang lolos ke kalibrasi Gemini akan menanyakan OpenWeatherMap dua kali,
    menggandakan anggaran jaringan yang sudah ketat (2 detik cuaca + 3 detik
    Gemini harus muat dalam anggaran 4 detik klien Dart)."""
    with TestClient(main.app) as klien:
        _lewati_jika_model_tidak_termuat()
        hitungan = []

        def _palsu(lat, lng, **k):
            hitungan.append(1)
            return 3

        monkeypatch.setattr(weather, 'ramalan_besok', _palsu)
        monkeypatch.delenv('GEMINI_API_KEY', raising=False)
        r = klien.post('/forecast', json={
            'merchant_id': 'x',
            'history': _history(),
            'target_date': '2026-08-29',
            'merchant_context': {'lat': -7.98, 'lng': 112.63},
        })
        assert r.status_code == 200
        assert len(hitungan) == 1
