import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/role_switcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart';

/// Layar masuk. Milik Agent B — bukan wilayah D/E/F.
///
/// Sengaja sederhana: satu jalur masuk untuk tiga role, karena `profiles.role`
/// yang menentukan ke mana pengguna mendarat, bukan pilihan di layar ini.
/// Router yang mengarahkan setelah sesi terbentuk.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _memuat = false;
  bool _sandiTersembunyi = true;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_email.text.trim(), _sandi.text);
      // Tidak ada navigasi manual di sini: router memantau sesi dan
      // memindahkan sendiri ke beranda role yang benar.
    } catch (e) {
      if (mounted) setState(() => _galat = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LestarTokens.padLayar),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tekan lama logo di build demo untuk berganti akun.
                  const Center(child: RoleSwitcherLogo(size: 72)),
                  const SizedBox(height: 24),
                  Text(
                    'Lestar',
                    textAlign: TextAlign.center,
                    style: LestarType.judulLayar(color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Surplus hari ini, nilai besok.',
                    textAlign: TextAlign.center,
                    style: LestarType.isi(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sandi,
                    obscureText: _sandiTersembunyi,
                    onSubmitted: (_) => _masuk(),
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sandiTersembunyi
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _sandiTersembunyi = !_sandiTersembunyi,
                        ),
                      ),
                    ),
                  ),
                  if (_galat != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _galat!,
                      style: LestarType.label(color: LestarTokens.danger),
                    ),
                  ],
                  const SizedBox(height: 20),
                  BigButton(
                    label: 'Masuk',
                    loading: _memuat,
                    onPressed: _masuk,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
