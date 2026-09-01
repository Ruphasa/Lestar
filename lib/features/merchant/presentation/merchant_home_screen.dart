import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fallback_engine.dart';
import '../../../core/supabase/session.dart';
import '../../../core/theme/dark_glass.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/merchant_home_controller.dart';
import 'widgets/merchant_forecast_card.dart';

class MerchantHomeScreen extends ConsumerStatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  ConsumerState<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends ConsumerState<MerchantHomeScreen>
    with WidgetsBindingObserver {
  Forecast? _offlineForecast;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshConnectivity();
  }

  Future<void> _refreshConnectivity() async {
    final merchant = ref.read(currentMerchantProvider).value;
    if (merchant == null) return;
    final data = ref.read(merchantHomeProvider(merchant.id)).value;
    if (data == null || data.history.isEmpty) return;

    var online = false;
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 2));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }
    if (!mounted) return;

    if (online) {
      setState(() => _offlineForecast = null);
      return;
    }

    final result = FallbackEngine.forecast(
      history: data.history,
      targetDate: data.forecast.forecastDate,
      weatherCode: data.history.first.weatherCode ?? 0,
    );
    setState(
      () => _offlineForecast = result.keForecast(
        merchantId: merchant.id,
        forecastDate: data.forecast.forecastDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantProvider);
    return merchantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(
        message: 'Data merchant belum dapat dimuat.',
        onRetry: () => ref.invalidate(currentMerchantProvider),
      ),
      data: (merchant) {
        if (merchant == null) {
          return const EmptyState(title: 'Akun merchant tidak ditemukan');
        }
        final homeAsync = ref.watch(merchantHomeProvider(merchant.id));
        return homeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: 'Dashboard belum dapat dimuat. Periksa koneksi Anda.',
            onRetry: () => ref.invalidate(merchantHomeProvider(merchant.id)),
          ),
          data: (data) => _Dashboard(
            data: data,
            forecast: _offlineForecast ?? data.forecast,
            offline: _offlineForecast != null,
            applied: _applied,
            onApply: () {
              setState(() => _applied = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Rencana produksi ${data.forecast.recommendedProduction} '
                    'diterapkan untuk sesi ini.',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.data,
    required this.forecast,
    required this.offline,
    required this.applied,
    required this.onApply,
  });

  final MerchantHomeData data;
  final Forecast forecast;
  final bool offline;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      OfflineBanner(
        offline: offline,
        message: 'Mode offline aktif — rekomendasi dihitung di perangkat.',
      ),
      Expanded(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _MerchantIdentity(merchant: data.merchant),
            const SizedBox(height: 28),
            Text(
              'Dashboard',
              style: LestarType.judulLayar(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Live operations · ${Fmt.tanggal(DateTime.now())}',
              style: LestarType.isi(
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 20),
            MerchantForecastCard(
              forecast: forecast,
              history: data.history,
              applied: applied,
              onApply: onApply,
            ),
            const SizedBox(height: 14),
            _KpiGrid(data: data),
          ],
        ),
      ),
    ],
  );
}

class _MerchantIdentity extends StatelessWidget {
  const _MerchantIdentity({required this.merchant});

  final Merchant merchant;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: DarkGlassTheme.badge,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.storefront, color: LestarTokens.emerald),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              merchant.storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LestarType.display(
                size: 19,
                wght: 700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Merchant Console',
              style: LestarType.body(
                size: 13,
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ],
        ),
      ),
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: DarkGlassTheme.tile,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none, color: Colors.white70),
            Positioned(
              top: 9,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: LestarTokens.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final MerchantHomeData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 20) / 3;
      return Row(
        children: [
          SizedBox(
            width: width,
            child: _KpiTile(
              value: Fmt.rupiah(data.esg.totalRevenueRecovered),
              label: 'Nilai dipulihkan',
              color: LestarTokens.orange,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: width,
            child: _KpiTile(
              value: Fmt.kg(data.esg.totalWeightKg),
              label: 'Waste diverted',
              color: LestarTokens.emerald,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: width,
            child: _KpiTile(
              value: Fmt.angka(data.listingCount),
              label: 'Items listed',
              color: Colors.white,
            ),
          ),
        ],
      );
    },
  );
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 126),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DarkGlassTheme.tile,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: LestarType.display(size: 23, wght: 700, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LestarType.body(
            size: 12,
            color: Colors.white.withValues(alpha: 0.42),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'Belum dapat memuat data',
    message: message,
    icon: Icons.cloud_off_outlined,
    action: FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
  );
}
