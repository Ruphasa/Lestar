"""Gemini 2.5 Flash — kalibrasi konteks dan narasi.

Dua tugas, bukan pajangan: menggeser angka LSTM dalam batas sempit, dan
mengubah angka jadi kalimat Bahasa Indonesia.

**Gemini tidak pernah mengarang angka dari nol dan tidak pernah menyentuh
keputusan keamanan pangan.** Batas geseran ±20% dari angka LSTM ditegakkan di
`kalibrasi()`; di luar batas, seluruh keluarannya dibuang — angka dan
kalimatnya sekaligus, karena kalimat yang lahir dari angka yang ditolak tidak
boleh ikut dipakai.

Dipanggil lewat REST dengan httpx, bukan lewat SDK `google-generativeai`.
Satu dependensi berat lebih sedikit di image, dan kontrol timeout langsung di
tangan kita.
"""

from __future__ import annotations

import json
import os
import re

import httpx

MODEL = 'gemini-2.5-flash'
URL = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent'
BATAS_GESERAN = 0.20

# TIMEOUT sempat 3,0 detik dan membuat /forecast SELALU jatuh ke lstm_only:
# gemini-2.5-flash menyalakan "thinking" secara default dan butuh ~9 detik untuk
# prompt ini. Diukur 31 Agu 2026 — 5,8 s sampai 9,0 s, tidak pernah di bawah 3 s.
#
# thinkingConfig.thinkingBudget=0 mematikan penalaran bertahap dan memangkasnya
# jadi ~1,3 detik. Kalibrasi tetap hidup: konteks hari libur nasional tetap
# menggeser 98 menjadi 110 (+12,2%), masih di dalam pita BATAS_GESERAN. Tugas
# di sini memang bukan penalaran panjang — hanya menggeser satu angka dalam
# batas sempit dan menuliskan satu kalimat.
#
# TIMEOUT 6,0 detik memberi ruang lebih dari empat kali latensi terukur, dan
# tetap muat di dalam timeout klien Flutter yang 4 detik untuk jalur cache-miss
# berikutnya. Nilai ini sama dengan yang sudah dipakai esg.py.
TIMEOUT = 6.0

# Dipakai di minta_teks(); menguntungkan /forecast maupun /esg-narrative.
THINKING_OFF = {'thinkingBudget': 0}


def tersedia() -> bool:
    return bool(os.getenv('GEMINI_API_KEY'))


def minta_teks(prompt: str, timeout: float = TIMEOUT) -> str | None:
    """Satu panggilan generateContent. Mengembalikan None kalau apa pun gagal."""
    kunci = os.getenv('GEMINI_API_KEY')
    if not kunci:
        return None
    try:
        r = httpx.post(
            URL,
            params={'key': kunci},
            json={
                'contents': [{'parts': [{'text': prompt}]}],
                'generationConfig': {
                    'temperature': 0.4,
                    'responseMimeType': 'application/json',
                    'thinkingConfig': THINKING_OFF,
                },
            },
            timeout=timeout,
        )
        if r.status_code != 200:
            return None
        return r.json()['candidates'][0]['content']['parts'][0]['text']
    except Exception:      # noqa: BLE001 — timeout, kuota habis, DNS: semuanya lstm_only
        return None


def json_pertama(teks: str) -> dict | None:
    try:
        return json.loads(teks)
    except Exception:
        pass
    m = re.search(r'\{.*\}', teks, re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except Exception:
        return None


def _prompt(lstm_demand: float, k: dict) -> str:
    return (
        'Kamu asisten peramalan permintaan untuk warung dan kafe di Indonesia.\n'
        f'Model LSTM memprediksi permintaan besok {lstm_demand:.0f} porsi.\n'
        f"Tanggal target: {k.get('target_date')} ({k.get('nama_hari')}).\n"
        f"Cuaca: {k.get('cuaca')}. Hari libur nasional: {k.get('is_holiday')}.\n"
        f"Merchant: {k.get('nama') or 'tidak disebut'}, kategori {k.get('kategori') or 'umum'}.\n"
        f"Probabilitas surplus dari model: {k.get('surplus_y')}.\n\n"
        'Tugasmu: sesuaikan angka LSTM itu berdasarkan konteks di atas, '
        f'maksimal {int(BATAS_GESERAN * 100)}% naik atau turun. '
        'Jangan menghitung angka dari nol — angka LSTM adalah titik awalnya.\n'
        'Balas JSON saja: {"demand": <angka>, "narasi": "<satu-dua kalimat '
        'Bahasa Indonesia untuk pemilik warung>"}'
    )


def kalibrasi(lstm_demand: float, konteks: dict) -> tuple[float, str, str]:
    """Kembalikan (demand, narasi, source).

    `source` 'lstm_gemini' hanya kalau Gemini menjawab, angkanya terbaca, dan
    geserannya <= 20%. Semua jalur lain 'lstm_only'.
    """
    template = konteks.get('narasi_template', '')

    if not tersedia() or lstm_demand <= 0:
        return lstm_demand, template, 'lstm_only'

    try:
        teks = minta_teks(_prompt(lstm_demand, konteks))
    except Exception:      # noqa: BLE001
        return lstm_demand, template, 'lstm_only'

    if not teks:
        return lstm_demand, template, 'lstm_only'

    data = json_pertama(teks)
    if not isinstance(data, dict):
        return lstm_demand, template, 'lstm_only'

    try:
        demand = float(data['demand'])
    except (KeyError, TypeError, ValueError):
        return lstm_demand, template, 'lstm_only'

    if demand <= 0 or abs(demand - lstm_demand) / lstm_demand > BATAS_GESERAN:
        return lstm_demand, template, 'lstm_only'

    narasi = str(data.get('narasi') or '').strip()
    if not narasi:
        return demand, template, 'lstm_gemini'
    return demand, narasi, 'lstm_gemini'
