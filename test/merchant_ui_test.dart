import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/api/api_models.dart';
import 'package:lestar/core/theme/dark_glass.dart';
import 'package:lestar/features/merchant/application/merchant_esg_controller.dart';
import 'package:lestar/features/merchant/application/merchant_inventory_controller.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_esg_widgets.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_forecast_card.dart';
import 'package:lestar/features/merchant/presentation/widgets/merchant_inventory_widgets.dart';
import 'package:lestar/shared/models/models.dart';

Widget _app(Widget child) => MaterialApp(
  theme: DarkGlassTheme.data,
  home: Scaffold(body: child),
);

void main() {
  // `Fmt.tanggal` memakai DateFormat locale id_ID. Di aplikasi, main.dart
  // memanggil initializeDateFormatting sebelum runApp; widget test merender
  // widget langsung tanpa melewati main(), jadi harus dipanggil sendiri.
  // E dan F akan bertemu hal yang sama begitu menyentuh Fmt.tanggal atau jam.
  setUpAll(() async => initializeDateFormatting('id_ID'));

  // Setiap test menyetel lebar HP sendiri lewat `tester.view.physicalSize`.
  // Itu disengaja: surface bawaan 800x600 lebih lebar dari HP mana pun, dan
  // overflow di laporan ESG hanya muncul di bawah ~400 dp.

  testWidgets('forecast card memuat akurasi, sumber, dan tujuh hari', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 9, 1);
    final history = List.generate(
      7,
      (index) => SalesHistory(
        id: '$index',
        merchantId: 'merchant',
        date: now.subtract(Duration(days: index + 1)),
        portionsSold: 44 + index,
        revenue: 1000000,
        dayOfWeek: (now.weekday - index - 2) % 7,
        isHoliday: false,
        weatherCode: 0,
        surplusKg: 1.2,
      ),
    );
    final forecast = Forecast(
      id: 'forecast',
      merchantId: 'merchant',
      forecastDate: now.add(const Duration(days: 1)),
      demandX: 48,
      surplusProbabilityY: 0.32,
      surplusVolumeEstKg: 2.4,
      recommendedProduction: 58,
      confidence: 0.92,
      narrative: 'Produksi aman dengan buffer yang terukur.',
      source: ForecastSource.lstmGemini,
      createdAt: now,
    );

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: MerchantForecastCard(
            forecast: forecast,
            history: history,
            applied: false,
            onApply: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('48 kg'), findsOneWidget);
    expect(find.text('92% · data sintetis'), findsOneWidget);
    expect(find.text('AI · LSTM + Gemini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skor di bawah 70 tidak pernah menawarkan validasi B2C', (
    tester,
  ) async {
    final submission = TriageSubmission(
      name: 'Sisa dapur',
      category: 'nasi_lauk',
      quantity: 8,
      cookedAt: DateTime(2026, 9, 1, 13),
      originalPrice: 50000,
      imageUrl: 'https://example.invalid/photo.jpg',
      triage: const TriageResult(
        score: 45,
        route: 'b2b',
        reason: 'Melewati ambang aman untuk konsumen.',
      ),
    );

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: FoodSafetyResultCard(
            submission: submission,
            busy: false,
            onValidate: () {},
            onRouteB2b: () {},
          ),
        ),
      ),
    );

    expect(find.text('Alihkan ke Jalur B2B'), findsOneWidget);
    expect(find.text('Validasi Kondisi Fisik Aman'), findsNothing);
  });

  testWidgets('hasil B2C selalu memuat pernyataan pemeriksaan fisik', (
    tester,
  ) async {
    final submission = TriageSubmission(
      name: 'Croissant',
      category: 'roti',
      quantity: 12,
      cookedAt: DateTime(2026, 9, 1, 13),
      originalPrice: 88000,
      imageUrl: 'https://example.invalid/photo.jpg',
      triage: const TriageResult(
        score: 80,
        route: 'b2c',
        reason: 'Kategori roti masih berada dalam umur simpan.',
      ),
    );

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: FoodSafetyResultCard(
            submission: submission,
            busy: false,
            onValidate: () {},
            onRouteB2b: () {},
          ),
        ),
      ),
    );

    expect(find.text('Validasi Kondisi Fisik Aman'), findsOneWidget);
    expect(find.textContaining('aroma, tekstur, dan tampilan'), findsOneWidget);
  });

  testWidgets('laporan ESG merender hanya angka report yang tersimpan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = EsgReport(
      id: 'report',
      merchantId: 'merchant',
      periodStart: DateTime(2026, 8, 1),
      periodEnd: DateTime(2026, 8, 31),
      totalWeightKg: 32,
      totalCo2Kg: 8,
      totalRevenueRecovered: 384000,
      mealsRescued: 128,
      narrative: 'Dampak ini berasal dari transaksi yang tercatat.',
      createdAt: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(
      _app(
        MerchantEsgReportView(
          data: MerchantEsgData(
            report: report,
            eventCount: 24,
            fromCache: true,
            saved: true,
          ),
          onExport: () {},
        ),
      ),
    );

    expect(find.text('32,0 kg'), findsOneWidget);
    expect(find.text('8,0 kg'), findsOneWidget);
    expect(find.text('Rp 384.000'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.textContaining('24 baris esg_events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
