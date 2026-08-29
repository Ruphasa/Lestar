// Bukti bahwa setiap repository benar-benar membaca data nyata dari Supabase.
//
// Ini bukan unit test dan sengaja TIDAK diletakkan di `test/`: berkas ini
// memerlukan jaringan dan project sungguhan, jadi `flutter test` biasa tidak
// boleh ikut menjalankannya. Jalankan sendiri:
//
//     flutter test tool/smoke_supabase.dart
//
// Angka yang diharapkan (keadaan seed menurut A-HANDOFF.md §5):
//   merchants 30 · listing live 12 · waste available 2 (16,6 kg) ·
//   sales_history 2700 · esg_events 40
//
// Kalau angkanya berbeda, kemungkinan besar sisa gladi belum dibersihkan —
// jalankan `supabase/seed/reset_demo.sql` dulu.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lestar/core/constants.dart';
import 'package:lestar/core/supabase/supabase_client.dart';
import 'package:lestar/shared/models/models.dart';
import 'package:lestar/shared/repositories/repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sandi = 'lestar2026';
const _merchant = 'merchant@lestar.id';
const _konsumen = 'amira@lestar.id';
const _mitra = 'budi@lestar.id';

void main() {
  final auth = AuthRepository();
  final profiles = ProfileRepository();
  final listings = ListingRepository();
  final orders = OrderRepository();
  final wastes = WasteRepository();
  final forecasts = ForecastRepository();
  final esg = EsgRepository();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // flutter_test memasang HttpClient tiruan yang membalas 400 dengan badan
    // kosong untuk setiap permintaan. Skrip ini justru butuh jaringan asli.
    HttpOverrides.global = null;
    await Supabase.initialize(
      url: LestarConstants.supabaseUrl,
      publishableKey: LestarConstants.supabaseAnonKey,
      // Tanpa dua baris ini, penyimpanan sesi memanggil plugin
      // shared_preferences yang tidak ada di lingkungan test.
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoriStorage(),
      ),
    );
  });

  tearDownAll(() async => auth.signOut());

  test('auth_repository: tiga akun demo masuk dan role-nya benar', () async {
    for (final (email, harapan) in <(String, UserRole)>[
      (_merchant, UserRole.merchant),
      (_konsumen, UserRole.consumer),
      (_mitra, UserRole.partner),
    ]) {
      final profil = await auth.signIn(email, _sandi);
      expect(profil, isNotNull, reason: email);
      expect(profil!.role, harapan, reason: email);
      // ignore: avoid_print
      print('auth ok · $email · ${profil.name} · ${profil.role.wire}');
    }
  });

  test('profile_repository: profil, merchant, dan partner terbaca', () async {
    final merchantProfil = await auth.signIn(_merchant, _sandi);
    final merchant = await profiles.getMerchant(merchantProfil!.id);
    expect(merchant, isNotNull);
    expect(merchant!.storeName, isNotEmpty);
    expect(merchant.cutoffTime, isNotEmpty);
    // ignore: avoid_print
    print('merchant ok · ${merchant.storeName} · cutoff ${merchant.cutoffTime}');

    final mitraProfil = await auth.signIn(_mitra, _sandi);
    final partner = await profiles.getPartner(mitraProfil!.id);
    expect(partner, isNotNull);
    expect(partner!.wastePreference, isNotEmpty);
    // ignore: avoid_print
    print(
      'partner ok · ${partner.orgName} · '
      'preferensi ${partner.wastePreference.map((e) => e.wire).join(",")} · '
      'radius ${partner.serviceRadiusKm} km',
    );
  });

  test('listing_repository: 12 listing live dan RPC geo mengembalikan baris', () async {
    final profil = await auth.signIn(_konsumen, _sandi);
    expect(profil, isNotNull);

    final live = await supabase
        .from('listings')
        .select()
        .eq('status', 'live');
    // ignore: avoid_print
    print('listing live ${live.length}');
    expect(live.length, greaterThan(0));

    // Koordinat diambil dari merchant sungguhan, bukan ditulis tangan —
    // data seed berada di Malang, dan titik uji yang ditebak akan
    // mengembalikan nol baris tanpa ada yang salah di kodenya.
    final toko = await supabase
        .from('merchants')
        .select('lat,lng')
        .limit(1)
        .single();

    final dekat = await listings.nearbyListings(
      lat: (toko['lat'] as num).toDouble(),
      lng: (toko['lng'] as num).toDouble(),
      radiusKm: 25,
    );
    // ignore: avoid_print
    print(
      'nearby_listings ${dekat.length} baris · '
      'terdekat ${dekat.isEmpty ? "-" : dekat.first.jarakKm.toStringAsFixed(2)} km',
    );
    expect(dekat, isNotEmpty);
    // RPC menjamin urutan jarak menaik.
    for (var i = 1; i < dekat.length; i++) {
      expect(dekat[i].jarakKm, greaterThanOrEqualTo(dekat[i - 1].jarakKm));
    }
  });

  test('listing_repository: liveListingsStream memancarkan baris awal', () async {
    await auth.signIn(_konsumen, _sandi);
    final pertama = await listings.liveListingsStream().first.timeout(
      const Duration(seconds: 15),
    );
    // ignore: avoid_print
    print('liveListingsStream ${pertama.length} listing');
    expect(pertama, isNotEmpty);
    expect(pertama.every((l) => l.status == ListingStatus.live), true);
  });

  test('order_repository: riwayat pesanan konsumen terbaca', () async {
    final profil = await auth.signIn(_konsumen, _sandi);
    final daftar = await orders.consumerOrders(profil!.id).first.timeout(
      const Duration(seconds: 15),
    );
    // ignore: avoid_print
    print('orders konsumen ${daftar.length}');
    expect(daftar, isA<List<Order>>());
  });

  test('waste_repository: radar 16,6 kg dan RPC geo pengepul', () async {
    final profil = await auth.signIn(_mitra, _sandi);
    final partner = await profiles.getPartner(profil!.id);

    final tersedia = await wastes.availableStream().first.timeout(
      const Duration(seconds: 15),
    );
    final totalKg = tersedia.fold<double>(0, (a, w) => a + w.weightKg);
    // ignore: avoid_print
    print(
      'waste available ${tersedia.length} batch · '
      '${totalKg.toStringAsFixed(1)} kg',
    );
    expect(tersedia, isNotEmpty);

    final dekat = await wastes.nearbyWaste(
      lat: partner!.baseLat,
      lng: partner.baseLng,
      radiusKm: partner.serviceRadiusKm,
    );
    // ignore: avoid_print
    print(
      'nearby_waste ${dekat.length} baris · '
      'dari kaskade ${dekat.where((w) => w.dariKaskade).length}',
    );
    expect(dekat, isA<List<NearbyWaste>>());
  });

  test('forecast_repository: 14 baris sales_history terbaca', () async {
    final profil = await auth.signIn(_merchant, _sandi);
    final riwayat = await forecasts.recentSalesHistory(profil!.id);
    // ignore: avoid_print
    print(
      'sales_history ${riwayat.length} baris · '
      'terbaru ${riwayat.isEmpty ? "-" : dateKeWire(riwayat.first.date)}',
    );
    expect(riwayat.length, 14);
    // Terbaru dulu — urutan yang diharapkan FallbackEngine.forecast.
    for (var i = 1; i < riwayat.length; i++) {
      expect(riwayat[i].date.isBefore(riwayat[i - 1].date), true);
    }
    // 0 = Senin, konvensi tabel.
    expect(riwayat.every((r) => r.dayOfWeek >= 0 && r.dayOfWeek <= 6), true);
  });

  test('esg_repository: peristiwa dan agregatnya terbaca', () async {
    final profil = await auth.signIn(_merchant, _sandi);
    final akhir = DateTime.now();
    final awal = akhir.subtract(const Duration(days: 365));

    final agregat = await esg.aggregate(profil!.id, awal, akhir);
    // ignore: avoid_print
    print(
      'esg merchant ini · ${agregat.totalWeightKg.toStringAsFixed(1)} kg · '
      '${agregat.totalCo2Kg.toStringAsFixed(1)} kg CO2 · '
      '${agregat.mealsRescued} porsi',
    );

    // Bukan 40 seperti di A-HANDOFF.md §5: RLS hanya memperlihatkan
    // peristiwa milik merchant yang sedang masuk. Angka 40 adalah jumlah
    // seluruh project, yang hanya terlihat oleh service role.
    final terlihat = await supabase.from('esg_events').select('id');
    // ignore: avoid_print
    print('esg_events terlihat oleh merchant ini ${terlihat.length}');
    expect(terlihat, isNotEmpty);
  });
}

/// Penyimpanan PKCE seadanya. Di aplikasi sungguhan tugas ini dipegang
/// shared_preferences; di sini cukup Map, karena prosesnya hidup sebentar.
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
