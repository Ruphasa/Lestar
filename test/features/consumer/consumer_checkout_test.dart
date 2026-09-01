import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/theme/light_glass.dart';
import 'package:lestar/features/consumer/application/consumer_providers.dart';
import 'package:lestar/features/consumer/presentation/consumer_checkout_flow.dart';
import 'package:lestar/features/consumer/presentation/qr_screen.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/order_repository.dart';
import 'package:lestar/shared/repositories/providers.dart';
import 'package:lestar/shared/widgets/qr_widgets.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets(
    'pembayaran memisahkan green fee dan menerbitkan QR setelah 1,5 detik',
    (tester) async {
      final repository = _FakeOrderRepository();
      final brightness = _FakeBrightness();
      await _pump(
        tester,
        ConsumerPaymentScreen(order: repository.pending, listing: _listing()),
        repository,
        brightness,
      );

      expect(find.text('Green Fee'), findsOneWidget);
      expect(find.text('Rp 1.000'), findsOneWidget);
      expect(find.text('Rp 33.000'), findsWidgets);
      await tester.tap(find.text('Bayar Rp 33.000'));
      await tester.pump(const Duration(milliseconds: 1499));
      expect(find.byType(QrScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Tunjukkan ke kasir'), findsOneWidget);
      expect(repository.payCalls, 1);
      expect(brightness.maximizeCalls, 1);
      expect(tester.widget<QrDisplay>(find.byType(QrDisplay)).data, 'qr-token');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(brightness.restoreCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('listing kedaluwarsa tetap tampil tetapi tombol nonaktif', (
    tester,
  ) async {
    final repository = _FakeOrderRepository();
    await _pump(
      tester,
      ListingDetailScreen(
        listing: _listing(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ),
      repository,
      _FakeBrightness(),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Penawaran berakhir'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Croissant Butter'), findsOneWidget);
  });
}

NearbyListing _listing({DateTime? expiresAt}) => NearbyListing(
  id: 'listing-1',
  merchantId: 'merchant-1',
  storeName: 'Verde Kitchen',
  storeAddress: 'Jl. Soekarno Hatta 12',
  name: 'Croissant Butter',
  category: 'roti',
  qtyRemaining: 12,
  originalPrice: 88000,
  price: 32000,
  cookedAt: DateTime.now().subtract(const Duration(hours: 2)),
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 2)),
  lat: -7.98,
  lng: 112.63,
  jarakKm: .4,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  OrderRepository repository,
  ConsumerScreenBrightness brightness,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repository),
        consumerScreenBrightnessProvider.overrideWithValue(brightness),
      ],
      child: MaterialApp(theme: LightGlassTheme.data, home: child),
    ),
  );
  await tester.pump();
}

class _FakeOrderRepository extends OrderRepository {
  int payCalls = 0;
  late final pending = Order(
    id: 'order-12345678',
    consumerId: 'consumer-1',
    merchantId: 'merchant-1',
    subtotal: 32000,
    greenFee: 1000,
    total: 33000,
    status: OrderStatus.pending,
    orderedAt: DateTime.now(),
    items: [
      OrderItem.baru(
        listingId: 'listing-1',
        nameSnapshot: 'Croissant Butter',
        qty: 1,
        unitPrice: 32000,
      ),
    ],
  );

  @override
  Future<Order> pay(String orderId, {String paymentMethod = 'simulasi'}) async {
    payCalls++;
    return pending.copyWith(
      status: OrderStatus.paid,
      qrToken: 'qr-token',
      qrExpiresAt: DateTime.now().add(const Duration(hours: 2)),
      paymentMethod: paymentMethod,
      paidAt: DateTime.now(),
    );
  }
}

class _FakeBrightness implements ConsumerScreenBrightness {
  int maximizeCalls = 0;
  int restoreCalls = 0;

  @override
  Future<void> maximize() async {
    maximizeCalls++;
  }

  @override
  Future<void> restore() async {
    restoreCalls++;
  }
}
