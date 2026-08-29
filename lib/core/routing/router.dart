import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/consumer/presentation/feed_screen.dart';
import '../../features/consumer/presentation/orders_screen.dart';
import '../../features/consumer/presentation/profile_screen.dart';
import '../../features/consumer/presentation/qr_screen.dart';
import '../../features/consumer/presentation/radar_screen.dart';
import '../../features/merchant/presentation/merchant_esg_screen.dart';
import '../../features/merchant/presentation/merchant_home_screen.dart';
import '../../features/merchant/presentation/merchant_inventory_screen.dart';
import '../../features/merchant/presentation/merchant_scan_screen.dart';
import '../../features/partner/presentation/partner_home_screen.dart';
import '../../features/partner/presentation/partner_langganan_screen.dart';
import '../../features/partner/presentation/partner_riwayat_screen.dart';
import '../../shared/models/models.dart';
import '../supabase/session.dart';
import 'routes.dart';
import 'shells.dart';

/// Menyalakan ulang `redirect` setiap kali sesi atau profil berubah.
/// Pola ini diwarisi dari Ecobite; yang diganti hanya sumber datanya.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(currentProfileProvider, (_, _) => notifyListeners());
  }

  // ignore: unused_field
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: notifier,
    debugLogDiagnostics: false,

    /// AuthGate. Satu tempat, tiga keputusan:
    /// 1. selama profil belum terbaca, jangan pindah ke mana-mana;
    /// 2. tamu hanya boleh di `/login`;
    /// 3. yang sudah masuk tidak boleh masuk wilayah role lain.
    redirect: (context, state) {
      final profilAsync = ref.read(currentProfileProvider);

      // 1. Masih memuat. Memindahkan sekarang akan melempar pengguna yang
      //    sebenarnya sudah punya sesi ke layar login, lalu memantulkannya
      //    balik — kedipan yang tidak perlu.
      if (profilAsync.isLoading) return null;

      final profil = profilAsync.value;
      final diLogin = state.matchedLocation == Routes.login;

      // 2. Belum masuk.
      if (profil == null) return diLogin ? null : Routes.login;

      // 3. Sudah masuk tapi masih di layar login.
      final beranda = Routes.berandaUntuk(profil.role);
      if (diLogin) return beranda;

      // 4. Lintas-role. Wilayah tiap role dipisah supaya konsumen tidak
      //    pernah melihat panel merchant — RLS sudah menolak datanya, tapi
      //    layar kosong dengan judul yang salah tetap membingungkan.
      final pemilik = Routes.pemilikPath(state.matchedLocation);
      if (pemilik != null && pemilik != profil.role) return beranda;

      return null;
    },

    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Merchant ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MerchantShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.merchantHome,
                builder: (context, state) => const MerchantHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.merchantInventory,
                builder: (context, state) => const MerchantInventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.merchantEsg,
                builder: (context, state) => const MerchantEsgScreen(),
              ),
            ],
          ),
        ],
      ),

      // Pemindai berdiri sendiri di luar shell: butuh layar penuh.
      GoRoute(
        path: Routes.merchantScan,
        builder: (context, state) => const MerchantScanScreen(),
      ),

      // ── Konsumen ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ConsumerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.radar,
                builder: (context, state) => const RadarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: Routes.qr,
        builder: (context, state) => const QrScreen(),
      ),

      // ── Pengepul ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            PartnerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.partnerHome,
                builder: (context, state) => const PartnerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.partnerRiwayat,
                builder: (context, state) => const PartnerRiwayatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.partnerLangganan,
                builder: (context, state) => const PartnerLanggananScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});

/// Dipakai `MaterialApp` untuk memilih tema tanpa menunggu profil selesai
/// dimuat — tamu dan pemuatan awal memakai tema konsumen.
UserRole? roleAktif(WidgetRef ref) => ref.watch(currentRoleProvider);
