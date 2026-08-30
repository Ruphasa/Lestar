"""Narasi laporan ESG.

Gemini menerima angka yang **sudah dihitung**, bukan data mentah. LLM tidak
pernah menghitung di sini — tugasnya hanya mengubah angka jadi kalimat.
Laporan tidak boleh memuat angka yang tidak bisa ditelusuri ke baris
`esg_events` (00-PRD.md §6.5), jadi template dan prompt memakai angka yang
sama persis.
"""

from __future__ import annotations

import gemini
from constants import round_half_away


def _rupiah(n: float) -> str:
    return f'{round_half_away(n):,}'.replace(',', '.')


def _desimal(n: float) -> str:
    dibulatkan = round_half_away(n * 10) / 10
    return f'{dibulatkan:.1f}'.replace('.', ',')


def template(a) -> str:
    subjek = a.merchant_name or 'Merchant ini'
    periode = ''
    if a.period_start and a.period_end:
        periode = f' pada periode {a.period_start} sampai {a.period_end}'
    return (
        f'{subjek} menahan {_desimal(a.total_weight_kg)} kg surplus pangan dari TPA'
        f'{periode}. Setara {_desimal(a.total_co2_kg)} kg CO2eq yang tidak terlepas '
        f'ke udara, {a.meals_rescued} porsi yang tetap dimakan orang, dan '
        f'Rp {_rupiah(a.total_revenue_recovered)} nilai yang kembali berputar. '
        'Seluruh angka di paragraf ini bisa ditelusuri ke baris esg_events.'
    )


def _prompt(a, dasar: str) -> str:
    return (
        'Tulis satu paragraf Bahasa Indonesia untuk materi green branding sebuah '
        'usaha kuliner. Nada percaya diri tapi tidak berlebihan, 3-4 kalimat.\n\n'
        'Angka yang WAJIB dipakai apa adanya, jangan diubah dan jangan ditambah '
        'angka baru:\n'
        f'- surplus pangan diselamatkan: {a.total_weight_kg} kg\n'
        f'- emisi dihindari: {a.total_co2_kg} kg CO2eq\n'
        f'- porsi diselamatkan: {a.meals_rescued}\n'
        f'- nilai ekonomi dipulihkan: Rp {_rupiah(a.total_revenue_recovered)}\n'
        f"- periode: {a.period_start or '-'} sampai {a.period_end or '-'}\n"
        f"- nama usaha: {a.merchant_name or 'tidak disebut'}\n\n"
        f'Sebagai acuan gaya, ini versi datarnya: {dasar}\n\n'
        'Balas JSON saja: {"narasi": "<paragraf>"}'
    )


def narasi_esg(a) -> dict:
    dasar = template(a)
    if not gemini.tersedia():
        return {'narrative': dasar, 'source': 'template'}

    try:
        teks = gemini.minta_teks(_prompt(a, dasar), timeout=6.0)
    except Exception:      # noqa: BLE001
        return {'narrative': dasar, 'source': 'template'}

    if not teks:
        return {'narrative': dasar, 'source': 'template'}

    data = gemini.json_pertama(teks)
    narasi = str((data or {}).get('narasi') or '').strip()
    if not narasi:
        return {'narrative': dasar, 'source': 'template'}
    return {'narrative': narasi, 'source': 'gemini'}
