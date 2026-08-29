import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

/// Token bersama tiga tema.
///
/// Sumber warna adalah `assets/logo.png` (forest + oranye) ditambah anggota
/// keluarga hijau yang lebih terang dari palet Tailwind v4, supaya setiap
/// nilai punya rujukan yang bisa diverifikasi.
///
/// **`#12C56A` tidak ada di sini dan tidak boleh dipakai** — itu nilai tebakan
/// dari draf lama.
///
/// Sumber: `docs/03-design-system.md` §3.
class LestarTokens {
  const LestarTokens._();

  // ── Hijau: sistem, keberlanjutan, kepercayaan ──────────────────────────
  /// Logo. Teks pekat dan permukaan brand. Kontras 8,1:1 di atas putih (AAA).
  static const forest = Color(0xFF265938);

  /// emerald-600. Tombol aksi. Putih di atasnya 3,65:1 — hanya untuk teks
  /// besar (>= 18 sp bold).
  static const emeraldDeep = Color(0xFF009966);

  /// emerald-500. Status aktif, ikon, badge AI.
  /// **Tidak pernah** dipakai sebagai latar teks — putih di atasnya 2,5:1.
  static const emerald = Color(0xFF00BC7D);

  /// Latar chip hijau.
  static const emeraldTint = Color(0xFFECFAEF);

  // ── Oranye: selera, urgensi, uang ──────────────────────────────────────
  /// Logo. Pill diskon, CTA beli, hitung mundur.
  /// Isian oranye selalu memakai teks [ink], tidak pernah putih (7,2:1 AAA).
  static const orange = Color(0xFFF38222);

  /// Teks oranye di atas latar terang. 4,6:1 (AA).
  static const orangeText = Color(0xFFC2540E);

  /// Latar chip oranye.
  static const orangeTint = Color(0xFFFFF1E4);

  // ── Netral (Tailwind v4) ───────────────────────────────────────────────
  /// neutral-950. Teks isi. 19,0:1 di atas putih (AAA).
  static const ink = Color(0xFF0A0A0A);

  /// neutral-900.
  static const inkSoft = Color(0xFF171717);

  /// neutral-500.
  static const muted = Color(0xFF737373);

  /// neutral-400.
  static const mutedSoft = Color(0xFFA1A1A1);

  /// neutral-100.
  static const surfaceGrey = Color(0xFFF5F5F5);

  static const danger = Color(0xFFE5484D);

  // ── Jarak dan radius yang dipakai bersama ──────────────────────────────
  static const radiusKartu = 20.0;
  static const radiusChip = 999.0;
  static const padLayar = 20.0;
}

/// Tipografi Lestar.
///
/// Kedua font adalah **variable font**: satu berkas melayani semua bobot, dan
/// bobot diatur lewat `fontVariations`, **bukan** `fontWeight`. Memakai
/// `fontWeight` pada berkas variable akan tampak benar di beberapa mesin dan
/// salah di mesin lain — pakai [display] dan [body] saja.
///
/// Paket `google_fonts` sengaja tidak dipakai: paket itu mengambil font lewat
/// jaringan, dan saat WiFi dimatikan di penutup demo teks akan jatuh ke
/// fallback sistem.
class LestarType {
  const LestarType._();

  static const keluargaDisplay = 'PlusJakartaSans';
  static const keluargaBody = 'Inter';

  /// Judul, angka besar, tombol, label huruf besar.
  static TextStyle display({
    required double size,
    double wght = 700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: keluargaDisplay,
    fontVariations: [FontVariation('wght', wght)],
    fontSize: size,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Teks isi, deskripsi, label kecil, input, navigasi.
  static TextStyle body({
    double size = 15,
    double wght = 400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: keluargaBody,
    fontVariations: [FontVariation('wght', wght)],
    fontSize: size,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // ── Skala dari 03-design-system.md §4 ──────────────────────────────────
  /// 90 / 800 — angka raksasa layar pengepul.
  static TextStyle angkaRaksasa({Color? color}) =>
      display(size: 90, wght: 800, color: color, height: 1);

  /// 44 / 700 — judul layar pengepul.
  static TextStyle judulPengepul({Color? color}) =>
      display(size: 44, wght: 700, color: color);

  /// 48 / 700 — angka besar dashboard merchant.
  static TextStyle angkaBesar({Color? color}) =>
      display(size: 48, wght: 700, color: color, height: 1.1);

  /// 32 / 700 — judul layar.
  static TextStyle judulLayar({Color? color}) =>
      display(size: 32, wght: 700, color: color);

  /// 20 / 600 — judul kartu.
  static TextStyle judulKartu({Color? color}) =>
      display(size: 20, wght: 600, color: color);

  /// 15 / 400 — body.
  static TextStyle isi({Color? color}) => body(size: 15, color: color);

  /// 13 / 500 — label.
  static TextStyle label({Color? color}) =>
      body(size: 13, wght: 500, color: color);

  /// 11 / 400 — caption.
  static TextStyle caption({Color? color}) => body(size: 11, color: color);

  /// `TextTheme` dasar yang dipakai ketiga tema. D/E/F boleh menimpanya
  /// lewat `copyWith`, tapi keluarga font dan mekanisme `fontVariations`
  /// harus tetap.
  static TextTheme textTheme(Color warnaUtama, Color warnaRedup) => TextTheme(
    displayLarge: display(size: 90, wght: 800, color: warnaUtama, height: 1),
    displayMedium: display(size: 48, wght: 700, color: warnaUtama),
    displaySmall: display(size: 44, wght: 700, color: warnaUtama),
    headlineLarge: display(size: 32, wght: 700, color: warnaUtama),
    headlineMedium: display(size: 24, wght: 700, color: warnaUtama),
    titleLarge: display(size: 20, wght: 600, color: warnaUtama),
    titleMedium: display(size: 17, wght: 600, color: warnaUtama),
    labelLarge: display(size: 15, wght: 600, color: warnaUtama),
    bodyLarge: body(size: 16, color: warnaUtama),
    bodyMedium: body(size: 15, color: warnaUtama),
    bodySmall: body(size: 13, color: warnaRedup),
    labelMedium: body(size: 13, wght: 500, color: warnaRedup),
    labelSmall: body(size: 11, color: warnaRedup),
  );
}
