"""Generator data sintetis Lestar — 30 merchant x 120 hari.

Bukan angka acak. Dibangun dari pola operasional F&B Indonesia: pengali
harian, hari gajian, libur nasional, Ramadan, cuaca, derau gaussian.
Parameter: docs/04-ai-pipeline.md §3.

Kalibrasi wajib: surplus rata-rata jatuh di 2-3 kg/merchant/hari, sesuai riset
Aksamala Foundation yang dikutip di Bab I proposal. Seluruh proyeksi ESG
bertumpu pada angka itu, jadi `faktor_kepercayaan` per merchant dicari dengan
bagi dua sampai targetnya tersentuh — bukan diundi lalu diharap benar.

Jalankan:  ml/.venv/Scripts/python.exe ml/generate_synthetic.py
"""

from __future__ import annotations

import argparse
from datetime import date, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

from kalender import is_libur, is_payday, is_ramadan
from merchants import MERCHANTS

# ── Parameter (04-ai-pipeline.md §3) ────────────────────────────────────
KATEGORI: dict[str, tuple[int, int]] = {
    'warung': (40, 90),
    'kafe': (60, 120),
    'bakery': (80, 150),
    'katering': (100, 180),
}

WEEKLY = [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]   # indeks 0 = Senin
PAYDAY = 1.12
HOLIDAY = 1.25
RAMADAN = 0.40
HUJAN = 0.88
NOISE = 0.08

FAKTOR_MIN, FAKTOR_MAX = 0.90, 1.30

# Kategori merchant -> berat porsi dominannya, diambil dari BERAT_PORSI_KG
# di 02-data-model.md §10. Tidak ada konstanta baru yang lahir di sini.
BERAT_PER_PORSI = {
    'warung': 0.35,      # nasi_lauk
    'katering': 0.35,    # nasi_lauk
    'kafe': 0.20,        # lainnya
    'bakery': 0.08,      # roti
}

HARGA_PORSI = {'warung': 15000, 'kafe': 22000, 'bakery': 12000, 'katering': 25000}

MULAI = pd.Timestamp(date(2026, 5, 31))
HARI = 120
HARI_SEED = 90

SURPLUS_TARGET_MIN, SURPLUS_TARGET_MAX = 2.0, 3.0
SEED = 20260902

AKAR = Path(__file__).resolve().parent


def _tanggal() -> list[pd.Timestamp]:
    return [MULAI + timedelta(days=i) for i in range(HARI)]


def _cuaca(rng: np.random.Generator, n: int) -> np.ndarray:
    """0 cerah, 1 berawan, 2 mendung, 3 hujan — skala Agent A.

    Bobotnya condong ke cerah/berawan; Malang di Juni-September musim kemarau.
    """
    return rng.choice([0, 1, 2, 3], size=n, p=[0.42, 0.30, 0.16, 0.12])


def _demand_harian(base: float, tanggal: list[pd.Timestamp], cuaca: np.ndarray,
                   rng: np.random.Generator) -> np.ndarray:
    """Permintaan sungguhan hari itu, sebelum merchant memutuskan produksi."""
    out = np.empty(len(tanggal))
    derau = rng.normal(1.0, NOISE, len(tanggal))
    for i, ts in enumerate(tanggal):
        d = ts.date()
        f = WEEKLY[ts.weekday()]
        if is_payday(d):
            f *= PAYDAY
        if is_libur(d):
            f *= HOLIDAY
        if is_ramadan(d):
            f *= RAMADAN
        if cuaca[i] == 3:
            f *= HUJAN
        out[i] = base * f * derau[i]
    return np.clip(out, 0, None)


def _produksi(base: float, tanggal: list[pd.Timestamp], faktor: float) -> np.ndarray:
    """Merchant mengikuti pola mingguan, dikali kepercayaan dirinya sendiri."""
    return np.array([base * WEEKLY[ts.weekday()] * faktor for ts in tanggal])


def _rata_surplus_kg(base, tanggal, demand, faktor, berat) -> float:
    prod = _produksi(base, tanggal, faktor)
    return float(np.maximum(0.0, prod - demand).mean() * berat)


def _cari_faktor(base, tanggal, demand, berat, target) -> tuple[float, bool]:
    """Bagi dua di [0.90, 1.30] sampai rata-rata surplus menyentuh target.

    Mengembalikan (faktor, tercapai). `tercapai=False` berarti target berada di
    luar jangkauan rentang yang ditetapkan 04-ai-pipeline.md §3; faktornya
    dijepit di batas dan pemanggil wajib mencetak peringatan.
    """
    lo, hi = FAKTOR_MIN, FAKTOR_MAX
    if _rata_surplus_kg(base, tanggal, demand, hi, berat) < target:
        return hi, False
    if _rata_surplus_kg(base, tanggal, demand, lo, berat) > target:
        return lo, False
    for _ in range(60):
        mid = (lo + hi) / 2
        if _rata_surplus_kg(base, tanggal, demand, mid, berat) < target:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2, True


def generate() -> pd.DataFrame:
    rng = np.random.default_rng(SEED)
    tanggal = _tanggal()
    baris = []
    peringatan = []
    di_luar_rentang = []

    for m in MERCHANTS:
        lo, hi = KATEGORI[m['kategori']]
        base = float(rng.integers(lo, hi + 1))
        berat = BERAT_PER_PORSI[m['kategori']]
        harga = HARGA_PORSI[m['kategori']] * float(rng.uniform(0.9, 1.1))

        cuaca = _cuaca(rng, HARI)
        demand = _demand_harian(base, tanggal, cuaca, rng)

        if m['kategori'] == 'bakery':
            # Penyesuaian resmi (task-4-brief.md, Step 6): berat porsi bakery
            # (0,08 kg) paling ringan sehingga butuh faktor_kepercayaan
            # tertinggi untuk mencapai target surplus yang sama. Target untuk
            # kategori ini digeser ke sisi bawah rentang riset supaya bisa
            # dicapai tanpa melebarkan batas faktor 0,90-1,30.
            target = float(rng.uniform(2.0, 2.3))
        else:
            target = float(rng.uniform(SURPLUS_TARGET_MIN + 0.15, SURPLUS_TARGET_MAX - 0.15))
        faktor, tercapai = _cari_faktor(base, tanggal, demand, berat, target)
        if not tercapai:
            peringatan.append((m['nama'], m['kategori'], round(faktor, 3), round(target, 2)))

        prod = _produksi(base, tanggal, faktor)
        terjual = np.minimum(prod, demand)
        surplus_kg = np.maximum(0.0, prod - demand) * berat

        surplus_rata2 = float(surplus_kg.mean())
        if not (SURPLUS_TARGET_MIN <= surplus_rata2 <= SURPLUS_TARGET_MAX):
            di_luar_rentang.append((m['nama'], m['kategori'], round(surplus_rata2, 3)))

        for i, ts in enumerate(tanggal):
            porsi = int(round(float(terjual[i])))
            baris.append({
                'merchant_id': m['id'],
                'date': ts,
                'portions_sold': porsi,
                'revenue': float(round(porsi * harga, 0)),
                'day_of_week': ts.weekday(),          # 0 = Senin
                'is_holiday': is_libur(ts.date()),
                'weather_code': int(cuaca[i]),
                'surplus_kg': round(float(surplus_kg[i]), 3),
            })

    if peringatan:
        print('\n  PERINGATAN — merchant yang tidak mencapai target surplus di dalam '
              f'rentang faktor {FAKTOR_MIN}-{FAKTOR_MAX}:')
        for nama, kat, f, t in peringatan:
            print(f'    {nama:32s} {kat:9s} faktor={f} target={t} kg')

    if di_luar_rentang:
        print('\n  PERINGATAN — merchant dengan surplus RATA-RATA di luar rentang riset '
              f'{SURPLUS_TARGET_MIN}-{SURPLUS_TARGET_MAX} kg/hari (lihat catatan di '
              'test_generate.py::test_setiap_merchant_juga_masuk_rentang):')
        for nama, kat, v in di_luar_rentang:
            print(f'    {nama:32s} {kat:9s} surplus_rata2={v} kg')

    return pd.DataFrame(baris).sort_values(['merchant_id', 'date']).reset_index(drop=True)


def ringkasan(df: pd.DataFrame) -> dict:
    kat = {m['id']: m['kategori'] for m in MERCHANTS}
    d = df.assign(kategori=df['merchant_id'].map(kat))
    per_kategori = (
        d.groupby('kategori')
        .agg(avg_porsi=('portions_sold', 'mean'), avg_surplus=('surplus_kg', 'mean'))
        .round(3)
        .to_dict('index')
    )
    return {
        'baris': len(df),
        'merchant': df['merchant_id'].nunique(),
        'hari': df['date'].nunique(),
        'avg_porsi': round(float(df['portions_sold'].mean()), 2),
        'avg_surplus': round(float(df['surplus_kg'].mean()), 3),
        'avg_revenue': round(float(df['revenue'].mean()), 0),
        'hari_libur': int(df['is_holiday'].sum() / df['merchant_id'].nunique()),
        'per_kategori': per_kategori,
    }


def cetak_ringkasan(r: dict) -> None:
    print('\n─── Ringkasan generator ' + '─' * 40)
    print(f"  baris            {r['baris']}  ({r['merchant']} merchant x {r['hari']} hari)")
    print(f"  rata porsi/hari  {r['avg_porsi']}")
    print(f"  rata revenue     Rp {r['avg_revenue']:,.0f}")
    print(f"  hari libur       {r['hari_libur']} dalam jendela")
    status = 'MASUK RENTANG' if 2.0 <= r['avg_surplus'] <= 3.0 else 'DI LUAR RENTANG — PERBAIKI'
    print(f"  rata surplus     {r['avg_surplus']} kg/merchant/hari   [{status} 2-3 kg]")
    print('\n  Sebaran per kategori merchant')
    print(f"  {'kategori':10s} {'avg porsi':>10s} {'avg surplus kg':>16s}")
    for k, v in sorted(r['per_kategori'].items()):
        print(f"  {k:10s} {v['avg_porsi']:>10.2f} {v['avg_surplus']:>16.3f}")
    print('─' * 63 + '\n')


def main() -> int:
    p = argparse.ArgumentParser(description='Generator data sintetis Lestar')
    p.add_argument('--out', default=str(AKAR / 'data'), help='folder keluaran')
    args = p.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    df = generate()
    r = ringkasan(df)
    cetak_ringkasan(r)

    train = df.copy()
    train['date'] = train['date'].dt.strftime('%Y-%m-%d')
    train.to_csv(out / 'train.csv', index=False)

    batas = MULAI + timedelta(days=HARI_SEED - 1)
    seed = df[df['date'] <= batas].copy()
    seed['date'] = seed['date'].dt.strftime('%Y-%m-%d')
    seed.to_csv(out / 'seed_sales_history.csv', index=False)

    print(f"  train.csv                {len(train)} baris  "
          f"{train['date'].min()} .. {train['date'].max()}")
    print(f"  seed_sales_history.csv   {len(seed)} baris  "
          f"{seed['date'].min()} .. {seed['date'].max()}  -> Agent A\n")

    if not (2.0 <= r['avg_surplus'] <= 3.0):
        print('  GAGAL: surplus rata-rata di luar 2-3 kg. Berkas tetap ditulis '
              'supaya bisa diperiksa, tapi jangan diserahkan ke Agent A.')
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
