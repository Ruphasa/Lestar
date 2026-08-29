import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/constants.dart';

void main() {
  test('konstanta bisnis cocok dengan versi SQL dan Python', () {
    expect(LestarConstants.faktorCo2PerKg, 0.25);
    expect(LestarConstants.greenFee, 1000);
    expect(LestarConstants.ambangTriageB2c, 70);
    expect(LestarConstants.diskonMaksimum, 0.70);
    expect(LestarConstants.diskonDasar, 0.30);
    expect(LestarConstants.qrMasaBerlakuJam, 2);
  });

  test('berat porsi identik dengan berat_porsi_kg() di SQL', () {
    expect(LestarConstants.beratPorsi('gorengan'), 0.15);
    expect(LestarConstants.beratPorsi('nasi_lauk'), 0.35);
    expect(LestarConstants.beratPorsi('roti'), 0.08);
    expect(LestarConstants.beratPorsi('kue'), 0.05);
    expect(LestarConstants.beratPorsi('minuman'), 0.30);
    expect(LestarConstants.beratPorsi('lainnya'), 0.20);
    // seafood dan santan_susu tidak punya berat porsi sendiri
    expect(LestarConstants.beratPorsi('seafood'), 0.20);
    expect(LestarConstants.beratPorsi('santan_susu'), 0.20);
    expect(LestarConstants.beratPorsi('entah_apa'), 0.20);
  });

  test('shelf life mencakup tujuh kategori', () {
    expect(LestarConstants.shelfLife('gorengan'), 6);
    expect(LestarConstants.shelfLife('nasi_lauk'), 8);
    expect(LestarConstants.shelfLife('roti'), 24);
    expect(LestarConstants.shelfLife('kue'), 72);
    expect(LestarConstants.shelfLife('seafood'), 4);
    expect(LestarConstants.shelfLife('santan_susu'), 5);
    expect(LestarConstants.shelfLife('minuman'), 12);
    expect(LestarConstants.shelfLife('lainnya'), 8);
  });

  test('kategori listing persis yang dikenali database', () {
    expect(LestarConstants.kategoriListing, [
      'gorengan',
      'nasi_lauk',
      'roti',
      'kue',
      'minuman',
      'lainnya',
    ]);
  });

  test('kunci yang dibundel bukan service role', () {
    expect(LestarConstants.supabaseAnonKey.startsWith('sb_publishable_'), true);
    expect(LestarConstants.supabaseAnonKey.contains('secret'), false);
  });
}
