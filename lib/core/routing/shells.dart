import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../demo/role_switcher.dart';
import '../theme/tokens.dart';
import 'routes.dart';

/// Tiga shell pengganti `main_layout.dart` Ecobite yang dibuang.
///
/// Masing-masing membungkus `StatefulShellRoute.indexedStack`, jadi setiap tab
/// menyimpan riwayat navigasinya sendiri — kembali dari detail listing tidak
/// melempar konsumen keluar dari tab Radar.
///
/// Logo di app bar adalah [RoleSwitcherLogo]: di build demo, tekan-lama
/// membuka pintasan ganti role.

void _keCabang(StatefulNavigationShell shell, int i) => shell.goBranch(
  i,
  // Menekan tab yang sedang aktif memulangkan ke akar cabang itu.
  initialLocation: i == shell.currentIndex,
);

// ── Merchant ─────────────────────────────────────────────────────────────

class MerchantShell extends StatelessWidget {
  const MerchantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          RoleSwitcherLogo(size: 28),
          SizedBox(width: 10),
          Text('Lestar'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Scan QR',
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => context.push(Routes.merchantScan),
        ),
      ],
    ),
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (i) => _keCabang(navigationShell, i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventaris',
        ),
        NavigationDestination(
          icon: Icon(Icons.eco_outlined),
          selectedIcon: Icon(Icons.eco),
          label: 'ESG',
        ),
      ],
    ),
  );
}

// ── Konsumen ─────────────────────────────────────────────────────────────

/// Empat tab plus FAB QR di tengah.
///
/// FAB bukan cabang shell: QR aktif adalah layar penuh yang dibuka di atas
/// shell, bukan tab kelima yang menyimpan riwayat.
class ConsumerShell extends StatelessWidget {
  const ConsumerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: [navigationShell, const DemoCornerTap()]),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push(Routes.qr),
      backgroundColor: LestarTokens.emeraldDeep,
      foregroundColor: Colors.white,
      tooltip: 'QR aktif milikku',
      child: const Icon(Icons.qr_code_2),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (i) => _keCabang(navigationShell, i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.radar_outlined),
          selectedIcon: Icon(Icons.radar),
          label: 'Radar',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_fire_department_outlined),
          selectedIcon: Icon(Icons.local_fire_department),
          label: 'Feed',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  );
}

// ── Pengepul ─────────────────────────────────────────────────────────────

/// Tiga tab, label huruf besar, tanpa app bar.
///
/// Aturan Agent F: satu layar satu aksi, target sentuh besar, tanpa hiasan.
/// Shell ini sengaja tidak punya app bar supaya angka raksasa dapat ruang
/// paling atas.
class PartnerShell extends StatelessWidget {
  const PartnerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(children: [navigationShell, const DemoCornerTap()]),
    ),
    bottomNavigationBar: NavigationBar(
      height: 72,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (i) => _keCabang(navigationShell, i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined, size: 28), label: 'BERANDA'),
        NavigationDestination(icon: Icon(Icons.history, size: 28), label: 'RIWAYAT'),
        NavigationDestination(icon: Icon(Icons.card_membership, size: 28), label: 'LANGGANAN'),
      ],
    ),
  );
}
