import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/supabase/session.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

class MerchantHomeData {
  const MerchantHomeData({
    required this.merchant,
    required this.forecast,
    required this.history,
    required this.esg,
    required this.listingCount,
  });

  final Merchant merchant;
  final Forecast forecast;
  final List<SalesHistory> history;
  final EsgAggregate esg;
  final int listingCount;
}

final merchantHomeProvider = FutureProvider.family<MerchantHomeData, String>((
  ref,
  merchantId,
) async {
  final merchant = await ref.watch(currentMerchantProvider.future);
  if (merchant == null || merchant.id != merchantId) {
    throw StateError('Data merchant tidak ditemukan.');
  }
  final forecastRepository = ref.watch(forecastRepositoryProvider);
  final forecastDate = _tanggalBesok();

  // Cache-first adalah bagian dari kontrak demo. Jangan memanggil API untuk
  // menyegarkan baris yang sudah tersimpan.
  var forecast = await forecastRepository.getForecast(
    merchant.id,
    forecastDate,
  );
  final history = await forecastRepository.recentSalesHistory(merchant.id);

  if (forecast == null) {
    final result = await ref
        .watch(lestarApiProvider)
        .forecast(
          merchantId: merchant.id,
          history: history,
          targetDate: forecastDate,
          // Kontrak Agent B masih mewajibkan int. Gunakan observasi terbaru,
          // bukan angka tampilan yang di-hardcode.
          weatherCode: history.isEmpty ? 0 : history.first.weatherCode ?? 0,
          merchantContext: {
            'name': merchant.storeName,
            'category': merchant.category,
            'lat': merchant.lat,
            'lng': merchant.lng,
          },
        );
    final generated = result.keForecast(
      merchantId: merchant.id,
      forecastDate: forecastDate,
    );
    try {
      forecast = await forecastRepository.saveForecast(generated);
    } catch (_) {
      // Angka fallback tetap berguna ketika penyimpanan gagal karena jaringan.
      forecast = generated;
    }
  }

  // Dashboard demo memakai bulan kalender terakhir yang sudah lengkap.
  // Pada 1 September ini berarti 1–31 Agustus, sehingga KPI tidak berubah
  // menjadi nol hanya karena bulan baru dimulai.
  final now = DateTime.now();
  final periodStart = DateTime(now.year, now.month - 1);
  final periodEnd = DateTime(
    now.year,
    now.month,
  ).subtract(const Duration(microseconds: 1));
  final esg = await ref
      .watch(esgRepositoryProvider)
      .aggregate(merchant.id, periodStart, periodEnd);
  final listings = await ref
      .watch(listingRepositoryProvider)
      .merchantListingsSekali(merchant.id);

  return MerchantHomeData(
    merchant: merchant,
    forecast: forecast,
    history: history,
    esg: esg,
    listingCount: listings.length,
  );
});

DateTime _tanggalBesok() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
}
