import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/theme/light_glass.dart';
import 'package:lestar/core/theme/tokens.dart';
import 'package:lestar/features/consumer/presentation/widgets/consumer_widgets.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/widgets/widgets.dart';

NearbyListing _listing({double discount = .64, String? imageUrl}) {
  final original = 100000.0;
  return NearbyListing(
    id: 'listing-1',
    merchantId: 'merchant-1',
    storeName: 'Verde Kitchen dengan nama cukup panjang',
    storeAddress: 'Jl. Soekarno Hatta 12, Malang',
    name: 'Assorted Butter Croissant Premium',
    category: 'roti',
    imageUrl: imageUrl,
    qtyRemaining: 12,
    originalPrice: original,
    price: original * (1 - discount),
    cookedAt: DateTime.now().subtract(const Duration(hours: 2)),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
    lat: -7.98,
    lng: 112.63,
    jarakKm: .4,
  );
}

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('pill diskon membesar mengikuti nilai diskon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightGlassTheme.data,
        home: const Scaffold(
          body: Row(
            children: [
              DiscountPill(key: Key('small'), percent: .30),
              DiscountPill(key: Key('large'), percent: .70),
            ],
          ),
        ),
      ),
    );

    final small = tester.getSize(find.byKey(const Key('small')));
    final large = tester.getSize(find.byKey(const Key('large')));
    expect(large.height, greaterThan(small.height));
    expect(large.width, greaterThan(small.width));
  });

  testWidgets('harga baru memakai orangeText pada tema terang', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightGlassTheme.data,
        home: const Scaffold(
          body: PriceText(price: 32000, originalPrice: 88000),
        ),
      ),
    );

    final price = tester.widget<Text>(find.text('Rp 32.000'));
    expect(price.style?.color, LestarTokens.orangeText);
  });

  testWidgets('placeholder dan kartu deal aman pada lebar HP', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: LightGlassTheme.data,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ConsumerDealCard(listing: _listing(), onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('food-placeholder')), findsOneWidget);
    expect(find.textContaining('Assorted Butter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marker diskon memakai oranye dan teks gelap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LightGlassTheme.data,
        home: Scaffold(
          body: Center(child: ConsumerDiscountMarker(listing: _listing())),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ConsumerDiscountMarker),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.color, LestarTokens.orange);
    expect(find.text('-64%'), findsOneWidget);
  });
}
