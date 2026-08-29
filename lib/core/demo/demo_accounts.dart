import '../../shared/models/models.dart';

/// Tiga akun panggung. Kata sandinya sama untuk seluruh 43 akun seed
/// (`A-HANDOFF.md` §4) — ini akun demo di project demo, bukan kredensial
/// produksi, dan sengaja tertulis supaya pintasan ganti role bisa jalan tanpa
/// mengetik apa pun di depan juri.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.label,
    required this.keterangan,
    required this.role,
  });

  final String email;
  final String label;
  final String keterangan;
  final UserRole role;

  String get password => kataSandiDemo;
}

const kataSandiDemo = 'lestar2026';

const demoAccounts = <DemoAccount>[
  DemoAccount(
    email: 'merchant@lestar.id',
    label: 'Verde Kitchen',
    keterangan: 'Merchant · panel gelap',
    role: UserRole.merchant,
  ),
  DemoAccount(
    email: 'amira@lestar.id',
    label: 'Amira Rahmadani',
    keterangan: 'Konsumen · 1.240 eco point',
    role: UserRole.consumer,
  ),
  DemoAccount(
    email: 'budi@lestar.id',
    label: 'Pak Budi',
    keterangan: 'Pengepul · maggot, 1,2 km dari Verde Kitchen',
    role: UserRole.partner,
  ),
];
