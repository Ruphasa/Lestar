"""Lestar API — stateless, tanpa koneksi database.

Flutter yang menulis hasil ke Supabase. Layanan ini hanya menghitung.
Kontrak endpoint: docs/04-ai-pipeline.md §4.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import model_runtime
from esg import narasi_esg
from forecast import hitung_forecast_dengan_gemini
from pricing import hitung_pricing
from schemas import (
    EsgRequest,
    EsgResponse,
    ForecastRequest,
    ForecastResponse,
    HealthResponse,
    PricingRequest,
    PricingResponse,
    TriageRequest,
    TriageResponse,
)
from triage import hitung_triage

VERSI = '1.0'

# Status runtime, diisi sekali di lifespan dan hanya dibaca setelahnya.
# /health membacanya tanpa I/O supaya balasannya di bawah 300 ms.
# `model_path` sengaja TIDAK dibaca di sini (Tugas 3 membacanya saat impor,
# yang membuat MODEL_PATH yang di-set sebelum startup tidak pernah kebaca
# kalau modul ini sudah pernah diimpor). Nilai defaultnya diisi ulang oleh
# lifespan setiap kali service (atau TestClient) start.
STATUS: dict = {
    'model_loaded': False,
    'model_path': './model/lestar_lstm.keras',
    'metrics': None,
}

RUNTIME: model_runtime.Runtime | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global RUNTIME
    STATUS['model_path'] = os.getenv('MODEL_PATH', './model/lestar_lstm.keras')
    RUNTIME = model_runtime.muat(STATUS['model_path'])
    STATUS['model_loaded'] = RUNTIME.loaded
    STATUS['metrics'] = RUNTIME.metrics
    if not RUNTIME.loaded:
        print(f'  model tidak dimuat ({RUNTIME.error}) — layanan jalan dalam mode degraded')
    yield


app = FastAPI(title='Lestar API', version=VERSI, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in os.getenv('ALLOWED_ORIGINS', '*').split(',')],
    allow_methods=['*'],
    allow_headers=['*'],
)


@app.get('/health', response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status='ok' if STATUS['model_loaded'] else 'degraded',
        model_loaded=STATUS['model_loaded'],
        model_path=STATUS['model_path'],
        gemini_configured=bool(os.getenv('GEMINI_API_KEY')),
        weather_configured=bool(os.getenv('OPENWEATHER_API_KEY')),
        metrics=STATUS['metrics'],
        version=VERSI,
    )


@app.post('/triage', response_model=TriageResponse)
def triage(req: TriageRequest) -> TriageResponse:
    return TriageResponse(**hitung_triage(req.category, req.hours_since_cooked, req.ambient_temp))


@app.post('/pricing', response_model=PricingResponse)
def pricing(req: PricingRequest) -> PricingResponse:
    return PricingResponse(
        **hitung_pricing(
            req.original_price, req.hours_left, req.hours_total, req.qty_remaining, req.qty_total
        )
    )


@app.post('/forecast', response_model=ForecastResponse)
def forecast(req: ForecastRequest) -> ForecastResponse:
    rt = RUNTIME or model_runtime.Runtime(path=STATUS['model_path'])
    return ForecastResponse(**hitung_forecast_dengan_gemini(req, rt))


@app.post('/esg-narrative', response_model=EsgResponse)
def esg_narrative(req: EsgRequest) -> EsgResponse:
    return EsgResponse(**narasi_esg(req))
