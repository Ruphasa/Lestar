import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/supabase/session.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

class MerchantEsgData {
  const MerchantEsgData({
    required this.report,
    required this.eventCount,
    required this.fromCache,
    required this.saved,
  });

  final EsgReport report;
  final int eventCount;
  final bool fromCache;
  final bool saved;
}

final merchantEsgProvider = FutureProvider.family<MerchantEsgData, String>((
  ref,
  merchantId,
) async {
  final merchant = await ref.watch(currentMerchantProvider.future);
  if (merchant == null || merchant.id != merchantId) {
    throw StateError('Data merchant tidak ditemukan.');
  }

  final now = DateTime.now();
  // Laporan selalu menutup bulan kalender terakhir. Ini menjaga angka dapat
  // diaudit dan cocok dengan alur demo 1–31 Agustus pada 1 September.
  final start = DateTime(now.year, now.month - 1);
  final reportEnd = DateTime(now.year, now.month, 0);
  final eventEnd = DateTime(
    now.year,
    now.month,
  ).subtract(const Duration(microseconds: 1));
  final repository = ref.watch(esgRepositoryProvider);

  // Cache laporan dibaca sebelum agregasi atau panggilan Gemini.
  final reports = await repository.reportsOf(merchantId);
  EsgReport? cached;
  for (final report in reports) {
    if (_sameDate(report.periodStart, start) &&
        _sameDate(report.periodEnd, reportEnd)) {
      cached = report;
      break;
    }
  }

  if (cached != null) {
    var eventCount = 0;
    try {
      eventCount = (await repository.eventsInPeriod(
        merchantId,
        start,
        eventEnd,
      )).length;
    } catch (_) {
      // Cache laporan tetap harus dapat tampil walau audit count gagal dimuat.
    }
    return MerchantEsgData(
      report: cached,
      eventCount: eventCount,
      fromCache: true,
      saved: true,
    );
  }

  final events = await repository.eventsInPeriod(merchantId, start, eventEnd);
  final aggregate = _aggregate(events, start, reportEnd);
  final narrative = await ref
      .watch(lestarApiProvider)
      .esgNarrative(
        agregat: {
          ...aggregate.toJson(),
          'merchant_name': merchant.storeName,
          'period_start': _dateWire(start),
          'period_end': _dateWire(reportEnd),
        },
      );
  final generated = EsgReport(
    id: '',
    merchantId: merchantId,
    periodStart: start,
    periodEnd: reportEnd,
    totalWeightKg: aggregate.totalWeightKg,
    totalCo2Kg: aggregate.totalCo2Kg,
    totalRevenueRecovered: aggregate.totalRevenueRecovered,
    mealsRescued: aggregate.mealsRescued,
    narrative: narrative,
    createdAt: DateTime.now(),
  );
  try {
    final saved = await repository.saveReport(generated);
    return MerchantEsgData(
      report: saved,
      eventCount: events.length,
      fromCache: false,
      saved: true,
    );
  } catch (_) {
    return MerchantEsgData(
      report: generated,
      eventCount: events.length,
      fromCache: false,
      saved: false,
    );
  }
});

EsgAggregate _aggregate(List<EsgEvent> events, DateTime start, DateTime end) =>
    EsgAggregate(
      totalWeightKg: events.fold(0, (sum, event) => sum + event.weightKg),
      totalCo2Kg: events.fold(0, (sum, event) => sum + event.co2SavedKg),
      totalRevenueRecovered: events.fold(
        0,
        (sum, event) => sum + event.revenueRecovered,
      ),
      mealsRescued: events
          .where((event) => event.eventType == EsgEventType.b2cRescued)
          .length,
      periodStart: start,
      periodEnd: end,
    );

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateWire(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
