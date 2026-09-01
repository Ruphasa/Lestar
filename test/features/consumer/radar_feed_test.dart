import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/supabase/session.dart';
import 'package:lestar/core/theme/light_glass.dart';
import 'package:lestar/features/consumer/application/consumer_providers.dart';
import 'package:lestar/features/consumer/presentation/feed_screen.dart';
import 'package:lestar/features/consumer/presentation/radar_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/listing_repository.dart';
import 'package:lestar/shared/repositories/providers.dart';

NearbyListing _listing(String id, {double discount = .64}) => NearbyListing(
  id: id,
  merchantId: 'merchant-$id',
  storeName: id == 'a' ? 'Verde Kitchen' : 'Rue Bakehouse',
  storeAddress: 'Jl. Besar 12',
  name: id == 'a' ? 'Croissant Butter' : 'Nasi Bento',
  category: id == 'a' ? 'roti' : 'nasi_lauk',
  qtyRemaining: 8,
  originalPrice: 100000,
  price: 100000 * (1 - discount),
  cookedAt: DateTime.now().subtract(const Duration(hours: 1)),
  expiresAt: DateTime.now().add(const Duration(hours: 3)),
  lat: -7.98,
  lng: 112.63,
  jarakKm: id == 'a' ? .4 : 1.2,
);

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('radar merender RPC listing dan aman pada 390 dp', (
    tester,
  ) async {
    final repository = _FakeListingRepository([_listing('a'), _listing('b')]);
    addTearDown(repository.dispose);
    await _pump(tester, const RadarScreen(), repository);

    expect(find.text('Live Flash Radar'), findsOneWidget);
    expect(find.text('Croissant Butter'), findsWidgets);
    expect(find.text('-64%'), findsWidgets);
    expect(find.text('Flash deals · segera berakhir'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(repository.lastLat, -7.9826);
    expect(repository.lastRadius, 5);
  });

  testWidgets('listing baru muncul setelah stream realtime memicu RPC', (
    tester,
  ) async {
    final repository = _FakeListingRepository([_listing('a')]);
    addTearDown(repository.dispose);
    await _pump(tester, const RadarScreen(), repository);
    expect(find.text('Nasi Bento'), findsNothing);

    repository.rows = [_listing('a'), _listing('b', discount: .52)];
    repository.emitRealtime();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 321));

    expect(find.text('Nasi Bento'), findsWidgets);
    expect(repository.rpcCalls, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed punya keadaan kosong yang jelas', (tester) async {
    final repository = _FakeListingRepository([]);
    addTearDown(repository.dispose);
    await _pump(tester, const FeedScreen(), repository);

    expect(find.text('Belum ada deal aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  _FakeListingRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final profile = Profile(
    id: 'consumer-1',
    name: 'Amira Rahmadani',
    email: 'amira@lestar.id',
    role: UserRole.consumer,
    ecoPoints: 1240,
    createdAt: DateTime(2026, 9, 1),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => profile),
        listingRepositoryProvider.overrideWithValue(repository),
        consumerLocationServiceProvider.overrideWithValue(
          const _FakeLocation(),
        ),
      ],
      child: MaterialApp(
        theme: LightGlassTheme.data,
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

class _FakeLocation implements ConsumerLocationService {
  const _FakeLocation();

  @override
  Future<ConsumerLocation> current() async => ConsumerLocation.malangFallback;
}

class _FakeListingRepository extends ListingRepository {
  _FakeListingRepository(this.rows);

  List<NearbyListing> rows;
  final _stream = StreamController<List<Listing>>.broadcast();
  int rpcCalls = 0;
  double? lastLat;
  double? lastRadius;

  @override
  Future<List<NearbyListing>> nearbyListings({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    rpcCalls++;
    lastLat = lat;
    lastRadius = radiusKm;
    return rows;
  }

  @override
  Stream<List<Listing>> liveListingsStream() => _stream.stream;

  void emitRealtime() => _stream.add(const []);
  Future<void> dispose() => _stream.close();
}
