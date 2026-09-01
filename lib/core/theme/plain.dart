import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tema pengepul — **kerangka**.
///
/// Agent F memiliki berkas ini dan mengisinya. Tema ini sengaja paling polos:
/// layar pengepul dipakai sambil berkendara, jadi yang menang adalah angka
/// besar dan tombol besar, bukan dekorasi.
///
/// Yang **tidak boleh diubah** F, karena dipakai widget bersama:
/// - `colorScheme.primary` tetap [LestarTokens.emeraldDeep]
/// - `colorScheme.secondary` tetap [LestarTokens.orange]
/// - keluarga font tetap PlusJakartaSans (display) dan Inter (body)
class PlainTheme {
  const PlainTheme._();

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
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: LestarTokens.ink, width: 2),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: LestarTokens.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: LestarType.display(
        size: 24,
        wght: 700,
        color: LestarTokens.ink,
      ),
    ),
    dividerTheme: const DividerThemeData(color: LestarTokens.ink, thickness: 2),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LestarTokens.emeraldDeep,
    ),
    // Indikator nav dipaksa hijau. Material 3 memakai `secondaryContainer`
    // untuk indikator, dan `secondaryContainer` kita bernuansa oranye —
    // padahal oranye disediakan khusus untuk uang dan peringatan. Tanpa
    // baris ini, tab aktif tampil oranye dan hierarki warnanya rusak.
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: LestarTokens.emeraldTint,
      backgroundColor: Colors.white,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        LestarType.body(size: 12, wght: 700, color: LestarTokens.ink),
      ),
    ),
  );
}
