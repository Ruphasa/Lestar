import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum BigButtonTone { primary, danger, neutral }

/// Tombol aksi utama. Tinggi 56, teks 18 bold — ukuran yang lolos kontras
/// putih di atas `emeraldDeep` (3,65:1 hanya berlaku untuk teks besar).
///
/// **Tanda tangan dikunci.** D/E/F menyesuaikan gaya lewat `Theme`, bukan
/// dengan menambah parameter di sini.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
    this.tone = BigButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Saat true, tombol menampilkan indikator dan menolak tekanan — pemanggil
  /// tidak perlu ikut menonaktifkan `onPressed`.
  final bool loading;

  final bool expanded;
  final IconData? icon;
  final BigButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color latar, Color teks) = switch (tone) {
      BigButtonTone.primary => (cs.primary, cs.onPrimary),
      BigButtonTone.danger => (LestarTokens.danger, Colors.white),
      BigButtonTone.neutral => (
        cs.surfaceContainerHighest,
        cs.onSurface,
      ),
    };

    final tombol = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: latar,
        foregroundColor: teks,
        disabledBackgroundColor: latar.withValues(alpha: 0.5),
        disabledForegroundColor: teks.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: LestarType.display(size: 18, wght: 700),
      ),
      child: loading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: teks),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    style: LestarType.display(size: 18, wght: 700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    return expanded ? SizedBox(width: double.infinity, child: tombol) : tombol;
  }
}
