import 'enums.dart';
import 'json.dart';

/// Tabel `forecasts` — hasil Buffer Intelligence untuk satu merchant, satu hari.
///
/// [source] wajib jujur. Kalau angkanya lahir dari `FallbackEngine`, nilainya
/// `heuristic` — bukan `lstm_only`, bukan dikosongkan.
class Forecast {
  const Forecast({
    required this.id,
    required this.merchantId,
    required this.forecastDate,
    required this.demandX,
    required this.surplusProbabilityY,
    this.surplusVolumeEstKg,
    required this.recommendedProduction,
    this.confidence,
    this.narrative,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String merchantId;

  /// Kolom `date`, bukan `timestamptz`.
  final DateTime forecastDate;

  /// Permintaan yang diperkirakan, dalam porsi.
  final double demandX;

  /// 0..1.
  final double surplusProbabilityY;

  final double? surplusVolumeEstKg;
  final int recommendedProduction;
  final double? confidence;
  final String? narrative;
  final ForecastSource source;
  final DateTime createdAt;

  bool get dariModel => source != ForecastSource.heuristic;

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    forecastDate: dateWajib(json['forecast_date']),
    demandX: toDouble(json['demand_x']),
    surplusProbabilityY: toDouble(json['surplus_probability_y']),
    surplusVolumeEstKg: toDoubleOpsional(json['surplus_volume_est_kg']),
    recommendedProduction: toInt(json['recommended_production']),
    confidence: toDoubleOpsional(json['confidence']),
    narrative: toStrOpsional(json['narrative']),
    source: ForecastSource.parse(json['source']),
    createdAt: dtWajib(json['created_at']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'merchant_id': merchantId,
    'forecast_date': dateKeWire(forecastDate),
    'demand_x': demandX,
    'surplus_probability_y': surplusProbabilityY,
    'surplus_volume_est_kg': surplusVolumeEstKg,
    'recommended_production': recommendedProduction,
    'confidence': confidence,
    'narrative': narrative,
    'source': source.wire,
  });

  Forecast copyWith({
    double? demandX,
    double? surplusProbabilityY,
    double? surplusVolumeEstKg,
    int? recommendedProduction,
    double? confidence,
    String? narrative,
    ForecastSource? source,
  }) => Forecast(
    id: id,
    merchantId: merchantId,
    forecastDate: forecastDate,
    demandX: demandX ?? this.demandX,
    surplusProbabilityY: surplusProbabilityY ?? this.surplusProbabilityY,
    surplusVolumeEstKg: surplusVolumeEstKg ?? this.surplusVolumeEstKg,
    recommendedProduction:
        recommendedProduction ?? this.recommendedProduction,
    confidence: confidence ?? this.confidence,
    narrative: narrative ?? this.narrative,
    source: source ?? this.source,
    createdAt: createdAt,
  );
}
