import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../../shared/repositories/repositories.dart';
import '../constants.dart';
import '../theme/tokens.dart';
import '../utils/error_handler.dart';
import 'demo_accounts.dart';

export 'demo_accounts.dart';

/// Logo app bar. Di build `--dart-define=DEMO=true`, tekan-lama membuka
/// pintasan ganti role.
///
/// Di build biasa ini hanya logo — tidak ada gestur tersembunyi yang bisa
/// ditemukan pengguna sungguhan, dan `LestarConstants.demoMode` adalah
/// konstanta kompilasi, jadi jalur di bawah ini hilang saat tree-shaking.
class RoleSwitcherLogo extends ConsumerWidget {
  const RoleSwitcherLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = Image.asset(
      'assets/logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
    );

    if (!LestarConstants.demoMode) return logo;

    return GestureDetector(
      onLongPress: () => showRoleSwitcher(context, ref),
      child: logo,
    );
  }
}

/// Bottom sheet berisi tiga akun demo. Pilih satu → keluar dan masuk lagi
/// diam-diam → router memindahkan sendiri ke shell yang sesuai.
///
/// Target: di bawah 3 detik dari tekan-lama sampai shell baru tampil.
Future<void> showRoleSwitcher(BuildContext context, WidgetRef ref) async {
  if (!LestarConstants.demoMode) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.switch_account, size: 18),
                const SizedBox(width: 8),
                Text('Ganti akun demo', style: LestarType.judulKartu()),
              ],
            ),
          ),
          for (final akun in demoAccounts)
            ListTile(
              leading: Icon(_ikon(akun), color: LestarTokens.emeraldDeep),
              title: Text(akun.label, style: LestarType.isi()),
              subtitle: Text(akun.keterangan, style: LestarType.caption()),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await gantiKeAkun(context, ref, akun);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

IconData _ikon(DemoAccount a) => switch (a.role) {
  UserRole.merchant => Icons.storefront,
  UserRole.consumer => Icons.person,
  UserRole.partner => Icons.local_shipping,
};

/// Keluar lalu masuk sebagai [akun]. Tidak ada navigasi manual: `redirect`
/// di router memindahkan sendiri begitu profil baru terbaca.
Future<void> gantiKeAkun(
  BuildContext context,
  WidgetRef ref,
  DemoAccount akun,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final auth = ref.read(authRepositoryProvider);
  try {
    await auth.signOut();
    await auth.signIn(akun.email, akun.password);
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(pesanError(e))));
  }
}
