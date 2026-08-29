// Bukti bahwa `liveListingsStream()` benar-benar menerima event realtime
// saat baris baru masuk — bukan sekadar memuat sekali lalu diam.
//
//     flutter test tool/smoke_realtime.dart
//
// Skrip ini menulis satu listing uji ke project sungguhan lalu menghapusnya
// lagi di `tearDown`, apa pun hasilnya. Baris uji dibuat sebagai Verde Kitchen
// (`merchant@lestar.id`) yang memang sengaja tidak punya listing aktif, jadi
// data panggung merchant lain tidak tersentuh.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/constants.dart';
import 'package:lestar/core/supabase/supabase_client.dart';
import 'package:lestar/shared/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sandi = 'lestar2026';
const _merchant = 'merchant@lestar.id';

void main() {
  final auth = AuthRepository();
  final listings = ListingRepository();
  String? idUji;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    await Supabase.initialize(
      url: LestarConstants.supabaseUrl,
      publishableKey: LestarConstants.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoriStorage(),
      ),
    );
  });

  tearDownAll(() async {
    if (idUji != null) {
      await supabase.from('listings').delete().eq('id', idUji!);
      // ignore: avoid_print
      print('baris uji dihapus · $idUji');
    }
    await auth.signOut();
  });

  test('liveListingsStream menerima event saat baris baru masuk', () async {
    final profil = await auth.signIn(_merchant, _sandi);
    expect(profil, isNotNull);

    // Mulai mendengarkan lebih dulu, lalu tunggu snapshot pertama supaya
    // langganan realtime benar-benar sudah terpasang sebelum insert.
    final terlihat = <int>[];
    final sub = listings.liveListingsStream().listen(
      (rows) => terlihat.add(rows.length),
    );

    await Future<void>.delayed(const Duration(seconds: 3));
    final sebelum = terlihat.isEmpty ? 0 : terlihat.last;
    // ignore: avoid_print
    print('sebelum insert · $sebelum listing live');

    final sekarang = DateTime.now();
    final baris = await supabase
        .from('listings')
        .insert({
          'merchant_id': profil!.id,
          'name': 'UJI REALTIME — hapus kalau tertinggal',
          'category': 'roti',
          'qty_total': 1,
          'qty_remaining': 1,
          'original_price': 20000,
          'price': 8000,
          'cooked_at': sekarang
              .subtract(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'expires_at': sekarang
              .add(const Duration(hours: 6))
              .toUtc()
              .toIso8601String(),
          // Gerbang database: status 'live' ditolak tanpa dua kolom ini.
          'triage_score': 88,
          'physical_validated': true,
          'physical_validated_at': sekarang.toUtc().toIso8601String(),
          'status': 'live',
        })
        .select()
        .single();
    idUji = baris['id'] as String;
    // ignore: avoid_print
    print('baris uji dibuat · $idUji');

    // Tunggu event realtime, bukan polling: kalau bertambah lebih cepat,
    // loop keluar lebih cepat.
    final batas = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(batas) &&
        (terlihat.isEmpty || terlihat.last <= sebelum)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    // ignore: avoid_print
    print('sesudah insert · ${terlihat.last} listing live');
    // ignore: avoid_print
    print('urutan snapshot yang diterima · $terlihat');

    expect(
      terlihat.last,
      sebelum + 1,
      reason: 'stream tidak menerima event realtime untuk baris baru',
    );

    await sub.cancel();
  }, timeout: const Timeout(Duration(seconds: 60)));
}

class _MemoriStorage extends GotrueAsyncStorage {
  final _isi = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _isi[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _isi[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _isi.remove(key);
}
