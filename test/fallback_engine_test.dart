import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/fallback_engine.dart';
import 'package:lestar/shared/models/models.dart';

/// Sepuluh input uji untuk membuktikan versi Dart dan versi Python memberi
/// angka yang sama persis.
///
/// Angka harapan diturunkan tangan dari rumus di `docs/04-ai-pipeline.md` §4,
/// bukan dari keluaran salah satu implementasi — kalau diambil dari salah
/// satunya, pengujian ini hanya membuktikan kode cocok dengan dirinya sendiri.
///
/// `api/test_parity.py` milik Agent C harus memakai sepuluh baris yang sama.
const kasusTriage = <List<Object>>[
  // kategori, jam sejak masak, suhu, skor, rute
  ['roti', 6.0, 28.0, 85, 'b2c'], // 100 - 6/24*60 = 85
  ['gorengan', 3.0, 28.0, 70, 'b2c'], // 100 - 3/6*60 = 70, tepat di ambang
  ['gorengan', 4.0, 28.0, 60, 'b2b'], // 100 - 40 = 60
  ['nasi_lauk', 2.0, 28.0, 85, 'b2c'], // 100 - 2/8*60 = 85
  ['nasi_lauk', 2.0, 33.0, 70, 'b2c'], // 85 - 15 suhu = 70
  ['kue', 12.0, 28.0, 90, 'b2c'], // 100 - 12/72*60 = 90
  ['seafood', 1.0, 28.0, 65, 'b2b'], // 100 - 15 - 20 kategori = 65
  ['santan_susu', 1.0, 28.0, 68, 'b2b'], // 100 - 12 - 20 = 68
  ['minuman', 6.0, 31.0, 55, 'b2b'], // 100 - 30 - 15 suhu = 55
  ['lainnya', 1.0, 28.0, 93, 'b2c'], // shelf default 8 jam: 100 - 7.5 = 92.5
];

List<SalesHistory> historyDatar({int porsi = 70, double surplus = 2.0}) =>
    List.generate(
      14,
      (i) => SalesHistory(
        id: 'h$i',
        merchantId: 'm1',
        date: DateTime(2026, 8, 28).subtract(Duration(days: i)),
        portionsSold: porsi,
        revenue: porsi * 10000,
        dayOfWeek: 0,
        isHoliday: false,
        weatherCode: 0,
        surplusKg: surplus,
      ),
    );

void main() {
  group('triage', () {
    test('identik dengan rumus Python untuk 10 input uji', () {
      for (final k in kasusTriage) {
        final r = FallbackEngine.triage(
          kategori: k[0] as String,
          jamSejakMasak: k[1] as double,
          ambientTemp: k[2] as double,
        );
        final label = '${k[0]} · ${k[1]} jam · ${k[2]}°C';
        expect(r.score, k[3], reason: label);
        expect(r.route, k[4], reason: label);
      }
    });

    test('ambang b2c tepat di 70, bukan di atasnya', () {
      final r = FallbackEngine.triage(
        kategori: 'gorengan',
        jamSejakMasak: 3,
        ambientTemp: 28,
      );
      expect(r.score, 70);
      expect(r.route, 'b2c');
      expect(r.keB2c, true);
    });

    test('skor dijepit ke 0..100', () {
      final bawah = FallbackEngine.triage(
        kategori: 'seafood',
        jamSejakMasak: 48,
        ambientTemp: 40,
      );
      expect(bawah.score, 0);
      expect(bawah.route, 'b2b');

      final atas = FallbackEngine.triage(
        kategori: 'kue',
        jamSejakMasak: 0,
        ambientTemp: 25,
      );
      expect(atas.score, 100);
    });

    test('kategori asing memakai shelf life default, tidak crash', () {
      final r = FallbackEngine.triage(
        kategori: 'entah_apa',
        jamSejakMasak: 1,
        ambientTemp: 28,
      );
      expect(r.score, 93);
    });

    test('alasan menyebut angka yang dipakai', () {
      final r = FallbackEngine.triage(
        kategori: 'roti',
        jamSejakMasak: 6,
        ambientTemp: 28,
      );
      expect(r.reason, contains('6 jam'));
      expect(r.reason, contains('24 jam'));
      expect(r.fromFallback, true);
    });
  });

  group('pricing', () {
    test('dibatasi 70% dan dibulatkan ke Rp500', () {
      final r = FallbackEngine.pricing(
        originalPrice: 25000,
        jamTersisa: 0,
        jamTotal: 8,
        qtyRemaining: 10,
        qtyTotal: 10,
      );
      // 0.30 + 0.35*1 + 0.15*1 = 0.80 -> dijepit 0.70
      expect(r.diskon, 0.70);
      expect(r.harga, 7500);
      expect(r.harga % 500, 0);
      expect(r.diskonPersen, 70);
    });

    test('awal masa jual memakai diskon dasar', () {
      final r = FallbackEngine.pricing(
        originalPrice: 20000,
        jamTersisa: 8,
        jamTotal: 8,
        qtyRemaining: 0,
        qtyTotal: 10,
      );
      expect(r.diskon, closeTo(0.30, 1e-9));
      expect(r.harga, 14000);
    });

    test('separuh waktu dan separuh stok', () {
      final r = FallbackEngine.pricing(
        originalPrice: 30000,
        jamTersisa: 4,
        jamTotal: 8,
        qtyRemaining: 5,
        qtyTotal: 10,
      );
      // 0.30 + 0.35*0.5 + 0.15*0.5 = 0.55
      expect(r.diskon, closeTo(0.55, 1e-9));
      // 30000 * 0.45 = 13500, sudah kelipatan 500
      expect(r.harga, 13500);
    });

    test('harga selalu kelipatan Rp500 untuk angka ganjil', () {
      final r = FallbackEngine.pricing(
        originalPrice: 17300,
        jamTersisa: 3,
        jamTotal: 7,
        qtyRemaining: 3,
        qtyTotal: 8,
      );
      expect(r.harga % 500, 0);
    });
  });

  group('forecast', () {
    test('jujur soal sumber dan tingkat keyakinan', () {
      final f = FallbackEngine.forecast(
        history: historyDatar(),
        targetDate: DateTime(2026, 8, 30), // Minggu
        weatherCode: 0,
      );
      expect(f.source, ForecastSource.heuristic);
      expect(f.fromFallback, true);
      expect(f.confidence, 0.45);
      expect(f.narrative, contains('Perkiraan lokal'));
    });

    test('memakai pengali hari yang benar', () {
      // 2026-08-30 hari Minggu -> pengali 1.15; rata-rata 7 hari = 70
      final f = FallbackEngine.forecast(
        history: historyDatar(),
        targetDate: DateTime(2026, 8, 30),
        weatherCode: 0,
      );
      expect(f.demandX, (70 * 1.15).round()); // 81
    });

    test('hujan menurunkan permintaan 12 persen', () {
      // 2026-08-29 hari Sabtu -> pengali 1.35; rata-rata 7 hari = 70.
      // Pembulatan terjadi sekali di akhir, jadi acuannya rumus mentah:
      // cerah 70*1.35 = 94.5 -> 95 · hujan 94.5*0.88 = 83.16 -> 83.
      final cerah = FallbackEngine.forecast(
        history: historyDatar(),
        targetDate: DateTime(2026, 8, 29),
        weatherCode: 0,
      );
      final hujan = FallbackEngine.forecast(
        history: historyDatar(),
        targetDate: DateTime(2026, 8, 29),
        weatherCode: 65,
      );
      expect(cerah.demandX, 95);
      expect(hujan.demandX, 83);
      expect(hujan.demandX, (70 * 1.35 * 0.88).round());
    });

    test('rekomendasi produksi tidak pernah di bawah permintaan', () {
      final f = FallbackEngine.forecast(
        history: historyDatar(),
        targetDate: DateTime(2026, 9, 1),
        weatherCode: 0,
      );
      expect(f.recommendedProduction, greaterThanOrEqualTo(f.demandX));
    });

    test('riwayat kosong tetap mengembalikan hasil, bukan exception', () {
      final f = FallbackEngine.forecast(
        history: const [],
        targetDate: DateTime(2026, 9, 1),
        weatherCode: 0,
      );
      expect(f.demandX, 0);
      expect(f.source, ForecastSource.heuristic);
    });
  });
}
