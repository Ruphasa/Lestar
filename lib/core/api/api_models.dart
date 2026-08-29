import '../../shared/models/json.dart';
import '../../shared/models/models.dart';

/// Hasil `/forecast`, atau hasil `FallbackEngine.forecast` kalau server tidak
/// terjangkau. [source] membedakan keduanya dan tidak pernah dipoles.
class ForecastResult {
  const ForecastResult({
    required this.demandX,
    required this.surplusProbabilityY,
    required this.surplusVolumeEstKg,
    required this.recommendedProduction,
    required this.confidence,
    required this.narrative,
    required this.source,
  });

  final int demandX;
  final double surplusProbabilityY;
  final double? surplusVolumeEstKg;
  final int recommendedProduction;
  final double confidence;
  final String narrative;
  final ForecastSource source;

  bool get fromFallback => source == ForecastSource.heuristic;

  factory ForecastResult.fromJson(Map<String, dynamic> json) => ForecastResult(
    demandX: toInt(json['demand_x']),
    surplusProbabilityY: toDouble(json['surplus_probability_y']),
    surplusVolumeEstKg: toDoubleOpsional(json['surplus_volume_est_kg']),
    recommendedProduction: toInt(json['recommended_production']),
    confidence: toDouble(json['confidence']),
    narrative: toStr(json['narrative']),
    source: ForecastSource.parse(json['source']),
  );

  /// Bentuk yang siap disimpan ke tabel `forecasts`.
  Forecast keForecast({
    required String merchantId,
    required DateTime forecastDate,
  }) => Forecast(
    id: '',
    merchantId: merchantId,
    forecastDate: forecastDate,
    demandX: demandX.toDouble(),
    surplusProbabilityY: surplusProbabilityY,
    surplusVolumeEstKg: surplusVolumeEstKg,
    recommendedProduction: recommendedProduction,
    confidence: confidence,
    narrative: narrative,
    source: source,
    createdAt: DateTime.now(),
  );
}

/// Hasil `/triage`. `score` dan `route` **tidak pernah** disentuh LLM —
/// keamanan pangan tidak boleh bergantung pada model probabilistik.
class TriageResult {
  const TriageResult({
    required this.score,
    required this.route,
    required this.reason,
    this.fromFallback = false,
  });

  final int score;

  /// `'b2c'` atau `'b2b'`.
  final String route;

  /// Boleh diperkaya Gemini; kalau server mati, ini kalimat lokal.
  final String reason;

  /// True kalau angkanya lahir dari `FallbackEngine`, bukan dari server.
  final bool fromFallback;

  bool get keB2c => route == 'b2c';

  factory TriageResult.fromJson(Map<String, dynamic> json) => TriageResult(
    score: toInt(json['score']),
    route: toStr(json['route'], 'b2b'),
    reason: toStr(json['reason']),
  );
}

/// Hasil `/pricing`. Deterministik, sama persis dengan versi Python.
class PricingResult {
  const PricingResult({
    required this.diskon,
    required this.harga,
    this.fromFallback = false,
  });

  /// 0..0.70.
  final double diskon;

  /// Sudah dibulatkan ke kelipatan Rp500.
  final double harga;

  final bool fromFallback;

  int get diskonPersen => (diskon * 100).round();

  factory PricingResult.fromJson(Map<String, dynamic> json) => PricingResult(
    diskon: toDouble(json['diskon'] ?? json['discount']),
    harga: toDouble(json['harga'] ?? json['price']),
  );
}
