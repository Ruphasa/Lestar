"""Hari libur nasional dan jendela Ramadan yang menyentuh rentang generator.

Tanggal Hijriah di bawah adalah perkiraan hisab. SKB tiga menteri bisa
menggeser satu hari, dan untuk data sintetis pergeseran itu tidak berpengaruh
pada pola yang dipelajari model.
"""

from datetime import date

LIBUR_NASIONAL: set[date] = {
    date(2026, 6, 1),    # Hari Lahir Pancasila
    date(2026, 6, 16),   # Tahun Baru Islam 1448 H (perkiraan)
    date(2026, 8, 17),   # Hari Kemerdekaan
    date(2026, 8, 25),   # Maulid Nabi Muhammad SAW (perkiraan)
}

# Ramadan 1447 H jatuh sekitar 17 Februari - 19 Maret 2026, seluruhnya di luar
# jendela generator (31 Mei - 27 September 2026). Pengalinya tetap ditulis dan
# diterapkan supaya generator benar kalau jendelanya digeser, tapi pada data
# yang dihasilkan sekarang faktor ini tidak pernah aktif. Ini dicatat di
# C-HANDOFF.md, bukan disembunyikan.
RAMADAN_MULAI = date(2026, 2, 17)
RAMADAN_SELESAI = date(2026, 3, 19)


def is_libur(d: date) -> bool:
    return d in LIBUR_NASIONAL


def is_ramadan(d: date) -> bool:
    return RAMADAN_MULAI <= d <= RAMADAN_SELESAI


def is_payday(d: date) -> bool:
    """Tanggal 25 sampai 5 bulan berikutnya."""
    return d.day >= 25 or d.day <= 5
