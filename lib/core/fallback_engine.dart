import 'dart:math' as math;

import '../shared/models/models.dart';
import 'api/api_models.dart';
import 'constants.dart';

/// Lapis 3 dari rantai fallback: heuristik yang hidup **di dalam APK**.
///
/// ```
/// Lapis 1  LSTM + Gemini 2.5 Flash     source = lstm_gemini
///            ↓ Gemini timeout / kuota habis / respons tidak valid
/// Lapis 2  LSTM saja + template        source = lstm_only
///            ↓ Railway mati / timeout / tidak ada koneksi
/// Lapis 3  di sini                     source = heuristic
/// ```
///
/// [triage] dan [pricing] adalah **duplikat sengaja** dari `api/triage.py` dan
/// `api/pricing.py`. Keduanya deterministik, jadi hasilnya harus sama persis.
/// Kalau salah satu diubah, yang lain wajib ikut diubah di commit yang sama.
/// Konstantanya hidup di [LestarConstants] dan `api/constants.py`.
///
/// Rumus lengkap: `docs/04-ai-pipeline.md` §4 dan §5.
class FallbackEngine {
  const FallbackEngine._();

  /// Pengali permintaan per hari. Indeks 0 = Senin, sesuai konvensi
  /// `sales_history.day_of_week` — bukan `DateTime.weekday` yang mulai dari 1.
  static const List<double> dowMultiplier = [
    0.85, // Senin
    0.95, // Selasa
    1.00, // Rabu
    1.05, // Kamis
    1.20, // Jumat
    1.35, // Sabtu
    1.15, // Minggu
  ];

  // ── Forecast ───────────────────────────────────────────────────────────

  /// Kasar, tapi masuk akal — dan tidak pernah gagal.
  ///
  /// [history] diurutkan terbaru dulu (`history.first` = hari kemarin), sama
  /// seperti yang dikembalikan `ForecastRepository.recentSalesHistory`.
  /// [weatherCode] memakai kode OpenWeatherMap: 60 ke atas berarti hujan.
  ///
  /// `confidence` sengaja rendah (0.45) supaya UI menampilkan tingkat
  /// keyakinan yang jujur, bukan angka yang menyamar sebagai hasil model.
  static ForecastResult forecast({
    required List<SalesHistory> history,
    required DateTime targetDate,
    required int weatherCode,
  }) {
    if (history.isEmpty) {
      return ForecastResult(
        demandX: 0,
        surplusProbabilityY: 0,
        surplusVolumeEstKg: null,
        recommendedProduction: 0,
        confidence: 0.45,
        narrative:
            'Belum ada riwayat penjualan yang cukup untuk membuat perkiraan. '
            'Angka akan muncul setelah beberapa hari penjualan tercatat.',
        source: ForecastSource.heuristic,
      );
    }

    final tujuh = history.take(7).toList();
    final avg7 =
        tujuh.fold<int>(0, (a, e) => a + e.portionsSold) / tujuh.length;

    final dow = dowMultiplier[targetDate.weekday - 1];
    final weather = weatherCode >= 60 ? 0.88 : 1.0;

    final demandX = avg7 * dow * weather;

    // Produksi kemarin diperkirakan dari porsi terjual + surplus yang tersisa,
    // dikonversi balik ke porsi lewat berat porsi rata-rata 0.2 kg.
    final terakhir = history.first;
    final lastProd = terakhir.portionsSold + terakhir.surplusKg / 0.2;
    final surplusY = lastProd <= 0
        ? 0.0
        : ((lastProd - demandX) / lastProd).clamp(0.0, 1.0);

    return ForecastResult(
      demandX: demandX.round(),
      surplusProbabilityY: surplusY,
      surplusVolumeEstKg: (demandX * surplusY * 0.2),
      recommendedProduction: rekomendasiProduksi(demandX, surplusY),
      confidence: 0.45,
      narrative: _narasiForecast(demandX, targetDate, weatherCode, surplusY),
      source: ForecastSource.heuristic,
    );
  }

  /// Inti Buffer Intelligence: semakin rendah probabilitas surplus, semakin
  /// besar buffer yang aman ditambahkan — merchant berani memproduksi lebih
  /// karena setiap surplus punya jalur keluar.
  ///
  /// `recommended_production = ceil(demand_x × (1 + 0.15 × (1 − y)))`
  static int rekomendasiProduksi(double demandX, double surplusY) =>
      (demandX * (1 + 0.15 * (1 - surplusY))).ceil();

  // ── Triage ─────────────────────────────────────────────────────────────

  /// Deterministik. Bukan LLM.
  ///
  /// ```
  /// score = 100
  /// score -= (jam_sejak_masak / SHELF_LIFE[kategori]) * 60
  /// if ambient_temp > 30: score -= 15
  /// if kategori in ('seafood', 'santan_susu'): score -= 20
  /// score = clamp(round(score), 0, 100)
  /// route = 'b2c' if score >= 70 else 'b2b'
  /// ```
  static TriageResult triage({
    required String kategori,
    required double jamSejakMasak,
    required double ambientTemp,
  }) {
    final shelf = LestarConstants.shelfLife(kategori);

    var score = 100.0;
    score -= (jamSejakMasak / shelf) * 60;
    if (ambientTemp > 30) score -= 15;
    if (kategori == 'seafood' || kategori == 'santan_susu') score -= 20;

    final skor = score.round().clamp(0, 100);

    return TriageResult(
      score: skor,
      route: skor >= LestarConstants.ambangTriageB2c ? 'b2c' : 'b2b',
      reason: _alasanTriage(kategori, jamSejakMasak, shelf, ambientTemp, skor),
      fromFallback: true,
    );
  }

  // ── Pricing ────────────────────────────────────────────────────────────

  /// Deterministik juga.
  ///
  /// ```
  /// rasio_waktu = 1 - (jam_tersisa / jam_total)
  /// rasio_stok  = qty_remaining / qty_total
  /// diskon = 0.30 + (0.35 * rasio_waktu) + (0.15 * rasio_stok)
  /// diskon = min(diskon, 0.70)
  /// harga  = round(original_price * (1 - diskon) / 500) * 500
  /// ```
  ///
  /// Batas 70% menepati janji "diskon 50–70%". Pembulatan ke Rp500 supaya
  /// harga terlihat wajar, bukan Rp 31.847.
  static PricingResult pricing({
    required double originalPrice,
    required double jamTersisa,
    required double jamTotal,
    required int qtyRemaining,
    required int qtyTotal,
  }) {
    final rasioWaktu = jamTotal <= 0 ? 1.0 : 1 - (jamTersisa / jamTotal);
    final rasioStok = qtyTotal <= 0 ? 0.0 : qtyRemaining / qtyTotal;

    var diskon =
        LestarConstants.diskonDasar + (0.35 * rasioWaktu) + (0.15 * rasioStok);
    diskon = math.min(diskon, LestarConstants.diskonMaksimum);

    final harga = (originalPrice * (1 - diskon) / 500).round() * 500;

    return PricingResult(
      diskon: diskon,
      harga: harga.toDouble(),
      fromFallback: true,
    );
  }

  // ── Narasi lokal ───────────────────────────────────────────────────────

  static const _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String _narasiForecast(
    double demandX,
    DateTime targetDate,
    int weatherCode,
    double surplusY,
  ) {
    final hari = _namaHari[targetDate.weekday - 1];
    final cuaca = weatherCode >= 60 ? 'hujan' : 'cerah';
    final porsi = demandX.round();
    final risiko = surplusY >= 0.3 ? 'cukup besar' : 'kecil';
    return 'Perkiraan lokal untuk $hari, cuaca $cuaca: permintaan sekitar '
        '$porsi porsi. Risiko surplus $risiko. Angka ini dihitung di dalam '
        'aplikasi tanpa model — pakai sebagai ancar-ancar, bukan patokan.';
  }

  static String _alasanTriage(
    String kategori,
    double jamSejakMasak,
    int shelf,
    double ambientTemp,
    int skor,
  ) {
    final jam = jamSejakMasak.round();
    final b = StringBuffer(
      'Dimasak $jam jam lalu, kategori $kategori tahan $shelf jam. ',
    );
    b.write(
      ambientTemp > 30
          ? 'Suhu ${ambientTemp.round()}°C di atas normal. '
          : 'Kondisi suhu normal. ',
    );
    if (kategori == 'seafood' || kategori == 'santan_susu') {
      b.write('Kategori ini cepat rusak, skor diturunkan. ');
    }
    b.write(
      skor >= LestarConstants.ambangTriageB2c
          ? 'Masih aman dijual ke konsumen.'
          : 'Sebaiknya dialihkan ke jalur B2B.',
    );
    return b.toString();
  }
}
