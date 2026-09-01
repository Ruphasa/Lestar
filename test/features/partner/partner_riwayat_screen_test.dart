import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/features/partner/application/partner_dashboard_controller.dart';
import 'package:lestar/features/partner/presentation/partner_riwayat_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('riwayat menampilkan statistik dan batch selesai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final batch = WasteBatch(
      id: 'w1',
      sourceMerchantId: 'm1',
      wasteType: WasteType.wet,
      weightKg: 25,
      price: 150000,
      pickupAddress: 'Jl. Soekarno Hatta 12',
      lat: -7.98,
      lng: 112.63,
      status: WasteStatus.completed,
      matchedPartnerId: 'p1',
      createdAt: DateTime(2026, 9, 1, 21, 30),
      completedAt: DateTime(2026, 9, 1, 22),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(
          body: PartnerHistoryView(
            items: [
              PartnerHistoryItem(batch: batch, storeName: 'Verde Kitchen'),
            ],
            now: DateTime(2026, 9, 1, 23),
          ),
        ),
      ),
    );

    expect(find.text('RIWAYAT PENJEMPUTAN'), findsOneWidget);
    expect(find.text('25 KG'), findsAtLeastNWidgets(1));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('VERDE KITCHEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
