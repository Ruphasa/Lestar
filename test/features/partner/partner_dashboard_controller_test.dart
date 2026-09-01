import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/features/partner/application/partner_dashboard_controller.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/providers.dart';
import 'package:lestar/shared/repositories/waste_repository.dart';

void main() {
  test(
    'snapshot realtime memuat ulang RPC dan tetap menyaring preferensi',
    () async {
      final repository = _ReloadingWasteRepository([
        _row('wet-1', WasteType.wet),
        _row('dry-1', WasteType.dry),
      ]);
      final partner = Partner(
        id: 'partner-1',
        orgName: 'Maggot Berkah Malang',
        wastePreference: const [WasteType.wet],
        serviceRadiusKm: 10,
        baseLat: -7.98,
        baseLng: 112.63,
        totalPickups: 0,
      );
      final container = ProviderContainer(
        overrides: [wasteRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(
        partnerNearbyWasteProvider(partner),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() async {
        subscription.close();
        container.dispose();
        await repository.dispose();
      });

      final initial = await container.read(
        partnerNearbyWasteProvider(partner).future,
      );
      expect(initial.map((row) => row.id), ['wet-1']);
      expect(repository.nearbyCalls, 1);
      await _waitUntil(() => repository.hasRealtimeListener);

      repository.rows = [
        _row('wet-2', WasteType.wet),
        _row('dry-2', WasteType.dry),
      ];
      repository.emitChange();
      await _waitUntil(() => repository.nearbyCalls == 2);

      final reloaded = container.read(partnerNearbyWasteProvider(partner));
      expect(reloaded.value?.map((row) => row.id), ['wet-2']);
    },
  );
}

NearbyWaste _row(String id, WasteType type) => NearbyWaste(
  id: id,
  sourceMerchantId: 'merchant-$id',
  storeName: 'Toko $id',
  wasteType: type,
  weightKg: 5,
  price: 0,
  pickupAddress: 'Jl. Uji 1',
  lat: -7.98,
  lng: 112.63,
  status: WasteStatus.available,
  createdAt: DateTime(2026, 9, 1),
  jarakKm: 1,
);

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: 'pemuatan ulang realtime tidak terjadi');
}

class _ReloadingWasteRepository extends WasteRepository {
  _ReloadingWasteRepository(this.rows);

  List<NearbyWaste> rows;
  int nearbyCalls = 0;
  final _changes = StreamController<List<WasteBatch>>.broadcast();

  @override
  Future<List<NearbyWaste>> nearbyWaste({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    nearbyCalls += 1;
    return rows;
  }

  @override
  Stream<List<WasteBatch>> availableStream() => _changes.stream;

  bool get hasRealtimeListener => _changes.hasListener;

  void emitChange() => _changes.add(const []);

  Future<void> dispose() => _changes.close();
}
