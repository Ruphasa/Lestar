import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/models.dart';
import '../../shared/repositories/providers.dart';
import 'supabase_client.dart';

/// Peristiwa masuk / keluar / token disegarkan.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => supabase.auth.onAuthStateChange,
);

/// Profil pengguna yang sedang masuk, atau null kalau tamu.
///
/// Router memakai ini untuk memilih shell, dan `MaterialApp` memakainya untuk
/// memilih tema. Selama masih `loading`, router menahan diri — kalau tidak,
/// pengguna yang sudah masuk akan sempat terlempar ke `/login`.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  // Menyalakan ulang setiap kali sesi berubah, termasuk saat pintasan demo
  // berganti akun.
  final _ = ref.watch(authStateProvider);

  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    return await ref.watch(authRepositoryProvider).currentProfile();
  } catch (_) {
    // Offline dengan sesi yang masih sah. Membaca `profiles` butuh jaringan,
    // tapi role sudah ada di dalam JWT — trigger `on_auth_user_created`
    // menyalinnya ke `raw_user_meta_data` saat registrasi.
    //
    // Tanpa jalur ini, mematikan WiFi melempar pengguna yang sudah masuk
    // kembali ke layar login. Di penutup demo, WiFi memang dimatikan.
    return _profilDariToken(user);
  }
});

/// Profil seadanya dari metadata JWT. Cukup untuk memilih shell dan tema;
/// angka seperti `ecoPoints` tidak ada di token dan sengaja nol — layar yang
/// menampilkannya sudah punya jalur kosongnya sendiri.
Profile _profilDariToken(User user) {
  final meta = user.userMetadata ?? const {};
  return Profile(
    id: user.id,
    name: (meta['name'] ?? '').toString(),
    email: user.email ?? '',
    phone: meta['phone']?.toString(),
    role: UserRole.parse(meta['role']),
    ecoPoints: 0,
    avatarUrl: meta['avatar_url']?.toString(),
    createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
  );
}

/// Role yang sedang berlaku, atau null kalau belum diketahui.
final currentRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(currentProfileProvider).value?.role,
);

/// Data merchant milik pengguna yang sedang masuk. Null untuk role lain.
final currentMerchantProvider = FutureProvider<Merchant?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.role != UserRole.merchant) return null;
  return ref.watch(profileRepositoryProvider).getMerchant(profile.id);
});

/// Data pengepul milik pengguna yang sedang masuk. Null untuk role lain.
final currentPartnerProvider = FutureProvider<Partner?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.role != UserRole.partner) return null;
  return ref.watch(profileRepositoryProvider).getPartner(profile.id);
});
