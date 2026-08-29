import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lestar/core/api/lestar_api.dart';
import 'package:lestar/shared/models/models.dart';

import 'fallback_engine_test.dart' show historyDatar;

const _basis = 'http://api-uji.local';

void main() {
  test('server mati: triage jatuh ke fallback, tidak melempar', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient((_) async => throw const SocketException('mati')),
    );
    final r = await api.triage(
      kategori: 'roti',
      jamSejakMasak: 6,
      ambientTemp: 28,
    );
    expect(r.score, 85);
    expect(r.route, 'b2c');
    expect(r.fromFallback, true);
  });

  test('timeout terlampaui: forecast jatuh ke heuristik', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 6));
        return http.Response('{}', 200);
      }),
    );
    final f = await api.forecast(
      merchantId: 'm1',
      history: historyDatar(),
      targetDate: DateTime(2026, 8, 30),
      weatherCode: 0,
    );
    expect(f.source, ForecastSource.heuristic);
    expect(f.confidence, 0.45);
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('respons 500 juga jatuh ke fallback', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient((_) async => http.Response('boom', 500)),
    );
    final r = await api.pricing(
      originalPrice: 25000,
      jamTersisa: 0,
      jamTotal: 8,
      qtyRemaining: 10,
      qtyTotal: 10,
    );
    expect(r.harga, 7500);
    expect(r.fromFallback, true);
  });

  test('respons bukan JSON tidak membuat UI melihat exception', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient((_) async => http.Response('<html>502</html>', 200)),
    );
    final r = await api.triage(
      kategori: 'gorengan',
      jamSejakMasak: 4,
      ambientTemp: 28,
    );
    expect(r.score, 60);
    expect(r.fromFallback, true);
  });

  test('basis URL kosong: langsung fallback tanpa menunggu', () async {
    var dipanggil = false;
    final api = LestarApi(
      baseUrl: '',
      client: MockClient((_) async {
        dipanggil = true;
        return http.Response('{}', 200);
      }),
    );
    final r = await api.triage(
      kategori: 'kue',
      jamSejakMasak: 12,
      ambientTemp: 28,
    );
    expect(dipanggil, false);
    expect(r.score, 90);
    expect(api.tersedia, false);
  });

  test('server sehat: angka server dipakai apa adanya', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient(
        (req) async => http.Response(
          '{"score": 77, "route": "b2c", "reason": "dari server"}',
          200,
          headers: const {'content-type': 'application/json'},
        ),
      ),
    );
    final r = await api.triage(
      kategori: 'roti',
      jamSejakMasak: 6,
      ambientTemp: 28,
    );
    expect(r.score, 77);
    expect(r.reason, 'dari server');
    expect(r.fromFallback, false);
  });

  test('forecast server mempertahankan source yang dikirim server', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient(
        (_) async => http.Response(
          '{"demand_x": 55, "surplus_probability_y": 0.34,'
          '"surplus_volume_est_kg": 2.8, "recommended_production": 58,'
          '"confidence": 0.72, "narrative": "ok", "source": "lstm_gemini"}',
          200,
        ),
      ),
    );
    final f = await api.forecast(
      merchantId: 'm1',
      history: historyDatar(),
      targetDate: DateTime(2026, 8, 30),
      weatherCode: 0,
    );
    expect(f.source, ForecastSource.lstmGemini);
    expect(f.demandX, 55);
    expect(f.fromFallback, false);
  });

  test('esg-narrative gagal: kalimat lokal tetap menyebut angka', () async {
    final api = LestarApi(
      baseUrl: _basis,
      client: MockClient((_) async => http.Response('', 503)),
    );
    final teks = await api.esgNarrative(
      agregat: const {
        'total_weight_kg': 16.6,
        'total_co2_kg': 4.15,
        'meals_rescued': 24,
        'total_revenue_recovered': 480000,
      },
    );
    expect(teks, contains('16.6 kg'));
    expect(teks, contains('24 porsi'));
    expect(teks, isNotEmpty);
  });
}
