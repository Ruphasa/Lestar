"""Kontrak wire empat endpoint.

Nama field mengikuti `lib/core/api/lestar_api.dart` dan
`lib/core/api/api_models.dart` persis. Jangan mengganti nama apa pun di sini
tanpa mengubah Dart di commit yang sama.
"""

from typing import Literal

from pydantic import BaseModel, Field

Source = Literal['lstm_gemini', 'lstm_only', 'heuristic']


class HistoryRow(BaseModel):
    date: str
    portions_sold: int
    day_of_week: int | None = None      # 0 = Senin
    is_holiday: bool = False
    weather_code: int | None = 0
    surplus_kg: float = 0.0


class WeatherForecast(BaseModel):
    code: int = 0
    temp: float | None = None


class MerchantContext(BaseModel):
    name: str | None = None
    category: str | None = None
    lat: float | None = None
    lng: float | None = None


class ForecastRequest(BaseModel):
    merchant_id: str
    history: list[HistoryRow] = Field(default_factory=list)
    target_date: str
    weather_forecast: WeatherForecast | None = None
    merchant_context: MerchantContext | None = None


class ForecastResponse(BaseModel):
    demand_x: int
    surplus_probability_y: float
    surplus_volume_est_kg: float | None
    recommended_production: int
    confidence: float
    narrative: str
    source: Source


class TriageRequest(BaseModel):
    category: str
    hours_since_cooked: float
    ambient_temp: float


class TriageResponse(BaseModel):
    score: int
    route: Literal['b2c', 'b2b']
    reason: str


class PricingRequest(BaseModel):
    original_price: float
    hours_left: float
    hours_total: float
    qty_remaining: int
    qty_total: int


class PricingResponse(BaseModel):
    diskon: float
    harga: float


class EsgRequest(BaseModel):
    total_weight_kg: float
    total_co2_kg: float
    total_revenue_recovered: float = 0.0
    meals_rescued: int = 0
    period_start: str | None = None
    period_end: str | None = None
    merchant_name: str | None = None


class EsgResponse(BaseModel):
    narrative: str
    source: Literal['gemini', 'template']


class HealthResponse(BaseModel):
    status: Literal['ok', 'degraded']
    model_loaded: bool
    model_path: str
    gemini_configured: bool
    weather_configured: bool
    metrics: dict | None = None
    version: str
