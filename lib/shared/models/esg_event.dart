import 'enums.dart';
import 'json.dart';

/// Tabel `esg_events` — **baca saja dari aplikasi.**
///
/// Baris lahir sendiri dari trigger saat `orders.status` jadi `claimed` dan
/// `waste_batches.status` jadi `completed`. Menulis manual akan ditolak
/// `unique (event_type, ref_id)`. Karena itu tidak ada `toJson` di sini.
class EsgEvent {
  const EsgEvent({
    required this.id,
    required this.merchantId,
    required this.eventType,
    required this.refId,
    required this.weightKg,
    required this.co2SavedKg,
    required this.revenueRecovered,
    required this.occurredAt,
  });

  final String id;
  final String merchantId;
  final EsgEventType eventType;

  /// `orders.id` untuk `b2c_rescued`, `waste_batches.id` untuk `b2b_diverted`.
  final String refId;

  final double weightKg;
  final double co2SavedKg;
  final double revenueRecovered;
  final DateTime occurredAt;

  factory EsgEvent.fromJson(Map<String, dynamic> json) => EsgEvent(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    eventType: EsgEventType.parse(json['event_type']),
    refId: toStr(json['ref_id']),
    weightKg: toDouble(json['weight_kg']),
    co2SavedKg: toDouble(json['co2_saved_kg']),
    revenueRecovered: toDouble(json['revenue_recovered']),
    occurredAt: dtWajib(json['occurred_at']),
  );
}

/// Hasil penjumlahan [EsgEvent] satu periode. Dihitung di sisi klien oleh
/// `EsgRepository.aggregate`, bukan RPC baru — wilayah SQL milik Agent A.
class EsgAggregate {
  const EsgAggregate({
    required this.totalWeightKg,
    required this.totalCo2Kg,
    required this.totalRevenueRecovered,
    required this.mealsRescued,
    required this.periodStart,
    required this.periodEnd,
  });

  final double totalWeightKg;
  final double totalCo2Kg;
  final double totalRevenueRecovered;

  /// Jumlah peristiwa `b2c_rescued` — porsi yang benar-benar dimakan orang.
  final int mealsRescued;

  final DateTime periodStart;
  final DateTime periodEnd;

  /// Periode tanpa satu pun peristiwa.
  factory EsgAggregate.kosong(DateTime start, DateTime end) => EsgAggregate(
    totalWeightKg: 0,
    totalCo2Kg: 0,
    totalRevenueRecovered: 0,
    mealsRescued: 0,
    periodStart: start,
    periodEnd: end,
  );

  Map<String, dynamic> toJson() => {
    'total_weight_kg': totalWeightKg,
    'total_co2_kg': totalCo2Kg,
    'total_revenue_recovered': totalRevenueRecovered,
    'meals_rescued': mealsRescued,
  };
}
