import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/features/partner/presentation/partner_langganan_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('langganan hanya menampilkan satu tindakan perpanjang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final partner = Partner(
      id: 'p1',
      orgName: 'Maggot Berkah Malang',
      wastePreference: const [WasteType.wet],
      serviceRadiusKm: 10,
      baseLat: -7.98,
      baseLng: 112.63,
      totalPickups: 12,
      subscriptionExpiry: DateTime.now().add(const Duration(days: 20)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(
          body: PartnerSubscriptionView(
            partner: partner,
            busy: false,
            onExtend: () {},
          ),
        ),
      ),
    );

    expect(find.text('LANGGANAN AKTIF'), findsOneWidget);
    expect(find.text('PERPANJANG 30 HARI'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
