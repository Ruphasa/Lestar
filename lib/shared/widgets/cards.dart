import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Tiga kartu, satu per tema. Tanda tangannya identik supaya layar bisa
/// menukar salah satu tanpa mengubah apa pun yang lain.
///
/// **Tanda tangan ini dikunci.** D/E/F boleh memperkaya isi `build`, tidak
/// boleh menambah, menghapus, atau mengubah tipe parameter.

/// Kartu terang berefek kaca — tema konsumen. Diisi Agent E.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = LestarTokens.radiusKartu,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.72),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu gelap berefek kaca — tema merchant. Diisi Agent D.
class DarkGlassCard extends StatelessWidget {
  const DarkGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = LestarTokens.radiusKartu,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: LestarTokens.inkSoft.withValues(alpha: 0.78),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu polos tanpa efek — tema pengepul. Diisi Agent F.
///
/// Sengaja tanpa blur: layar pengepul dipakai sambil berkendara dan sering
/// di bawah matahari; kontras tinggi menang atas dekorasi.
class PlainCard extends StatelessWidget {
  const PlainCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = LestarTokens.radiusKartu,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    return Material(
      color: cs.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
