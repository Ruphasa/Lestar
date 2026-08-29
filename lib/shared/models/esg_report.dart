import 'json.dart';

/// Tabel `esg_reports` — hasil agregasi satu periode yang disimpan permanen,
/// beserta narasi dan (kalau sudah dibuat) berkas PDF-nya.
class EsgReport {
  const EsgReport({
    required this.id,
    required this.merchantId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalWeightKg,
    required this.totalCo2Kg,
    required this.totalRevenueRecovered,
    required this.mealsRescued,
    this.narrative,
    this.pdfUrl,
    required this.createdAt,
  });

  final String id;
  final String merchantId;

  /// Kolom `date`, bukan `timestamptz`.
  final DateTime periodStart;
  final DateTime periodEnd;

  final double totalWeightKg;
  final double totalCo2Kg;
  final double totalRevenueRecovered;
  final int mealsRescued;
  final String? narrative;

  /// Bucket `esg-reports` bersifat privat — URL-nya perlu ditandatangani.
  final String? pdfUrl;

  final DateTime createdAt;

  factory EsgReport.fromJson(Map<String, dynamic> json) => EsgReport(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    periodStart: dateWajib(json['period_start']),
    periodEnd: dateWajib(json['period_end']),
    totalWeightKg: toDouble(json['total_weight_kg']),
    totalCo2Kg: toDouble(json['total_co2_kg']),
    totalRevenueRecovered: toDouble(json['total_revenue_recovered']),
    mealsRescued: toInt(json['meals_rescued']),
    narrative: toStrOpsional(json['narrative']),
    pdfUrl: toStrOpsional(json['pdf_url']),
    createdAt: dtWajib(json['created_at']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'merchant_id': merchantId,
    'period_start': dateKeWire(periodStart),
    'period_end': dateKeWire(periodEnd),
    'total_weight_kg': totalWeightKg,
    'total_co2_kg': totalCo2Kg,
    'total_revenue_recovered': totalRevenueRecovered,
    'meals_rescued': mealsRescued,
    'narrative': narrative,
    'pdf_url': pdfUrl,
  });

  EsgReport copyWith({String? narrative, String? pdfUrl}) => EsgReport(
    id: id,
    merchantId: merchantId,
    periodStart: periodStart,
    periodEnd: periodEnd,
    totalWeightKg: totalWeightKg,
    totalCo2Kg: totalCo2Kg,
    totalRevenueRecovered: totalRevenueRecovered,
    mealsRescued: mealsRescued,
    narrative: narrative ?? this.narrative,
    pdfUrl: pdfUrl ?? this.pdfUrl,
    createdAt: createdAt,
  );
}
