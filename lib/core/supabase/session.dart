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
  if (uidSekarang == null) return null;
  return ref.watch(authRepositoryProvider).currentProfile();
});

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
