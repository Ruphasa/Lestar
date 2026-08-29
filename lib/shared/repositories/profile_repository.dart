import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// `profiles` + dua tabel turunannya.
///
/// Ketiganya berbagi satu id: `profiles.id` = `merchants.id` = `partners.id`
/// = `auth.uid()`. Tidak ada kolom `merchant_id` terpisah di `merchants`.
class ProfileRepository {
  /// `maybeSingle` supaya baris yang belum ada mengembalikan null, bukan
  /// melempar — profil merchant bisa saja belum diisi saat pertama masuk.
  Future<Profile?> getProfile(String id) async {
    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<Merchant?> getMerchant(String id) async {
    final row = await supabase
        .from('merchants')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Merchant.fromJson(row);
  }

  Future<Partner?> getPartner(String id) async {
    final row = await supabase
        .from('partners')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Partner.fromJson(row);
  }

  Future<Profile> updateProfile(String id, Map<String, dynamic> patch) async {
    final row = await supabase
        .from('profiles')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromJson(row);
  }

  Future<Merchant> updateMerchant(String id, Map<String, dynamic> patch) async {
    final row = await supabase
        .from('merchants')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Merchant.fromJson(row);
  }

  Future<Partner> updatePartner(String id, Map<String, dynamic> patch) async {
    final row = await supabase
        .from('partners')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Partner.fromJson(row);
  }
}
