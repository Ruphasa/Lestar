import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/supabase/session.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/features/partner/presentation/partner_home_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/providers.dart';
import 'package:lestar/shared/repositories/waste_repository.dart';

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
    final weight = tester.widget<Text>(find.text('25 KG'));
    expect(weight.style?.fontSize, 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perjalanan menampilkan urutan aksi sampai selesai', (
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('keadaan kosong menawarkan peta tanpa daftar kosong', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PlainTheme.data,
        home: Scaffold(body: PartnerEmptyView(onShowMap: () {})),
      ),
    );

    expect(find.text('BELUM ADA\nSAMPAH HARI INI'), findsOneWidget);
    expect(find.text('LIHAT PETA SEKITAR'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alur jemput memanggil seluruh transisi repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rows = [
      _waste(id: 'a', weight: 8.4, distance: 1.2),
      _waste(id: 'b', weight: 16.6, distance: 1.8),
    ];
    final repository = _FakeWasteRepository(rows);
    addTearDown(repository.dispose);
    final partner = Partner(
      id: 'partner-1',
      orgName: 'Maggot Berkah Malang',
      wastePreference: const [WasteType.wet],
      serviceRadiusKm: 10,
      baseLat: -7.98,
      baseLng: 112.63,
      totalPickups: 0,
    );
    final profile = Profile(
      id: partner.id,
      name: 'Pak Budi',
      email: 'budi@lestar.id',
      role: UserRole.partner,
      ecoPoints: 0,
      createdAt: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) async => profile),
          currentPartnerProvider.overrideWith((ref) async => partner),
          wasteRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: PlainTheme.data,
          home: const Scaffold(body: PartnerHomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('JEMPUT\nSEKARANG'));
    await tester.pumpAndSettle();
    expect(repository.matchedIds, ['a', 'b']);

    await tester.tap(find.text('SUDAH SAMPAI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SELESAI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUDAH SAMPAI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SELESAI'));
    await tester.pumpAndSettle();

    expect(repository.statuses, [
      ('a', WasteStatus.pickedUp),
      ('a', WasteStatus.completed),
      ('b', WasteStatus.pickedUp),
      ('b', WasteStatus.completed),
    ]);
    expect(tester.takeException(), isNull);
  });
}

class _FakeWasteRepository extends WasteRepository {
  _FakeWasteRepository(this.rows);

  final List<NearbyWaste> rows;
  final matchedIds = <String>[];
  final statuses = <(String, WasteStatus)>[];
  final _changes = StreamController<List<WasteBatch>>.broadcast();

  @override
  Future<List<NearbyWaste>> nearbyWaste({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async => rows;

  @override
  Stream<List<WasteBatch>> availableStream() => _changes.stream;

  @override
  Future<WasteBatch> matchPartner(String batchId, String partnerId) async {
    matchedIds.add(batchId);
    return _batch(batchId, WasteStatus.matched, partnerId);
  }

  @override
  Future<WasteBatch> updateStatus(String batchId, WasteStatus status) async {
    statuses.add((batchId, status));
    return _batch(batchId, status, 'partner-1');
  }

  WasteBatch _batch(String id, WasteStatus status, String partnerId) {
    final row = rows.singleWhere((item) => item.id == id);
    return WasteBatch(
      id: row.id,
      sourceMerchantId: row.sourceMerchantId,
      sourceListingId: row.sourceListingId,
      wasteType: row.wasteType,
      description: row.description,
      weightKg: row.weightKg,
      price: row.price,
      pickupAddress: row.pickupAddress,
      lat: row.lat,
      lng: row.lng,
      pickupWindowStart: row.pickupWindowStart,
      pickupWindowEnd: row.pickupWindowEnd,
      imageUrl: row.imageUrl,
      status: status,
      matchedPartnerId: partnerId,
      createdAt: row.createdAt,
      completedAt: status == WasteStatus.completed
          ? DateTime(2026, 9, 1, 22)
          : null,
    );
  }

  Future<void> dispose() => _changes.close();
}
