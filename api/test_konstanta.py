"""Konstanta di sini wajib identik dengan lib/core/constants.dart.

Kalau salah satu berubah tanpa yang lain ikut, laporan ESG dan skor triage
akan berselisih antara app dan server tanpa ada yang menyadarinya sampai demo.
"""
from constants import (
    AMBANG_TRIAGE_B2C,
    BERAT_PORSI_DEFAULT_KG,
    DISKON_DASAR,
    DISKON_MAKSIMUM,
    DOW_MULTIPLIER,
    FAKTOR_CO2_PER_KG,
    GREEN_FEE,
    QR_MASA_BERLAKU_JAM,
    SHELF_LIFE_DEFAULT_JAM,
    berat_porsi,
    normalisasi_weather,
    round_half_away,
    shelf_life,
)


def test_angka_bisnis_sama_dengan_dart():
    assert FAKTOR_CO2_PER_KG == 0.25
    assert GREEN_FEE == 1000
    assert AMBANG_TRIAGE_B2C == 70
    assert DISKON_MAKSIMUM == 0.70
    assert DISKON_DASAR == 0.30
    assert QR_MASA_BERLAKU_JAM == 2


def test_shelf_life_lengkap_dan_default_delapan_jam():
    assert shelf_life('gorengan') == 6
    assert shelf_life('nasi_lauk') == 8
    assert shelf_life('roti') == 24
    assert shelf_life('kue') == 72
    assert shelf_life('seafood') == 4
    assert shelf_life('santan_susu') == 5
    assert shelf_life('minuman') == 12
    # Tidak tertulis di 02-data-model.md §10; Agent B memilih 8 jam
    # (sama dengan nasi_lauk). Kalau berbeda, triage kategori tak dikenal
    # berselisih antara app dan server.
    assert SHELF_LIFE_DEFAULT_JAM == 8
    assert shelf_life('kategori_yang_tidak_ada') == 8


def test_berat_porsi_lengkap_dan_default():
    assert berat_porsi('gorengan') == 0.15
    assert berat_porsi('nasi_lauk') == 0.35
    assert berat_porsi('roti') == 0.08
    assert berat_porsi('kue') == 0.05
    assert berat_porsi('minuman') == 0.30
    assert berat_porsi('lainnya') == 0.20
    assert BERAT_PORSI_DEFAULT_KG == 0.20
    assert berat_porsi('seafood') == 0.20


def test_dow_multiplier_indeks_nol_senin():
    assert DOW_MULTIPLIER == [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]


def test_round_half_away_mengikuti_dart_bukan_python():
    # Ini kasus yang menggigit: round() bawaan Python memberi 92.
    assert round_half_away(92.5) == 93
    assert round_half_away(0.5) == 1
    assert round_half_away(1.5) == 2
    assert round_half_away(2.5) == 3
    assert round_half_away(-0.5) == -1
    assert round_half_away(-2.5) == -3
    assert round_half_away(92.4) == 92
    assert round_half_away(92.6) == 93


def test_normalisasi_weather_menerima_dua_skala():
    # Skala sales_history (0..3) dari Agent A
    assert normalisasi_weather(0) == 0.0
    assert normalisasi_weather(3) == 1.0
    # Skala kode cuaca app (>= 60 berarti hujan, sesuai FallbackEngine Dart)
    assert normalisasi_weather(61) >= 0.7
    assert normalisasi_weather(800) == 0.0
    assert normalisasi_weather(500) >= 0.7
