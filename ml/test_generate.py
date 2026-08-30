"""Uji generator. Ini tempat angka aneh ketahuan — bukan saat demo."""
from datetime import date

import pandas as pd

from generate_synthetic import HARI, MULAI, generate, ringkasan


def test_bentuk_dan_jendela_tanggal():
    df = generate()
    assert len(df) == 30 * HARI
    assert df['merchant_id'].nunique() == 30
    assert df['date'].min() == MULAI
    assert (df['date'].max() - MULAI).days == HARI - 1
    # Sembilan puluh hari pertama harus jatuh tepat di jendela Agent A.
    # (.date() diperlukan: datetime/Timestamp tidak pernah == date Python
    # murni walau tanggalnya sama -- ini semantik bahasa, bukan bug logika.)
    assert MULAI.date() == date(2026, 5, 31)
    assert MULAI + pd.Timedelta(days=89) == pd.Timestamp(date(2026, 8, 28))


def test_kolom_persis_kontrak_agent_a():
    df = generate()
    assert list(df.columns) == [
        'merchant_id', 'date', 'portions_sold', 'revenue',
        'day_of_week', 'is_holiday', 'weather_code', 'surplus_kg',
    ]


def test_domain_setiap_kolom():
    df = generate()
    assert (df['portions_sold'] >= 0).all()
    assert (df['revenue'] >= 0).all()
    assert df['day_of_week'].between(0, 6).all()
    assert df['weather_code'].between(0, 3).all()
    assert (df['surplus_kg'] >= 0).all()
    assert df['is_holiday'].dtype == bool
    assert not df.duplicated(subset=['merchant_id', 'date']).any()


def test_day_of_week_nol_adalah_senin():
    df = generate()
    baris = df.iloc[0]
    assert baris['day_of_week'] == baris['date'].weekday()


def test_kalibrasi_surplus_masuk_rentang_riset():
    """2-3 kg/merchant/hari, dikutip dari riset Aksamala Foundation."""
    df = generate()
    assert 2.0 <= df['surplus_kg'].mean() <= 3.0


def test_setiap_merchant_juga_masuk_rentang():
    df = generate()
    per_merchant = df.groupby('merchant_id')['surplus_kg'].mean()
    assert per_merchant.between(2.0, 3.0).all(), per_merchant[~per_merchant.between(2.0, 3.0)]


def test_akhir_pekan_lebih_ramai_daripada_senin():
    df = generate()
    per_hari = df.groupby('day_of_week')['portions_sold'].mean()
    assert per_hari[5] > per_hari[0]      # Sabtu > Senin


def test_deterministik():
    a, b = generate(), generate()
    pd.testing.assert_frame_equal(a, b)


def test_ringkasan_mengembalikan_angka_bukan_none():
    r = ringkasan(generate())
    assert r['avg_porsi'] > 0
    assert 2.0 <= r['avg_surplus'] <= 3.0
    assert set(r['per_kategori']) == {'warung', 'kafe', 'bakery', 'katering'}
