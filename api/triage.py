"""Triage keamanan pangan — deterministik, bukan LLM.

Keamanan pangan tidak boleh bergantung pada model probabilistik. `score` dan
`route` di sini tidak pernah disentuh Gemini; hanya `reason` yang boleh
diperkaya, dan itu pun terjadi di lapisan lain.

Kembaran persis `FallbackEngine.triage` di lib/core/fallback_engine.dart.
Rumus: docs/04-ai-pipeline.md §4.
"""

from constants import AMBANG_TRIAGE_B2C, KATEGORI_CEPAT_RUSAK, round_half_away, shelf_life


def hitung_triage(kategori: str, jam_sejak_masak: float, ambient_temp: float) -> dict:
    shelf = shelf_life(kategori)

    score = 100.0
    score -= (jam_sejak_masak / shelf) * 60
    if ambient_temp > 30:
        score -= 15
    if kategori in KATEGORI_CEPAT_RUSAK:
        score -= 20

    skor = max(0, min(100, round_half_away(score)))
    rute = 'b2c' if skor >= AMBANG_TRIAGE_B2C else 'b2b'

    return {'score': skor, 'route': rute, 'reason': _alasan(kategori, jam_sejak_masak, shelf, ambient_temp, skor)}


def _alasan(kategori: str, jam: float, shelf: int, suhu: float, skor: int) -> str:
    bagian = [f'Dimasak {round_half_away(jam)} jam lalu, kategori {kategori} tahan {shelf} jam.']
    bagian.append(
        f'Suhu {round_half_away(suhu)}°C di atas normal.' if suhu > 30 else 'Kondisi suhu normal.'
    )
    if kategori in KATEGORI_CEPAT_RUSAK:
        bagian.append('Kategori ini cepat rusak, skor diturunkan.')
    bagian.append(
        'Masih aman dijual ke konsumen.' if skor >= AMBANG_TRIAGE_B2C else 'Sebaiknya dialihkan ke jalur B2B.'
    )
    return ' '.join(bagian)
