"""Lestar API — stateless, tanpa koneksi database.

Flutter yang menulis hasil ke Supabase. Layanan ini hanya menghitung.
Kontrak endpoint: docs/04-ai-pipeline.md §4.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from pricing import hitung_pricing
from schemas import (
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
STATUS: dict = {
    'model_loaded': False,
    'model_path': os.getenv('MODEL_PATH', './model/lestar_lstm.keras'),
    'metrics': None,
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Tugas 6 memuat model di sini, sekali saat startup — bukan per request.
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
