import '../../core/constants.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// Tabel `waste_batches` — jalur B2B.
class WasteRepository {
  /// Radar pengepul. Realtime aktif di `waste_batches`.
  Stream<List<WasteBatch>> availableStream() => supabase
      .from('waste_batches')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(WasteBatch.fromJson)
                .where((w) => w.status == WasteStatus.available)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// RPC geo milik Agent A. Hanya batch `available`, terurut `jarak_km`.
  Future<List<NearbyWaste>> nearbyWaste({
    required double lat,
    required double lng,
    double radiusKm = LestarConstants.radiusPengepulKm,
  }) async {
    final rows =
        await supabase.rpc(
              'nearby_waste',
              params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm},
            )
            as List<dynamic>;
    return rows
        .map((e) => NearbyWaste.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Pengepul menekan JEMPUT.
  Future<WasteBatch> matchPartner(String batchId, String partnerId) async {
    final row = await supabase
        .from('waste_batches')
        .update({
          'matched_partner_id': partnerId,
          'status': WasteStatus.matched.wire,
        })
        .eq('id', batchId)
        .select()
        .single();
    return WasteBatch.fromJson(row);
  }

  /// `matched` → `picked_up` → `completed`.
  ///
  /// Pembatalan memakai `status = 'cancelled'` sambil **membiarkan**
  /// `matched_partner_id` tetap terisi. Mengosongkannya akan ditolak policy
  /// `WITH CHECK` di `waste_batches` — lihat `A-HANDOFF.md` §8.6.
  Future<WasteBatch> updateStatus(String batchId, WasteStatus status) async {
    final patch = <String, dynamic>{'status': status.wire};
    if (status == WasteStatus.completed) {
      patch['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    final row = await supabase
        .from('waste_batches')
        .update(patch)
        .eq('id', batchId)
        .select()
        .single();
    return WasteBatch.fromJson(row);
  }

  /// Batch yang dikirim satu merchant — dipakai layar ESG merchant.
  Stream<List<WasteBatch>> merchantWaste(String merchantId) => supabase
      .from('waste_batches')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(WasteBatch.fromJson)
                .where((w) => w.sourceMerchantId == merchantId)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// Batch yang sedang atau pernah dijemput satu pengepul.
  Stream<List<WasteBatch>> partnerWaste(String partnerId) => supabase
      .from('waste_batches')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(WasteBatch.fromJson)
                .where((w) => w.matchedPartnerId == partnerId)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Future<WasteBatch> createBatch(WasteBatch batch) async {
    final row = await supabase
        .from('waste_batches')
        .insert(batch.toJson())
        .select()
        .single();
    return WasteBatch.fromJson(row);
  }

  Future<WasteBatch?> getBatch(String id) async {
    final row = await supabase
        .from('waste_batches')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : WasteBatch.fromJson(row);
  }
}
