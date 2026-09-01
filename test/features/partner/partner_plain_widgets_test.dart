import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/plain.dart';
import 'package:lestar/core/theme/tokens.dart';
import 'package:lestar/features/partner/presentation/widgets/partner_plain_widgets.dart';

void main() {
  testWidgets('tombol utama pengepul setinggi 140 dp dan hijau pekat', (
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
          body: PartnerPrimaryButton(
            key: const Key('tombol-utama'),
            label: 'JEMPUT\nSEKARANG',
            icon: Icons.local_shipping_outlined,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('tombol-utama'))).height, 140);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      LestarTokens.emeraldDeep,
    );
    expect(tester.takeException(), isNull);
  });
}
