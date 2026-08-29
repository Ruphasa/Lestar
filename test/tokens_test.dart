import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/theme/theme_for_role.dart';
import 'package:lestar/shared/models/models.dart';

void main() {
  test('token warna persis dari 03-design-system §3', () {
    expect(LestarTokens.forest, const Color(0xFF265938));
    expect(LestarTokens.emeraldDeep, const Color(0xFF009966));
    expect(LestarTokens.emerald, const Color(0xFF00BC7D));
    expect(LestarTokens.emeraldTint, const Color(0xFFECFAEF));
    expect(LestarTokens.orange, const Color(0xFFF38222));
    expect(LestarTokens.orangeText, const Color(0xFFC2540E));
    expect(LestarTokens.orangeTint, const Color(0xFFFFF1E4));
    expect(LestarTokens.ink, const Color(0xFF0A0A0A));
    expect(LestarTokens.inkSoft, const Color(0xFF171717));
    expect(LestarTokens.muted, const Color(0xFF737373));
    expect(LestarTokens.mutedSoft, const Color(0xFFA1A1A1));
    expect(LestarTokens.surfaceGrey, const Color(0xFFF5F5F5));
    expect(LestarTokens.danger, const Color(0xFFE5484D));
  });

  test('nilai tebakan draf lama tidak ada di mana pun', () {
    const dilarang = Color(0xFF12C56A);
    final semua = [
      LestarTokens.forest,
      LestarTokens.emeraldDeep,
      LestarTokens.emerald,
      LestarTokens.emeraldTint,
      LestarTokens.orange,
      LestarTokens.orangeText,
      LestarTokens.orangeTint,
      LestarTokens.ink,
      LestarTokens.inkSoft,
      LestarTokens.muted,
      LestarTokens.mutedSoft,
      LestarTokens.surfaceGrey,
      LestarTokens.danger,
    ];
    expect(semua.contains(dilarang), false);
  });

  test('bobot font lewat fontVariations, bukan fontWeight', () {
    final s = LestarType.display(size: 90, wght: 800);
    expect(s.fontFamily, 'PlusJakartaSans');
    expect(s.fontVariations, [const FontVariation('wght', 800)]);
    expect(s.fontWeight, isNull);
    expect(s.fontSize, 90);

    final b = LestarType.body(size: 15);
    expect(b.fontFamily, 'Inter');
    expect(b.fontVariations, [const FontVariation('wght', 400)]);
    expect(b.fontWeight, isNull);
  });

  test('skala tipografi cocok dengan tabel design system', () {
    expect(LestarType.angkaRaksasa().fontSize, 90);
    expect(LestarType.angkaRaksasa().fontVariations!.first.value, 800);
    expect(LestarType.judulPengepul().fontSize, 44);
    expect(LestarType.angkaBesar().fontSize, 48);
    expect(LestarType.judulLayar().fontSize, 32);
    expect(LestarType.judulKartu().fontSize, 20);
    expect(LestarType.judulKartu().fontVariations!.first.value, 600);
    expect(LestarType.isi().fontSize, 15);
    expect(LestarType.label().fontSize, 13);
    expect(LestarType.caption().fontSize, 11);
  });

  test('tema dipilih dari role, tamu memakai tema konsumen', () {
    expect(themeForRole(UserRole.consumer), LightGlassTheme.data);
    expect(themeForRole(UserRole.merchant), DarkGlassTheme.data);
    expect(themeForRole(UserRole.partner), PlainTheme.data);
    expect(themeForRole(null), LightGlassTheme.data);
  });

  test('kontrak warna tema yang tidak boleh diubah D/E/F', () {
    expect(LightGlassTheme.data.colorScheme.primary, LestarTokens.emeraldDeep);
    expect(DarkGlassTheme.data.colorScheme.primary, LestarTokens.emerald);
    expect(PlainTheme.data.colorScheme.primary, LestarTokens.emeraldDeep);

    for (final t in [
      LightGlassTheme.data,
      DarkGlassTheme.data,
      PlainTheme.data,
    ]) {
      expect(t.colorScheme.secondary, LestarTokens.orange);
      // Isian oranye selalu teks gelap, tidak pernah putih.
      expect(t.colorScheme.onSecondary, LestarTokens.ink);
      expect(t.textTheme.titleLarge!.fontFamily, 'PlusJakartaSans');
      expect(t.textTheme.bodyMedium!.fontFamily, 'Inter');
    }
  });
}
