import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/constants.dart';
import 'package:lestar/core/theme/dark_glass.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/widgets/widgets.dart';

void main() {
  test('akurasi model mengikuti metrics Agent C', () {
    expect(LestarConstants.modelAkurasi, 0.9227);
    expect(LestarConstants.modelDasarUji, 'data sintetis');
  });

  test('tema merchant memakai latar hijau gelap', () {
    expect(
      DarkGlassTheme.data.scaffoldBackgroundColor,
      const Color(0xFF10140F),
    );
    expect(DarkGlassTheme.data.colorScheme.primary, const Color(0xFF00BC7D));
    expect(DarkGlassTheme.data.colorScheme.secondary, const Color(0xFFF38222));
  });

  testWidgets('SourceBadge memakai tiga label merchant yang jujur', (
    tester,
  ) async {
    for (final entry in <ForecastSource, String>{
      ForecastSource.lstmGemini: 'AI · LSTM + Gemini',
      ForecastSource.lstmOnly: 'AI · LSTM',
      ForecastSource.heuristic: 'Mode offline · heuristik',
    }.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: DarkGlassTheme.data,
          home: Scaffold(
            body: Center(child: SourceBadge(source: entry.key)),
          ),
        ),
      );
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
