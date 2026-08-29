import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';
import 'profile_repository.dart';

/// Masuk, keluar, dan siapa yang sedang masuk.
///
/// Registrasi tidak ada di sini: baris `profiles` dibuat trigger
/// `on_auth_user_created` dari `raw_user_meta_data`, jadi pendaftaran cukup
/// `signUp` dengan metadata — dan untuk demo, 43 akun sudah disiapkan Agent A.
class AuthRepository {
  AuthRepository({ProfileRepository? profileRepository})
    : _profiles = profileRepository ?? ProfileRepository();

  final ProfileRepository _profiles;

  /// Mengembalikan profil lengkap (termasuk role) supaya router bisa langsung
  /// memilih shell. Melempar [AuthException] kalau kredensial salah — ini satu
  /// dari sedikit tempat yang memang boleh melempar, karena layar login perlu
  /// menampilkan pesannya.
  Future<Profile?> signIn(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final id = res.user?.id;
    if (id == null) return null;
    return _profiles.getProfile(id);
  }

  Future<void> signOut() => supabase.auth.signOut();

  /// Profil pengguna yang sedang masuk, atau null.
  Future<Profile?> currentProfile() async {
    final id = uidSekarang;
    if (id == null) return null;
    return _profiles.getProfile(id);
  }

  /// Berubah setiap kali sesi masuk, keluar, atau token disegarkan.
  Stream<AuthState> authStateStream() => supabase.auth.onAuthStateChange;

  Session? get session => supabase.auth.currentSession;
}
