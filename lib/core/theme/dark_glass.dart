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

  static const background = Color(0xFF10140F);
  static const surfaceDeep = Color(0xFF0D120C);
  static const card = Color(0xFF151A13);
  static const cardAlt = Color(0xFF141912);
  static const tile = Color(0xFF1C201B);
  static const narrative = Color(0xFF11291B);
  static const badge = Color(0xFF113525);

  static final ThemeData data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: LestarTokens.emerald,
      onPrimary: LestarTokens.ink,
      primaryContainer: badge,
      onPrimaryContainer: Colors.white,
      secondary: LestarTokens.orange,
      onSecondary: LestarTokens.ink,
      secondaryContainer: LestarTokens.orangeText,
      onSecondaryContainer: Colors.white,
      surface: card,
      onSurface: Colors.white,
      surfaceContainerHighest: tile,
      outline: Color(0xFF343A32),
      error: LestarTokens.danger,
      onError: Colors.white,
    ),
    textTheme: LestarType.textTheme(Colors.white, LestarTokens.mutedSoft),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
      ),
    ),
    // Indikator nav dipaksa hijau. Material 3 memakai `secondaryContainer`
    // untuk indikator, dan `secondaryContainer` kita bernuansa oranye —
    // padahal oranye disediakan khusus untuk uang dan peringatan. Tanpa
    // baris ini, tab aktif tampil oranye dan hierarki warnanya rusak.
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: background,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: LestarType.display(
        size: 18,
        wght: 700,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: badge,
      backgroundColor: surfaceDeep,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => LestarType.body(
          size: 11,
          wght: states.contains(WidgetState.selected) ? 600 : 400,
          color: states.contains(WidgetState.selected)
              ? LestarTokens.emerald
              : Colors.white.withValues(alpha: 0.48),
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? LestarTokens.emerald
              : Colors.white.withValues(alpha: 0.48),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tile,
      labelStyle: LestarType.label(color: Colors.white.withValues(alpha: 0.62)),
      hintStyle: LestarType.body(color: Colors.white.withValues(alpha: 0.38)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LestarTokens.emerald),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tile,
      contentTextStyle: LestarType.isi(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
