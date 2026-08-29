import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// `esg_events` (baca saja) + `esg_reports`.
///
/// Baris `esg_events` lahir dari trigger saat `orders.status` jadi `claimed`
/// dan `waste_batches.status` jadi `completed`. Repository ini tidak punya
/// metode tulis untuk tabel itu — sengaja: `unique (event_type, ref_id)` akan
/// menolaknya, dan angka ESG hanya boleh datang dari peristiwa nyata.
class EsgRepository {
  Future<List<EsgEvent>> eventsInPeriod(
    String merchantId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await supabase
        .from('esg_events')
        .select()
        .eq('merchant_id', merchantId)
        .gte('occurred_at', start.toUtc().toIso8601String())
        .lte('occurred_at', end.toUtc().toIso8601String())
        .order('occurred_at', ascending: false);
    return rows.map(EsgEvent.fromJson).toList();
  }

  /// Dijumlahkan di sisi klien, bukan lewat RPC baru — `supabase/` adalah
  /// wilayah Agent A, dan jumlah peristiwa satu merchant per periode kecil
  /// (40 baris untuk seluruh data seed).
  Future<EsgAggregate> aggregate(
    String merchantId,
    DateTime start,
    DateTime end,
  ) async {
    final events = await eventsInPeriod(merchantId, start, end);
    if (events.isEmpty) return EsgAggregate.kosong(start, end);

    return EsgAggregate(
      totalWeightKg: events.fold(0, (a, e) => a + e.weightKg),
      totalCo2Kg: events.fold(0, (a, e) => a + e.co2SavedKg),
      totalRevenueRecovered: events.fold(0, (a, e) => a + e.revenueRecovered),
      mealsRescued: events
          .where((e) => e.eventType == EsgEventType.b2cRescued)
          .length,
      periodStart: start,
      periodEnd: end,
    );
  }

  Future<EsgReport> saveReport(EsgReport report) async {
    final row = await supabase
        .from('esg_reports')
        .insert(report.toJson())
        .select()
        .single();
    return EsgReport.fromJson(row);
  }

  Future<List<EsgReport>> reportsOf(String merchantId) async {
    final rows = await supabase
        .from('esg_reports')
        .select()
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);
    return rows.map(EsgReport.fromJson).toList();
  }
}
