import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tema merchant — **kerangka**.
///
/// Agent D memiliki berkas ini dan mengisinya. Kaca gelap, gradien, dan
/// dekorasi dashboard adalah pekerjaan D.
///
/// Yang **tidak boleh diubah** D, karena dipakai widget bersama:
/// - `colorScheme.primary` tetap [LestarTokens.emerald] (ikon dan indikator
///   di atas latar gelap; kontrasnya baik di sana)
/// - `colorScheme.secondary` tetap [LestarTokens.orange]
/// - keluarga font tetap PlusJakartaSans (display) dan Inter (body)
class DarkGlassTheme {
  const DarkGlassTheme._();

  static final ThemeData data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LestarTokens.ink,
    colorScheme: const ColorScheme.dark(
      primary: LestarTokens.emerald,
      onPrimary: LestarTokens.ink,
      primaryContainer: LestarTokens.forest,
      onPrimaryContainer: Colors.white,
      secondary: LestarTokens.orange,
      onSecondary: LestarTokens.ink,
      secondaryContainer: LestarTokens.orangeText,
      onSecondaryContainer: Colors.white,
      surface: LestarTokens.inkSoft,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF262626),
      outline: LestarTokens.muted,
      error: LestarTokens.danger,
      onError: Colors.white,
    ),
    textTheme: LestarType.textTheme(Colors.white, LestarTokens.mutedSoft),
    cardTheme: CardThemeData(
      color: LestarTokens.inkSoft,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
      ),
    ),
    // Indikator nav dipaksa hijau. Material 3 memakai `secondaryContainer`
    // untuk indikator, dan `secondaryContainer` kita bernuansa oranye —
    // padahal oranye disediakan khusus untuk uang dan peringatan. Tanpa
    // baris ini, tab aktif tampil oranye dan hierarki warnanya rusak.
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: LestarTokens.forest,
      backgroundColor: LestarTokens.inkSoft,
    ),
    // Agent D: perkaya di sini. Jangan mengubah tiga hal di atas.
  );
}
