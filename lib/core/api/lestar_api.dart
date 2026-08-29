import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/models/models.dart';
import '../constants.dart';
import '../fallback_engine.dart';
import 'api_models.dart';

/// Klien FastAPI milik Agent C.
///
/// **Tidak ada satu pun metode di kelas ini yang melempar exception.** Server
/// mati, timeout terlampaui, respons tidak valid, tidak ada koneksi — semua
/// jatuh ke [FallbackEngine] dan mengembalikan angka yang masuk akal. UI tidak
/// perlu `try/catch`, dan demo tidak berhenti karena Railway tidur.
///
/// Timeout: forecast 4 dtk · triage 4 dtk · pricing 3 dtk · esg 8 dtk.
class LestarApi {
  LestarApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? LestarConstants.apiBaseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;

  /// Basis URL kosong berarti Agent C belum menyerahkan alamatnya —
  /// langsung pakai fallback tanpa membuang waktu menunggu timeout.
  bool get tersedia => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    if (!tersedia) return null;
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // Disengaja: apa pun yang gagal, pemanggil dapat fallback.
      return null;
    }
  }

  // ── /forecast ──────────────────────────────────────────────────────────

  /// Buffer Intelligence. [history] terbaru dulu, 14 baris.
  Future<ForecastResult> forecast({
    required String merchantId,
    required List<SalesHistory> history,
    required DateTime targetDate,
    required int weatherCode,
    Map<String, dynamic>? merchantContext,
  }) async {
    final json = await _post('/forecast', {
      'merchant_id': merchantId,
      'history': [
        for (final h in history)
          {
            'date': dateKeWire(h.date),
            'portions_sold': h.portionsSold,
            'day_of_week': h.dayOfWeek,
            'is_holiday': h.isHoliday,
            'weather_code': h.weatherCode ?? 0,
            'surplus_kg': h.surplusKg,
          },
      ],
      'target_date': dateKeWire(targetDate),
      'weather_forecast': {'code': weatherCode},
      'merchant_context': ?merchantContext,
    }, LestarConstants.timeoutForecast);

    if (json == null) {
      return FallbackEngine.forecast(
        history: history,
        targetDate: targetDate,
        weatherCode: weatherCode,
      );
    }
    return ForecastResult.fromJson(json);
  }

  // ── /triage ────────────────────────────────────────────────────────────

  /// Skor keamanan pangan. Server boleh memperkaya `reason` lewat Gemini,
  /// tapi `score` dan `route` selalu hasil rumus yang sama dengan di sini —
  /// karena itu fallback-nya tidak mengubah keputusan, hanya kalimatnya.
  Future<TriageResult> triage({
    required String kategori,
    required double jamSejakMasak,
    required double ambientTemp,
  }) async {
    final json = await _post('/triage', {
      'category': kategori,
      'hours_since_cooked': jamSejakMasak,
      'ambient_temp': ambientTemp,
    }, LestarConstants.timeoutTriage);

    if (json == null) {
      return FallbackEngine.triage(
        kategori: kategori,
        jamSejakMasak: jamSejakMasak,
        ambientTemp: ambientTemp,
      );
    }
    return TriageResult.fromJson(json);
  }

  // ── /pricing ───────────────────────────────────────────────────────────

  Future<PricingResult> pricing({
    required double originalPrice,
    required double jamTersisa,
    required double jamTotal,
    required int qtyRemaining,
    required int qtyTotal,
  }) async {
    final json = await _post('/pricing', {
      'original_price': originalPrice,
      'hours_left': jamTersisa,
      'hours_total': jamTotal,
      'qty_remaining': qtyRemaining,
      'qty_total': qtyTotal,
    }, LestarConstants.timeoutPricing);

    if (json == null) {
      return FallbackEngine.pricing(
        originalPrice: originalPrice,
        jamTersisa: jamTersisa,
        jamTotal: jamTotal,
        qtyRemaining: qtyRemaining,
        qtyTotal: qtyTotal,
      );
    }
    return PricingResult.fromJson(json);
  }

  // ── /esg-narrative ─────────────────────────────────────────────────────

  /// Gemini menerima angka yang **sudah dihitung**, bukan data mentah.
  /// Kalau gagal, kalimat tetap keluar — hanya lebih datar.
  Future<String> esgNarrative({
    required Map<String, dynamic> agregat,
    Duration? timeout,
  }) async {
    final json = await _post(
      '/esg-narrative',
      agregat,
      timeout ?? LestarConstants.timeoutEsg,
    );
    final teks = json?['narrative'];
    if (teks is String && teks.trim().isNotEmpty) return teks;
    return narasiEsgLokal(agregat);
  }

  /// Template lokal untuk narasi ESG. Menyebut angka yang sama dengan yang
  /// akan dipakai Gemini, jadi laporan tetap benar meski kalimatnya kaku.
  static String narasiEsgLokal(Map<String, dynamic> a) {
    final kg = toDouble(a['total_weight_kg']).toStringAsFixed(1);
    final co2 = toDouble(a['total_co2_kg']).toStringAsFixed(1);
    final porsi = toInt(a['meals_rescued']);
    final rupiah = toDouble(a['total_revenue_recovered']).round();
    return 'Sepanjang periode ini, $kg kg surplus pangan tidak berakhir di '
        'TPA. Setara $co2 kg CO2eq yang tidak terlepas ke udara, $porsi porsi '
        'yang tetap dimakan orang, dan Rp $rupiah nilai yang kembali berputar.';
  }

  void dispose() => _client.close();
}
