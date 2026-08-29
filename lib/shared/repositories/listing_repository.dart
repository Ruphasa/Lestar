import '../../core/constants.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// Tabel `listings` — jalur B2C.
class ListingRepository {
  /// Database menolak `status='live'` kalau `physical_validated` masih false
  /// atau `triage_score < 70`. Urutannya karena itu: simpan sebagai draft,
  /// lalu [validatePhysical] yang menaikkannya jadi live.
  Future<Listing> createListing(Listing listing) async {
    final row = await supabase
        .from('listings')
        .insert(listing.toJson())
        .select()
        .single();
    return Listing.fromJson(row);
  }

  /// Merchant menekan "Validasi Kondisi Fisik Aman". Ini gerbang yang
  /// ditegakkan database, bukan sekadar tombol di UI.
  Future<Listing> validatePhysical(String listingId) async {
    final row = await supabase
        .from('listings')
        .update({
          'physical_validated': true,
          'physical_validated_at': DateTime.now().toUtc().toIso8601String(),
          'status': ListingStatus.live.wire,
        })
        .eq('id', listingId)
        .select()
        .single();
    return Listing.fromJson(row);
  }

  /// Radar konsumen. Realtime aktif di `listings` (replica identity full).
  ///
  /// Filter diulang di sisi klien meski RLS sudah menyaring baris: RLS
  /// menentukan baris mana yang boleh dibaca, bukan baris mana yang menarik.
  /// Tanpa `.where` di bawah, setiap perubahan listing siapa pun akan
  /// memicu rebuild radar. `expires_at > now()` juga tidak bisa dititipkan ke
  /// server — nilainya bergerak, kueri stream tidak.
  Stream<List<Listing>> liveListingsStream() => supabase
      .from('listings')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows.map(Listing.fromJson).where((l) => l.tampilDiRadar).toList()
              ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)),
      );

  /// RPC geo milik Agent A. Sudah menyaring live + sisa stok + belum
  /// kedaluwarsa, dan mengembalikan hasil terurut `jarak_km` menaik.
  Future<List<NearbyListing>> nearbyListings({
    required double lat,
    required double lng,
    double radiusKm = LestarConstants.radiusKonsumenKm,
  }) async {
    final rows =
        await supabase.rpc(
              'nearby_listings',
              params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm},
            )
            as List<dynamic>;
    return rows
        .map((e) => NearbyListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inventaris satu merchant — semua status, termasuk draft dan cascaded.
  Stream<List<Listing>> merchantListings(String merchantId) => supabase
      .from('listings')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(Listing.fromJson)
                .where((l) => l.merchantId == merchantId)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Future<Listing?> getListing(String id) async {
    final row = await supabase
        .from('listings')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Listing.fromJson(row);
  }

  /// Dipakai layar merchant untuk melihat hasil kaskade tadi malam.
  Future<List<Listing>> merchantListingsSekali(String merchantId) async {
    final rows = await supabase
        .from('listings')
        .select()
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);
    return rows.map(Listing.fromJson).toList();
  }
}
