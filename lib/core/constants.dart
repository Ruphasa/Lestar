/// Konstanta bersama Lestar.
///
/// Nilai di berkas ini muncul di tiga tempat: Dart (di sini), Python
/// (`api/constants.py`), dan SQL (`berat_porsi_kg()` + `faktor_co2_per_kg()`
/// di `supabase/migrations/0005_intelligence.sql`). **Ketiganya wajib sama.**
/// Kalau salah satu diubah, ubah dua lainnya di commit yang sama — kalau tidak,
/// laporan ESG dan berat kaskade akan berselisih tanpa ada yang menyadarinya
/// sampai demo.
///
/// Sumber angka: `docs/02-data-model.md` §10.
library;

class LestarConstants {
  const LestarConstants._();

  // ── Angka bisnis ───────────────────────────────────────────────────────
  /// kg CO2eq yang dihindari per kg surplus. SQL: `faktor_co2_per_kg()`.
  static const double faktorCo2PerKg = 0.25;

  /// Rupiah per transaksi B2C.
  static const int greenFee = 1000;

  /// Skor triage minimum agar sebuah listing boleh masuk jalur B2C.
  /// Ditegakkan juga di database (gerbang validasi fisik).
  static const int ambangTriageB2c = 70;

  static const double diskonMaksimum = 0.70;
  static const double diskonDasar = 0.30;

  /// Masa berlaku QR klaim, dalam jam.
  static const int qrMasaBerlakuJam = 2;

  // ── Tabel kategori ─────────────────────────────────────────────────────
  /// Umur simpan aman per kategori, dalam jam. Dipakai `FallbackEngine.triage`.
  ///
  /// `seafood` dan `santan_susu` hanya punya umur simpan; keduanya tidak punya
  /// berat porsi sendiri dan memakai berat `lainnya`.
  static const Map<String, int> shelfLifeJam = {
    'gorengan': 6,
    'nasi_lauk': 8,
    'roti': 24,
    'kue': 72,
    'seafood': 4,
    'santan_susu': 5,
    'minuman': 12,
  };

  /// Umur simpan untuk kategori yang tidak terdaftar.
  static const int shelfLifeDefaultJam = 8;

  /// Berat satu porsi per kategori, dalam kg. SQL: `berat_porsi_kg(text)`.
  static const Map<String, double> beratPorsiKg = {
    'gorengan': 0.15,
    'nasi_lauk': 0.35,
    'roti': 0.08,
    'kue': 0.05,
    'minuman': 0.30,
    'lainnya': 0.20,
  };

  /// Berat porsi untuk kategori yang tidak terdaftar — sama dengan `lainnya`.
  static const double beratPorsiDefaultKg = 0.20;

  /// Kategori yang dikenali sistem. Persis string ini, huruf kecil.
  static const List<String> kategoriListing = [
    'gorengan',
    'nasi_lauk',
    'roti',
    'kue',
    'minuman',
    'lainnya',
  ];

  /// Berat satu porsi kategori mana pun. Kategori asing jatuh ke 0.20 kg,
  /// sama seperti `berat_porsi_kg()` di SQL.
  static double beratPorsi(String kategori) =>
      beratPorsiKg[kategori] ?? beratPorsiDefaultKg;

  /// Umur simpan kategori mana pun, dalam jam.
  static int shelfLife(String kategori) =>
      shelfLifeJam[kategori] ?? shelfLifeDefaultJam;

  // ── Lingkungan ─────────────────────────────────────────────────────────
  /// Aman untuk publik: dilindungi RLS. Bisa ditimpa lewat
  /// `--dart-define=SUPABASE_URL=...`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vhauffhtjckzmqomcgrl.supabase.co',
  );

  /// Kunci publishable, bukan service role. Service role key tidak pernah
  /// masuk APK.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_DqmsbnmC7rUB8tUSmBAw3Q_CTi-rAue',
  );

  /// Basis URL FastAPI milik Agent C. Kosong berarti klien API langsung
  /// memakai `FallbackEngine` tanpa menunggu timeout.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Radius radar bawaan, kilometer.
  static const double radiusKonsumenKm = 5;
  static const double radiusPengepulKm = 10;

  /// Pintasan demo hanya hidup di build `--dart-define=DEMO=true`.
  static const bool demoMode = bool.fromEnvironment('DEMO');

  // ── Timeout klien API ──────────────────────────────────────────────────
  static const Duration timeoutForecast = Duration(seconds: 4);
  static const Duration timeoutTriage = Duration(seconds: 4);
  static const Duration timeoutPricing = Duration(seconds: 3);
  static const Duration timeoutEsg = Duration(seconds: 8);

  // ── Mutu model ────────────────────────────────────────────────────────
  /// Sumber: api/model/metrics.json → demand_akurasi (Agent C, 30 Agu 2026).
  /// Diukur pada split kronologis data sintetis Fase 1, bukan acak.
  /// Perbarui manual kalau model dilatih ulang.
  static const double modelAkurasi = 0.9227;
  static const String modelDasarUji = 'data sintetis';
}
