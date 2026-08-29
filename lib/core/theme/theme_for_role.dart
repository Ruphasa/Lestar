import 'package:flutter/material.dart';

import '../../shared/models/models.dart';
import 'dark_glass.dart';
import 'light_glass.dart';
import 'plain.dart';

export 'dark_glass.dart';
export 'light_glass.dart';
export 'plain.dart';
export 'tokens.dart';

/// Satu-satunya tempat role dipetakan ke tema.
///
/// Tamu (belum masuk) memakai tema konsumen — layar login dan onboarding
/// milik jalur konsumen.
ThemeData themeForRole(UserRole? role) => switch (role) {
  UserRole.merchant => DarkGlassTheme.data,
  UserRole.partner => PlainTheme.data,
  UserRole.consumer || null => LightGlassTheme.data,
};
