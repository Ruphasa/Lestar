"""Uji paritas rumus deterministik Python <-> Dart.

Rumus `triage` dan `pricing` ada dua kali dengan sengaja: di sini dan di
`lib/core/fallback_engine.dart`. Duplikasi itu yang membuat app tetap
berfungsi penuh tanpa server. Konsekuensinya, kalau satu diubah yang lain
wajib ikut diubah di commit yang sama.

Angka harapan di berkas ini dihitung tangan dari `docs/04-ai-pipeline.md` §4.
Versi Dart diuji melawan angka yang sama di `test/fallback_engine_test.dart`,
jadi keduanya diuji melawan spec — bukan melawan satu sama lain.
"""
import pytest

from pricing import hitung_pricing
from triage import hitung_triage

# kategori, jam sejak masak, suhu, skor, rute, asal angka
KASUS_TRIAGE = [
    ('roti',        6,  28, 85, 'b2c', '100 - 6/24*60'),
    ('gorengan',    3,  28, 70, 'b2c', '100 - 3/6*60, tepat di ambang'),
    ('gorengan',    4,  28, 60, 'b2b', '100 - 40'),
    ('nasi_lauk',   2,  28, 85, 'b2c', '100 - 2/8*60'),
    ('nasi_lauk',   2,  33, 70, 'b2c', '85 - 15 suhu'),
    ('kue',        12,  28, 90, 'b2c', '100 - 12/72*60'),
    ('seafood',     1,  28, 65, 'b2b', '100 - 15 - 20 kategori'),
    ('santan_susu', 1,  28, 68, 'b2b', '100 - 12 - 20'),
    ('minuman',     6,  31, 55, 'b2b', '100 - 30 - 15 suhu'),
    ('lainnya',     1,  28, 93, 'b2c', 'shelf default 8 jam: 100 - 7,5 = 92,5'),
]


@pytest.mark.parametrize('kategori,jam,suhu,skor,rute,asal', KASUS_TRIAGE)
def test_triage_paritas(kategori, jam, suhu, skor, rute, asal):
    hasil = hitung_triage(kategori, jam, suhu)
    assert hasil['score'] == skor, f'{kategori} {jam}j {suhu}C — {asal}'
    assert hasil['route'] == rute
    assert hasil['reason'].strip() != ''


def test_kasus_sepuluh_adalah_jebakan_pembulatan():
    """92,5 harus jadi 93, sama seperti Dart. round() bawaan memberi 92."""
    assert hitung_triage('lainnya', 1, 28)['score'] == 93


def test_triage_dijepit_nol_sampai_seratus():
    assert hitung_triage('seafood', 48, 35)['score'] == 0
    assert hitung_triage('kue', 0, 25)['score'] == 100


# harga asli, jam tersisa, jam total, sisa stok, stok awal, diskon, harga
KASUS_PRICING = [
    (25000, 0, 8, 10, 10, 0.70, 7500),   # 0,80 dijepit ke 0,70
    (20000, 8, 8,  0, 10, 0.30, 14000),
    (30000, 4, 8,  5, 10, 0.55, 13500),
]


@pytest.mark.parametrize('harga_asli,sisa,total,qty_sisa,qty_awal,diskon,harga', KASUS_PRICING)
def test_pricing_paritas(harga_asli, sisa, total, qty_sisa, qty_awal, diskon, harga):
    hasil = hitung_pricing(harga_asli, sisa, total, qty_sisa, qty_awal)
    assert hasil['diskon'] == pytest.approx(diskon, abs=1e-9)
    assert hasil['harga'] == harga


def test_pricing_selalu_kelipatan_lima_ratus():
    for harga_asli in (17300, 23999, 8100, 45500):
        hasil = hitung_pricing(harga_asli, 3, 8, 4, 10)
        assert hasil['harga'] % 500 == 0


def test_pricing_tidak_pernah_melebihi_diskon_maksimum():
    hasil = hitung_pricing(50000, 0, 8, 10, 10)
    assert hasil['diskon'] <= 0.70


def test_pricing_jam_total_nol_tidak_membagi_nol():
    """jam_total 0 berarti jendela sudah habis — perlakukan sebagai rasio penuh."""
    hasil = hitung_pricing(20000, 0, 0, 0, 10)
    assert hasil['diskon'] == pytest.approx(0.65, abs=1e-9)
