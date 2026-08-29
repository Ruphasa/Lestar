import '../../shared/models/models.dart';

/// Seluruh path rute Lestar di satu tempat.
///
/// D/E/F memakai konstanta ini, bukan string mentah — kalau path berubah,
/// yang berubah cuma berkas ini.
class Routes {
  const Routes._();

  // ── Auth ───────────────────────────────────────────────────────────────
  static const login = '/login';

  // ── Merchant (tema gelap) ──────────────────────────────────────────────
  static const merchantHome = '/merchant';
  static const merchantInventory = '/merchant/inventory';
  static const merchantEsg = '/merchant/esg';

  /// Di luar shell — pemindai membutuhkan layar penuh.
  static const merchantScan = '/merchant/scan';

  // ── Konsumen (tema terang) ─────────────────────────────────────────────
  static const radar = '/radar';
  static const feed = '/feed';
  static const orders = '/orders';
  static const profile = '/profile';

  /// FAB tengah: QR aktif milik konsumen. Di luar shell.
  static const qr = '/qr';

  // ── Pengepul (tema polos) ──────────────────────────────────────────────
  static const partnerHome = '/partner';
  static const partnerRiwayat = '/partner/riwayat';
  static const partnerLangganan = '/partner/langganan';

  /// Layar pertama setiap role setelah masuk.
  static String berandaUntuk(UserRole role) => switch (role) {
    UserRole.merchant => merchantHome,
    UserRole.consumer => radar,
    UserRole.partner => partnerHome,
  };

  /// Prefix yang hanya boleh diakses satu role. Dipakai penjaga lintas-role
  /// di `router.dart`.
  static UserRole? pemilikPath(String path) {
    if (path.startsWith('/merchant')) return UserRole.merchant;
    if (path.startsWith('/partner')) return UserRole.partner;
    if (path == radar ||
        path == feed ||
        path == orders ||
        path == profile ||
        path == qr) {
      return UserRole.consumer;
    }
    return null;
  }
}
