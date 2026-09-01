import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:lestar/core/api/api_models.dart';
import 'package:lestar/core/supabase/session.dart';
import 'package:lestar/core/theme/dark_glass.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/features/merchant/application/merchant_esg_controller.dart';
import 'package:lestar/features/merchant/application/merchant_home_controller.dart';
import 'package:lestar/features/merchant/application/merchant_inventory_controller.dart';
import 'package:lestar/features/merchant/presentation/merchant_esg_screen.dart';
import 'package:lestar/features/merchant/presentation/merchant_home_screen.dart';
import 'package:lestar/features/merchant/presentation/merchant_inventory_screen.dart';
import 'package:lestar/features/merchant/presentation/merchant_scan_screen.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_esg_widgets.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_forecast_card.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_inventory_widgets.dart';
import 'package:lestar/features/partner/application/partner_dashboard_controller.dart';
import 'package:lestar/features/partner/presentation/partner_home_screen.dart';
import 'package:lestar/features/partner/presentation/partner_langganan_screen.dart';
import 'package:lestar/features/partner/presentation/partner_riwayat_screen.dart';
import 'package:lestar/features/partner/presentation/widgets/partner_plain_widgets.dart';
import 'package:lestar/shared/models/models.dart';

const _widths = <double>[320, 360, 412];
const _textScales = <double>[1, 1.3];
final _now = DateTime(2026, 9, 1, 18, 30);

final _merchant = Merchant(
  id: 'merchant-layout',
  storeName: 'Verde Kitchen & Artisan Bakery Nusantara',
  storeAddress: 'Jalan Soekarno Hatta Nomor 123, Kota Malang',
  lat: -7.98,
  lng: 112.63,
  category: 'restoran',
  cutoffTime: '22:00:00',
  rating: 4.9,
  totalEarnings: 987654321,
  totalWasteSavedKg: 12345.6,
  level: 8,
);

final _partner = Partner(
  id: 'partner-layout',
  orgName: 'Koperasi Pengolah Sampah Organik Sukamaju',
  partnerType: 'maggot',
  wastePreference: const [WasteType.wet],
  vehicleType: 'pickup',
  licensePlate: 'N 1234 ABC',
  serviceRadiusKm: 125,
  baseLat: -7.98,
  baseLng: 112.63,
  totalPickups: 12345,
  subscriptionExpiry: DateTime(2026, 12, 31),
);

final _partnerProfile = Profile(
  id: _partner.id,
  name: 'Pak Budi Santoso',
  email: 'budi@lestar.id',
  role: UserRole.partner,
  ecoPoints: 0,
  createdAt: _now,
);

final _history = List<SalesHistory>.generate(
  7,
  (index) => SalesHistory(
    id: 'history-$index',
    merchantId: _merchant.id,
    date: _now.subtract(Duration(days: index + 1)),
    portionsSold: 44 + index,
    revenue: 12345678,
    dayOfWeek: index,
    isHoliday: false,
    weatherCode: index % 4,
    surplusKg: 2.5 + index,
  ),
);

final _forecast = Forecast(
  id: 'forecast-layout',
  merchantId: _merchant.id,
  forecastDate: DateTime(2026, 9, 2),
  demandX: 9876,
  surplusProbabilityY: 0.92,
  surplusVolumeEstKg: 1234.5,
  recommendedProduction: 12345,
  confidence: 0.9227,
  narrative:
      'Kurangi produksi besok secara bertahap agar surplus tetap aman dan '
      'seluruh bahan baku bernilai tinggi dapat dimanfaatkan.',
  source: ForecastSource.lstmGemini,
  createdAt: _now,
);

final _esgAggregate = EsgAggregate(
  totalWeightKg: 12345.6,
  totalCo2Kg: 9876.5,
  totalRevenueRecovered: 987654321,
  mealsRescued: 123456,
  periodStart: DateTime(2026, 8),
  periodEnd: DateTime(2026, 8, 31),
);

final _esgReport = EsgReport(
  id: 'report-layout',
  merchantId: _merchant.id,
  periodStart: DateTime(2026, 8),
  periodEnd: DateTime(2026, 8, 31),
  totalWeightKg: 12345.6,
  totalCo2Kg: 9876.5,
  totalRevenueRecovered: 987654321,
  mealsRescued: 123456,
  narrative:
      'Seluruh dampak berasal dari transaksi yang tercatat dan dapat diaudit. '
      'Pemanfaatan surplus membantu mitra menjaga produksi tetap efisien.',
  createdAt: _now,
);

final _listing = Listing(
  id: 'listing-layout',
  merchantId: _merchant.id,
  name: 'Assorted Butter Croissant Premium Panggang Hari Ini',
  description: 'Produk uji layout dengan nama dan deskripsi yang panjang.',
  category: 'roti',
  qtyTotal: 12345,
  qtyRemaining: 9876,
  originalPrice: 987654321,
  price: 456789012,
  cookedAt: _now.subtract(const Duration(hours: 6)),
  expiresAt: _now.add(const Duration(hours: 3)),
  triageScore: 92,
  triageReason: 'Aman setelah pemeriksaan fisik.',
  physicalValidated: true,
  status: ListingStatus.cascaded,
  createdAt: _now,
);

final _wasteBatch = WasteBatch(
  id: 'waste-layout',
  sourceMerchantId: _merchant.id,
  sourceListingId: _listing.id,
  wasteType: WasteType.wet,
  description: 'Sisa bahan organik untuk mitra pengolahan.',
  weightKg: 125.4,
  price: 12345678,
  pickupAddress: _merchant.storeAddress,
  lat: _merchant.lat,
  lng: _merchant.lng,
  pickupWindowStart: _now,
  pickupWindowEnd: _now.add(const Duration(hours: 2)),
  status: WasteStatus.completed,
  matchedPartnerId: _partner.id,
  createdAt: _now,
  completedAt: _now.add(const Duration(hours: 1)),
);

final _nearbyWaste = NearbyWaste(
  id: _wasteBatch.id,
  sourceMerchantId: _merchant.id,
  storeName: _merchant.storeName,
  sourceListingId: _listing.id,
  wasteType: WasteType.wet,
  description: _wasteBatch.description,
  weightKg: _wasteBatch.weightKg,
  price: _wasteBatch.price,
  pickupAddress: _wasteBatch.pickupAddress,
  lat: _wasteBatch.lat,
  lng: _wasteBatch.lng,
  pickupWindowStart: _wasteBatch.pickupWindowStart,
  pickupWindowEnd: _wasteBatch.pickupWindowEnd,
  status: WasteStatus.available,
  createdAt: _wasteBatch.createdAt,
  jarakKm: 123.4,
);

final _merchantHomeData = MerchantHomeData(
  merchant: _merchant,
  forecast: _forecast,
  history: _history,
  esg: _esgAggregate,
  listingCount: 123456,
);

MerchantEsgData _esgData({required bool saved}) => MerchantEsgData(
  report: _esgReport,
  eventCount: 123456,
  fromCache: saved,
  saved: saved,
);

final _b2cSubmission = TriageSubmission(
  name: _listing.name,
  category: _listing.category,
  quantity: _listing.qtyTotal,
  cookedAt: _listing.cookedAt,
  originalPrice: _listing.originalPrice,
  imageUrl: '',
  triage: const TriageResult(
    score: 92,
    route: 'b2c',
    reason:
        'Kategori roti masih berada dalam umur simpan dan wajib diperiksa '
        'langsung sebelum ditayangkan.',
  ),
);

final _b2bSubmission = TriageSubmission(
  name: 'Sisa dapur campuran untuk pengolahan mitra',
  category: 'nasi_lauk',
  quantity: 12345,
  cookedAt: _now.subtract(const Duration(hours: 16)),
  originalPrice: 987654321,
  imageUrl: '',
  triage: const TriageResult(
    score: 45,
    route: 'b2b',
    reason:
        'Melewati ambang aman untuk konsumen dan harus dialihkan ke jalur B2B.',
  ),
);

typedef _SurfaceBuilder = Widget Function();
typedef _SurfaceExercise = Future<void> Function(WidgetTester tester);
typedef _SurfaceVerifier =
    void Function(WidgetTester tester, double width, double textScale);

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  group('merchant layout sweep', () {
    _sweepSurface(
      name: 'MerchantHomeScreen',
      theme: DarkGlassTheme.data,
      builder: () => ProviderScope(
        overrides: [
          currentMerchantProvider.overrideWith((ref) async => _merchant),
          merchantHomeProvider(
            _merchant.id,
          ).overrideWith((ref) async => _merchantHomeData),
        ],
        child: const MerchantHomeScreen(),
      ),
    );
    _sweepSurface(
      name: 'MerchantInventoryScreen listings',
      theme: DarkGlassTheme.data,
      builder: _merchantInventoryScreen,
    );
    _sweepSurface(
      name: 'MerchantInventoryScreen form',
      theme: DarkGlassTheme.data,
      builder: _merchantInventoryScreen,
      exercise: (tester) async {
        await tester.tap(find.text('Surplus'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
    _sweepSurface(
      name: 'MerchantScanScreen',
      theme: DarkGlassTheme.data,
      builder: () => const MerchantScanScreen(),
    );
    _sweepSurface(
      name: 'MerchantScanScreen manual dialog',
      theme: DarkGlassTheme.data,
      builder: () => const MerchantScanScreen(),
      exercise: (tester) async {
        await tester.tap(find.text('Masukkan kode manual'));
        await tester.pumpAndSettle();
      },
    );
    _sweepSurface(
      name: 'MerchantEsgScreen',
      theme: DarkGlassTheme.data,
      builder: () => ProviderScope(
        overrides: [
          currentMerchantProvider.overrideWith((ref) async => _merchant),
          merchantEsgProvider(
            _merchant.id,
          ).overrideWith((ref) async => _esgData(saved: true)),
        ],
        child: const MerchantEsgScreen(),
      ),
    );
    _sweepSurface(
      name: 'MerchantForecastCard applied',
      theme: DarkGlassTheme.data,
      scroll: true,
      builder: () => MerchantForecastCard(
        forecast: _forecast,
        history: _history,
        applied: true,
        onApply: () {},
      ),
    );
    _sweepSurface(
      name: 'FoodSafetyResultCard B2C',
      theme: DarkGlassTheme.data,
      scroll: true,
      builder: () => FoodSafetyResultCard(
        submission: _b2cSubmission,
        busy: false,
        onValidate: () {},
        onRouteB2b: () {},
      ),
    );
    _sweepSurface(
      name: 'FoodSafetyResultCard B2B',
      theme: DarkGlassTheme.data,
      scroll: true,
      builder: () => FoodSafetyResultCard(
        submission: _b2bSubmission,
        busy: false,
        onValidate: () {},
        onRouteB2b: () {},
      ),
    );
    _sweepSurface(
      name: 'MerchantListingList populated',
      theme: DarkGlassTheme.data,
      scroll: true,
      builder: () =>
          MerchantListingList(listings: [_listing], waste: [_wasteBatch]),
    );
    _sweepSurface(
      name: 'MerchantListingList empty',
      theme: DarkGlassTheme.data,
      builder: () => const MerchantListingList(listings: [], waste: []),
    );
    _sweepSurface(
      name: 'MerchantEsgReportView saved',
      theme: DarkGlassTheme.data,
      builder: () =>
          MerchantEsgReportView(data: _esgData(saved: true), onExport: () {}),
    );
    _sweepSurface(
      name: 'MerchantEsgReportView unsaved',
      theme: DarkGlassTheme.data,
      builder: () =>
          MerchantEsgReportView(data: _esgData(saved: false), onExport: () {}),
    );
  });

  group('partner layout sweep', () {
    _sweepSurface(
      name: 'PartnerHomeScreen',
      theme: PlainTheme.data,
      builder: () => ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) async => _partnerProfile),
          currentPartnerProvider.overrideWith((ref) async => _partner),
          partnerNearbyWasteProvider(
            _partner,
          ).overrideWith((ref) => Stream.value([_nearbyWaste])),
        ],
        child: const PartnerHomeScreen(),
      ),
    );
    _sweepSurface(
      name: 'PartnerRiwayatScreen',
      theme: PlainTheme.data,
      builder: () => ProviderScope(
        overrides: [
          currentPartnerProvider.overrideWith((ref) async => _partner),
          partnerHistoryProvider(_partner.id).overrideWith(
            (ref) => Stream.value([
              PartnerHistoryItem(
                batch: _wasteBatch,
                storeName: _merchant.storeName,
              ),
            ]),
          ),
        ],
        child: const PartnerRiwayatScreen(),
      ),
    );
    _sweepSurface(
      name: 'PartnerLanggananScreen',
      theme: PlainTheme.data,
      builder: () => ProviderScope(
        overrides: [
          currentPartnerProvider.overrideWith((ref) async => _partner),
        ],
        child: const PartnerLanggananScreen(),
      ),
    );
    _sweepSurface(
      name: 'PartnerAvailableView',
      theme: PlainTheme.data,
      builder: () => PartnerAvailableView(
        name: _partnerProfile.name,
        waste: [_nearbyWaste],
        onPickup: () {},
        onShowMap: () {},
      ),
      verify: (tester, width, textScale) {
        if (width == 320 && textScale == 1.3) {
          final weight = tester.widget<Text>(find.text('125,4 KG'));
          expect(weight.style?.fontSize, 90);
        }
      },
    );
    for (final status in [WasteStatus.matched, WasteStatus.pickedUp]) {
      _sweepSurface(
        name: 'PartnerJourneyView ${status.wire}',
        theme: PlainTheme.data,
        builder: () => PartnerJourneyView(
          destination: _nearbyWaste,
          status: status,
          onOpenMap: () {},
          onAdvance: () {},
        ),
      );
    }
    _sweepSurface(
      name: 'PartnerEmptyView',
      theme: PlainTheme.data,
      builder: () => PartnerEmptyView(onShowMap: () {}),
    );
    _sweepSurface(
      name: 'PartnerWasteMapView',
      theme: PlainTheme.data,
      builder: () => PartnerWasteMapView(
        center: LatLng(_partner.baseLat, _partner.baseLng),
        waste: [_nearbyWaste],
        onBack: () {},
        onSelect: (_) {},
      ),
    );
    _sweepSurface(
      name: 'PartnerLoadError',
      theme: PlainTheme.data,
      builder: () => const PartnerLoadError(
        message:
            'DATA PENGEPUL BELUM DAPAT DIMUAT. PERIKSA KONEKSI DAN COBA LAGI.',
      ),
    );
    _sweepSurface(
      name: 'PartnerHistoryView populated',
      theme: PlainTheme.data,
      builder: () => PartnerHistoryView(
        items: [
          PartnerHistoryItem(
            batch: _wasteBatch,
            storeName: _merchant.storeName,
          ),
        ],
        now: _now,
      ),
    );
    _sweepSurface(
      name: 'PartnerHistoryView empty',
      theme: PlainTheme.data,
      builder: () => PartnerHistoryView(items: const [], now: _now),
    );
    _sweepSurface(
      name: 'PartnerSubscriptionView active',
      theme: PlainTheme.data,
      builder: () => PartnerSubscriptionView(
        partner: _partner,
        busy: false,
        onExtend: () {},
      ),
    );
    _sweepSurface(
      name: 'PartnerSubscriptionView inactive',
      theme: PlainTheme.data,
      builder: () => PartnerSubscriptionView(
        partner: Partner(
          id: 'inactive-partner',
          orgName: _partner.orgName,
          wastePreference: _partner.wastePreference,
          serviceRadiusKm: _partner.serviceRadiusKm,
          baseLat: _partner.baseLat,
          baseLng: _partner.baseLng,
          totalPickups: 0,
        ),
        busy: false,
        onExtend: () {},
      ),
    );
    _sweepSurface(
      name: 'PartnerPrimaryButton',
      theme: PlainTheme.data,
      builder: () => Padding(
        padding: const EdgeInsets.all(24),
        child: PartnerPrimaryButton(
          label: 'JEMPUT\nSEKARANG',
          icon: Icons.local_shipping_outlined,
          onPressed: () {},
        ),
      ),
      verify: (tester, width, textScale) {
        expect(tester.getSize(find.byType(PartnerPrimaryButton)).height, 140);
      },
    );
    _sweepSurface(
      name: 'PartnerOutlineButton',
      theme: PlainTheme.data,
      builder: () => Padding(
        padding: const EdgeInsets.all(24),
        child: PartnerOutlineButton(
          label: 'LIHAT PETA SEKITAR',
          icon: Icons.map_outlined,
          onPressed: () {},
        ),
      ),
    );
    _sweepSurface(
      name: 'PartnerSectionCard',
      theme: PlainTheme.data,
      builder: () => const Padding(
        padding: EdgeInsets.all(24),
        child: PartnerSectionCard(
          child: Text('INFORMASI PENTING UNTUK PENGEPUL DAN MITRA PENGOLAHAN'),
        ),
      ),
    );
    _sweepSurface(
      name: 'PartnerScreenTitle',
      theme: PlainTheme.data,
      builder: () => const Padding(
        padding: EdgeInsets.all(24),
        child: PartnerScreenTitle('RIWAYAT PENJEMPUTAN'),
      ),
    );
    _sweepSurface(
      name: 'PartnerStatTile',
      theme: PlainTheme.data,
      builder: () => const Padding(
        padding: EdgeInsets.all(24),
        child: PartnerStatTile(
          label: 'PERKIRAAN HEMAT BIAYA BULAN INI',
          value: 'Rp 987.654.321',
          icon: Icons.savings_outlined,
        ),
      ),
    );
  });
}

Widget _merchantInventoryScreen() => ProviderScope(
  overrides: [
    currentMerchantProvider.overrideWith((ref) async => _merchant),
    merchantListingsProvider(
      _merchant.id,
    ).overrideWith((ref) => Stream.value([_listing])),
    merchantWasteProvider(
      _merchant.id,
    ).overrideWith((ref) => Stream.value([_wasteBatch])),
  ],
  child: const MerchantInventoryScreen(),
);

void _sweepSurface({
  required String name,
  required ThemeData theme,
  required _SurfaceBuilder builder,
  _SurfaceExercise? exercise,
  _SurfaceVerifier? verify,
  bool scroll = false,
}) {
  for (final width in _widths) {
    for (final textScale in _textScales) {
      testWidgets(
        '$name | ${width.toInt()} dp | text ${textScale.toStringAsFixed(1)}',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final surface = builder();
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: Scaffold(
                body: scroll ? SingleChildScrollView(child: surface) : surface,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 700));
          _expectNoException(tester, name, width, textScale);

          if (exercise != null) {
            await exercise(tester);
            _expectNoException(tester, name, width, textScale);
          }
          verify?.call(tester, width, textScale);
        },
      );
    }
  }
}

void _expectNoException(
  WidgetTester tester,
  String surface,
  double width,
  double textScale,
) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason:
        '$surface overflow/exception at ${width.toInt()} dp and '
        'text scale ${textScale.toStringAsFixed(1)}: $exception',
  );
}
