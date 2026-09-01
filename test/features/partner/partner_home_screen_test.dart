import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/features/partner/presentation/partner_home_screen.dart';
import 'package:lestar/shared/models/models.dart';

NearbyWaste _waste({
  required String id,
  required double weight,
  required double distance,
  WasteType type = WasteType.wet,
}) => NearbyWaste(
  id: id,
  sourceMerchantId: 'merchant-$id',
  storeName: id == 'a' ? 'Verde Kitchen' : 'Dapur Tetangga',
  wasteType: type,
  weightKg: weight,
  price: 0,
  pickupAddress: 'Jl. Soekarno Hatta 12',
  lat: -7.98,
  lng: 112.63,
  status: WasteStatus.available,
  createdAt: DateTime(2026, 9, 1),
  jarakKm: distance,
);

void main() {
  testWidgets('beranda menjumlahkan berat dan memakai jarak terdekat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(
          body: PartnerAvailableView(
            name: 'Pak Budi',
            waste: [
              _waste(id: 'a', weight: 8.4, distance: 1.2),
              _waste(id: 'b', weight: 16.6, distance: 1.8),
            ],
            onPickup: () {},
          ),
        ),
      ),
    );

    expect(find.text('25 KG'), findsOneWidget);
    expect(find.textContaining('1,2 KM'), findsOneWidget);
    expect(find.text('JEMPUT\nSEKARANG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perjalanan menampilkan urutan aksi sampai selesai', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(
          body: PartnerJourneyView(
            destination: _waste(id: 'a', weight: 8.4, distance: 1.2),
            status: WasteStatus.matched,
            onOpenMap: () {},
            onAdvance: () {},
          ),
        ),
      ),
    );
    expect(find.text('SEDANG MENUJU'), findsOneWidget);
    expect(find.text('SUDAH SAMPAI'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(
          body: PartnerJourneyView(
            destination: _waste(id: 'a', weight: 8.4, distance: 1.2),
            status: WasteStatus.pickedUp,
            onOpenMap: () {},
            onAdvance: () {},
          ),
        ),
      ),
    );
    expect(find.text('SELESAI'), findsOneWidget);
  });
}
