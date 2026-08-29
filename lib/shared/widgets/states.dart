import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Layar kosong yang menjelaskan dirinya. Dipakai di mana pun daftar bisa
/// kosong — radar tanpa listing, riwayat baru, pesanan nol.
///
/// **Tanda tangan dikunci.**
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 48,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: LestarType.judulKartu(color: cs.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: LestarType.isi(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Pita yang muncul saat koneksi hilang.
///
/// Ini bukan hiasan: di penutup demo WiFi memang dimatikan, dan pita ini yang
/// menjelaskan kenapa angka forecast berlabel "Perkiraan lokal".
///
/// **Tanda tangan dikunci.**
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.offline,
    this.message = 'Sedang offline — data terakhir yang tersimpan.',
  });

  final bool offline;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!offline) return const SizedBox.shrink();
    return Material(
      color: LestarTokens.orangeTint,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off,
                size: 16,
                color: LestarTokens.orangeText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: LestarType.label(color: LestarTokens.orangeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
