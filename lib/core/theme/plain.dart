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
    scaffoldBackgroundColor: LestarTokens.surfaceGrey,
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
        borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
      ),
    ),
    // Agent F: perkaya di sini. Jangan mengubah tiga hal di atas.
  );
}
