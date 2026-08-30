"""Harga dinamis — deterministik, bukan LLM.

Kembaran persis `FallbackEngine.pricing` di lib/core/fallback_engine.dart.
Rumus: docs/04-ai-pipeline.md §4.

    rasio_waktu = 1 - (jam_tersisa / jam_total)
    rasio_stok  = qty_remaining / qty_total
    diskon = 0.30 + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
    diskon = min(diskon, 0.70)
    harga  = round(original_price * (1 - diskon) / 500) * 500

Batas 70% menepati janji "diskon 50-70%" di proposal. Pembulatan ke Rp500
supaya harga terlihat wajar, bukan Rp 31.847.
"""

from constants import DISKON_DASAR, DISKON_MAKSIMUM, round_half_away


def hitung_pricing(
    original_price: float,
    jam_tersisa: float,
    jam_total: float,
    qty_remaining: int,
    qty_total: int,
) -> dict:
    rasio_waktu = 1.0 if jam_total <= 0 else 1 - (jam_tersisa / jam_total)
    rasio_stok = 0.0 if qty_total <= 0 else qty_remaining / qty_total

    diskon = DISKON_DASAR + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
    diskon = min(diskon, DISKON_MAKSIMUM)

    harga = round_half_away(original_price * (1 - diskon) / 500) * 500

    return {'diskon': diskon, 'harga': float(harga)}
