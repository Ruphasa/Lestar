"""Konstanta bersama Lestar — sisi Python.

Nilai di berkas ini muncul di tiga tempat: Dart (`lib/core/constants.dart`),
Python (di sini), dan SQL (`berat_porsi_kg()` + `faktor_co2_per_kg()` di
`supabase/migrations/0005_intelligence.sql`). **Ketiganya wajib sama.** Kalau
salah satu diubah, ubah dua lainnya di commit yang sama.

Sumber angka: `docs/02-data-model.md` §10.
"""

import math

# ── Angka bisnis ────────────────────────────────────────────────────────
FAKTOR_CO2_PER_KG = 0.25
GREEN_FEE = 1000
AMBANG_TRIAGE_B2C = 70
DISKON_MAKSIMUM = 0.70
DISKON_DASAR = 0.30
QR_MASA_BERLAKU_JAM = 2

# ── Tabel kategori ──────────────────────────────────────────────────────
SHELF_LIFE_JAM: dict[str, int] = {
    'gorengan': 6,
    'nasi_lauk': 8,
    'roti': 24,
    'kue': 72,
    'seafood': 4,
    'santan_susu': 5,
    'minuman': 12,
}

# Tidak tertulis di 02-data-model.md §10, yang hanya menyebut default berat
# porsi. Agent B memilih 8 jam (nilai nasi_lauk, kategori paling umum) dan
# angka ini wajib sama di kedua sisi.
SHELF_LIFE_DEFAULT_JAM = 8

BERAT_PORSI_KG: dict[str, float] = {
    'gorengan': 0.15,
    'nasi_lauk': 0.35,
    'roti': 0.08,
    'kue': 0.05,
    'minuman': 0.30,
    'lainnya': 0.20,
}
BERAT_PORSI_DEFAULT_KG = 0.20

KATEGORI_CEPAT_RUSAK = frozenset({'seafood', 'santan_susu'})

# Pengali permintaan per hari. Indeks 0 = Senin, mengikuti konvensi
# sales_history.day_of_week — bukan datetime.weekday() Python yang juga 0=Senin
# tapi bukan DateTime.weekday Dart yang 1=Senin.
DOW_MULTIPLIER: list[float] = [0.85, 0.95, 1.00, 1.05, 1.20, 1.35, 1.15]


def shelf_life(kategori: str) -> int:
    return SHELF_LIFE_JAM.get(kategori, SHELF_LIFE_DEFAULT_JAM)


def berat_porsi(kategori: str) -> float:
    return BERAT_PORSI_KG.get(kategori, BERAT_PORSI_DEFAULT_KG)


# ── Pembulatan ──────────────────────────────────────────────────────────
def round_half_away(x: float) -> int:
    """Bulatkan setengah menjauhi nol — sama dengan `double.round()` di Dart.

    `round()` bawaan Python membulatkan setengah ke genap: 92.5 jadi 92,
    sementara Dart memberi 93. Selisih satu itu baru ketahuan saat demo
    sebagai skor triage yang tidak cocok antara layar dan server.
    """
    return int(math.floor(x + 0.5)) if x >= 0 else int(math.ceil(x - 0.5))


# ── Cuaca ───────────────────────────────────────────────────────────────
def normalisasi_weather(code: int | None) -> float:
    """Ubah kode cuaca jadi 0..1 (0 = cerah, 1 = hujan lebat).

    Dua skala masuk ke sistem ini dan keduanya harus dilayani:

    * `sales_history.weather_code` dari Agent A: smallint 0..3
      (0 cerah, 1 berawan, 2 mendung, 3 hujan).
    * kode cuaca dari app: `FallbackEngine` Dart memperlakukan >= 60 sebagai
      hujan, dan OpenWeatherMap memakai id kondisi 2xx–8xx.

    Angka <= 3 dibaca sebagai skala Agent A karena di skala OpenWeatherMap
    tidak ada id kondisi di bawah 200.
    """
    if code is None:
        return 0.0
    c = int(code)
    if 0 <= c <= 3:
        return c / 3.0
    if c >= 200 and c < 600:      # badai, gerimis, hujan
        return 0.9
    if c >= 600 and c < 700:      # salju — tidak relevan di Indonesia
        return 0.9
    if c >= 700 and c < 800:      # kabut, asap
        return 0.5
    if c == 800:                  # cerah
        return 0.0
    if c > 800:                   # 801..804 berawan sampai mendung
        return min((c - 800) / 4.0, 1.0)
    if c >= 60:                   # ambang hujan versi FallbackEngine Dart
        return 0.9
    return 0.3
