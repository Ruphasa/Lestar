"""Pemuatan model sekali di startup.

Model dimuat lewat `lifespan`, bukan per request — memuat ulang `.keras` di
setiap panggilan menambah detik yang langsung terlihat saat demo.

Kegagalan memuat bukan alasan untuk mati. Runtime yang gagal tetap sah;
`loaded=False` membuat /health mengaku `degraded` dan /forecast turun ke
heuristik sisi server.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Runtime:
    path: str
    loaded: bool = False
    model: object | None = None
    scalers: dict = field(default_factory=dict)
    metrics: dict | None = None
    error: str | None = None


def _baca_json(p: Path) -> dict | None:
    try:
        return json.loads(p.read_text(encoding='utf-8'))
    except Exception:
        return None


def muat(path: str) -> Runtime:
    rt = Runtime(path=path)
    berkas = Path(path)
    folder = berkas.parent

    rt.scalers = _baca_json(folder / 'scalers.json') or {'per_merchant': {}, 'global': {'porsi': 70.0, 'surplus': 2.5}}
    rt.metrics = _baca_json(folder / 'metrics.json')

    if not berkas.exists():
        rt.error = f'berkas model tidak ada: {path}'
        return rt

    try:
        from tensorflow import keras     # impor di sini supaya kegagalan TF tidak mematikan proses
        rt.model = keras.models.load_model(berkas, compile=False)
        rt.loaded = True
    except Exception as e:               # noqa: BLE001 — apa pun yang gagal, layanan tetap hidup
        rt.error = f'{type(e).__name__}: {e}'
    return rt
