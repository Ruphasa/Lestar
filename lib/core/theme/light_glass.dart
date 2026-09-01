import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tema konsumen — **kerangka**.
///
/// Agent E memiliki berkas ini dan mengisinya. Yang ada di sini hanya cukup
/// untuk membuat aplikasi berjalan dan warnanya benar: palet, tipografi, dan
/// bentuk dasar. Efek kaca, gradien, dan dekorasi lain adalah pekerjaan E.
///
/// Yang **tidak boleh diubah** E, karena dipakai widget bersama:
/// - `colorScheme.primary` tetap [LestarTokens.emeraldDeep]
/// - `colorScheme.secondary` tetap [LestarTokens.orange]
/// - keluarga font tetap PlusJakartaSans (display) dan Inter (body)
class LightGlassTheme {
  const LightGlassTheme._();

  static final ThemeData data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9FDFA),
    colorScheme: const ColorScheme.light(
      primary: LestarTokens.emeraldDeep,
      onPrimary: Colors.white,
      primaryContainer: LestarTokens.emeraldTint,
      onPrimaryContainer: LestarTokens.forest,
      secondary: LestarTokens.orange,
      // Isian oranye selalu memakai teks gelap, tidak pernah putih.
      onSecondary: LestarTokens.ink,
      secondaryContainer: LestarTokens.orangeTint,
      onSecondaryContainer: LestarTokens.orangeText,
      surface: Colors.white,
      onSurface: LestarTokens.ink,
      surfaceContainerHighest: LestarTokens.surfaceGrey,
      outline: LestarTokens.mutedSoft,
      error: LestarTokens.danger,
      onError: Colors.white,
    ),
    textTheme: LestarType.textTheme(LestarTokens.ink, LestarTokens.muted),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2FCF6).withValues(alpha: 0.92),
      prefixIconColor: LestarTokens.emeraldDeep,
      hintStyle: LestarType.isi(color: LestarTokens.mutedSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: LestarTokens.emeraldDeep,
          width: 1.4,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: LestarTokens.forest,
      titleTextStyle: LestarType.judulKartu(color: LestarTokens.forest),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: LestarTokens.orange,
        foregroundColor: LestarTokens.ink,
        disabledBackgroundColor: LestarTokens.surfaceGrey,
        disabledForegroundColor: LestarTokens.muted,
        minimumSize: const Size(48, 52),
        textStyle: LestarType.display(size: 15, wght: 700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    // Indikator nav dipaksa hijau. Material 3 memakai `secondaryContainer`
    // untuk indikator, dan `secondaryContainer` kita bernuansa oranye —
    // padahal oranye disediakan khusus untuk uang dan peringatan. Tanpa
    // baris ini, tab aktif tampil oranye dan hierarki warnanya rusak.
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: LestarTokens.emeraldTint,
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => LestarType.label(
          color: states.contains(WidgetState.selected)
              ? LestarTokens.forest
              : LestarTokens.muted,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LestarTokens.emeraldDeep,
    ),
  );
}
