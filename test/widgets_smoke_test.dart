import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lestar/core/theme/theme_for_role.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/widgets/widgets.dart';

Widget bungkus(Widget w, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? LightGlassTheme.data,
  home: Scaffold(body: w),
);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('DiscountPill menampilkan persen bulat', (t) async {
    await t.pumpWidget(bungkus(const DiscountPill(percent: 0.52)));
    expect(find.text('-52%'), findsOneWidget);
  });

  testWidgets('PriceText mencoret harga asli', (t) async {
    await t.pumpWidget(
      bungkus(const PriceText(price: 12000, originalPrice: 25000)),
    );
    expect(find.text('Rp 12.000'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsOneWidget);
  });

  testWidgets('PriceText tanpa harga asli hanya menampilkan satu harga', (
    t,
  ) async {
    await t.pumpWidget(bungkus(const PriceText(price: 8000)));
    expect(find.text('Rp 8.000'), findsOneWidget);
    expect(find.textContaining('Rp'), findsOneWidget);
  });

  testWidgets('SourceBadge jujur saat heuristik', (t) async {
    await t.pumpWidget(
      bungkus(const SourceBadge(source: ForecastSource.heuristic)),
    );
    expect(find.text('Perkiraan lokal'), findsOneWidget);
  });

  testWidgets('SourceBadge membedakan hasil model', (t) async {
    await t.pumpWidget(
      bungkus(const SourceBadge(source: ForecastSource.lstmGemini)),
    );
    expect(find.text('Prediksi AI'), findsOneWidget);
  });

  testWidgets('CountdownChip menampilkan sisa waktu, dan Habis saat lewat', (
    t,
  ) async {
    await t.pumpWidget(
      bungkus(
        CountdownChip(
          // +2 detik supaya pembulatan ke bawah tidak menjadikannya 2j 14m
          // pada mikrodetik pertama setelah widget dibangun.
          expiresAt: DateTime.now().add(
            const Duration(hours: 2, minutes: 15, seconds: 2),
          ),
        ),
      ),
    );
    expect(find.text('2j 15m'), findsOneWidget);

    await t.pumpWidget(
      bungkus(
        CountdownChip(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ),
    );
    expect(find.text('Habis'), findsOneWidget);
  });

  testWidgets('EmptyState dan OfflineBanner terpasang', (t) async {
    await t.pumpWidget(
      bungkus(
        const Column(
          children: [
            OfflineBanner(offline: true),
            EmptyState(
              title: 'Belum ada apa-apa',
              message: 'Coba lagi nanti.',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Belum ada apa-apa'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('OfflineBanner menghilang saat online', (t) async {
    await t.pumpWidget(bungkus(const OfflineBanner(offline: false)));
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('BigButton memanggil onPressed sekali', (t) async {
    var n = 0;
    await t.pumpWidget(bungkus(BigButton(label: 'Beli', onPressed: () => n++)));
    await t.tap(find.text('Beli'));
    expect(n, 1);
  });

  testWidgets('BigButton saat loading menolak tekanan', (t) async {
    var n = 0;
    await t.pumpWidget(
      bungkus(BigButton(label: 'Beli', loading: true, onPressed: () => n++)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.tap(find.byType(BigButton));
    expect(n, 0);
  });

  testWidgets('StatTile menampilkan label, nilai, dan satuan', (t) async {
    await t.pumpWidget(
      bungkus(
        const StatTile(label: 'Radar hari ini', value: '25', unit: 'KG'),
      ),
    );
    expect(find.text('Radar hari ini'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
  });

  testWidgets('QrDisplay menampilkan caption', (t) async {
    await t.pumpWidget(
      bungkus(
        const QrDisplay(
          data: 'token-uji',
          size: 120,
          caption: 'Tunjukkan ke kasir',
        ),
      ),
    );
    expect(find.text('Tunjukkan ke kasir'), findsOneWidget);
  });

  testWidgets('tiga kartu bisa dipakai bergantian dengan tema masing-masing', (
    t,
  ) async {
    var ditekan = 0;
    for (final (kartu, tema) in <(Widget, ThemeData)>[
      (
        GlassCard(
          onTap: () => ditekan++,
          child: const Text('kartu'),
        ),
        LightGlassTheme.data,
      ),
      (
        DarkGlassCard(
          onTap: () => ditekan++,
          child: const Text('kartu'),
        ),
        DarkGlassTheme.data,
      ),
      (
        PlainCard(onTap: () => ditekan++, child: const Text('kartu')),
        PlainTheme.data,
      ),
    ]) {
      await t.pumpWidget(bungkus(kartu, theme: tema));
      expect(find.text('kartu'), findsOneWidget);
      await t.tap(find.text('kartu'));
    }
    expect(ditekan, 3);
  });
}
