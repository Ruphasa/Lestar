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
    scaffoldBackgroundColor: Colors.white,
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
    // Indikator nav dipaksa hijau. Material 3 memakai `secondaryContainer`
    // untuk indikator, dan `secondaryContainer` kita bernuansa oranye —
    // padahal oranye disediakan khusus untuk uang dan peringatan. Tanpa
    // baris ini, tab aktif tampil oranye dan hierarki warnanya rusak.
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: LestarTokens.emeraldTint,
      backgroundColor: Colors.white,
    ),
    // Agent E: perkaya di sini (efek kaca, blur, gradien, appBarTheme,
    // navigationBarTheme). Jangan mengubah tiga hal di atas.
  );
}
