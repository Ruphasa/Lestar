import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/supabase/session.dart';
import 'package:lestar/core/theme/light_glass.dart';
import 'package:lestar/features/consumer/application/consumer_providers.dart';
import 'package:lestar/features/consumer/presentation/orders_screen.dart';
import 'package:lestar/features/consumer/presentation/profile_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/auth_repository.dart';
import 'package:lestar/shared/repositories/providers.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('pesanan kosong memakai EmptyState', (tester) async {
    await _pump(tester, const OrdersScreen(), orders: const []);
    expect(find.text('Belum ada pesanan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pesanan paid menampilkan total, status, dan tombol QR', (
    tester,
  ) async {
    final order = Order(
      id: 'order-123456789',
      consumerId: 'consumer-1',
      merchantId: 'merchant-1',
      subtotal: 32000,
      greenFee: 1000,
      total: 33000,
      status: OrderStatus.paid,
      qrToken: 'token',
      qrExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      orderedAt: DateTime(2026, 9, 1),
    );
    await _pump(tester, const OrdersScreen(), orders: [order]);
    expect(find.text('Dibayar'), findsOneWidget);
    expect(find.text('Rp 33.000'), findsOneWidget);
    expect(find.text('Tampilkan QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profil tahan nama panjang dan logout memanggil repository', (
    tester,
  ) async {
    final auth = _FakeAuthRepository();
    final profile = Profile(
      id: 'consumer-1',
      name: 'Amira Rahmadani dengan Nama yang Sangat Panjang',
      email: 'amira@lestar.id',
      phone: '08123456789',
      address:
          'Jalan panjang sekali di Kota Malang yang tetap harus membungkus dengan aman',
      role: UserRole.consumer,
      ecoPoints: 0,
      createdAt: DateTime(2026, 9, 1),
    );
    await _pump(
      tester,
      const ProfileScreen(),
      profile: profile,
      auth: auth,
      width: 360,
    );
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('Keluar'));
    await tester.pump();
    expect(auth.signOutCalls, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Order>? orders,
  Profile? profile,
  AuthRepository? auth,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (orders != null)
          consumerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
        if (profile != null)
          currentProfileProvider.overrideWith((ref) async => profile),
        if (auth != null) authRepositoryProvider.overrideWithValue(auth),
      ],
      child: MaterialApp(
        theme: LightGlassTheme.data,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

class _FakeAuthRepository extends AuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
