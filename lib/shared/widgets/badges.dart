import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';

/// Menampilkan asal angka forecast — termasuk saat sistem jatuh ke heuristik.
///
/// Aturan proyek: `forecasts.source` selalu jujur. Badge ini adalah wajah
/// aturan itu; jangan menyembunyikan varian `heuristic` demi tampilan.
///
/// **Tanda tangan dikunci.**
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source, this.compact = false});

  final ForecastSource source;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final (
      String teks,
      IconData ikon,
      Color latar,
      Color warnaTeks,
    ) = switch (source) {
      ForecastSource.lstmGemini => (
        gelap ? 'AI · LSTM + Gemini' : 'Prediksi AI',
        Icons.auto_awesome,
        gelap ? const Color(0xFF113525) : LestarTokens.emeraldTint,
        gelap ? LestarTokens.emerald : LestarTokens.forest,
      ),
      ForecastSource.lstmOnly => (
        gelap ? 'AI · LSTM' : 'Model tanpa narasi',
        Icons.insights,
        gelap ? Colors.white.withValues(alpha: 0.05) : LestarTokens.emeraldTint,
        gelap ? LestarTokens.emeraldDeep : LestarTokens.forest,
      ),
      ForecastSource.heuristic => (
        gelap ? 'Mode offline · heuristik' : 'Perkiraan lokal',
        Icons.offline_bolt_outlined,
        gelap ? Colors.white.withValues(alpha: 0.05) : LestarTokens.surfaceGrey,
        gelap ? Colors.white.withValues(alpha: 0.55) : LestarTokens.muted,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(LestarTokens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: compact ? 12 : 14, color: warnaTeks),
          const SizedBox(width: 5),
          Text(teks, style: LestarType.label(color: warnaTeks)),
        ],
      ),
    );
  }
}

/// Pill diskon. Isian oranye dengan teks `ink` — 7,2:1 (AAA).
/// Jangan menukar teksnya jadi putih; kombinasi itu gagal kontras.
///
/// **Tanda tangan dikunci.**
class DiscountPill extends StatelessWidget {
  const DiscountPill({super.key, required this.percent, this.compact = false});

  /// Rasio 0..1, bukan persen. `0.52` menghasilkan `-52%`.
  final double percent;

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 10,
      vertical: compact ? 3 : 5,
    ),
    decoration: BoxDecoration(
      color: LestarTokens.orange,
      borderRadius: BorderRadius.circular(LestarTokens.radiusChip),
    ),
    child: Text(
      Fmt.diskon(percent),
      style: LestarType.display(
        size: compact ? 12 : 14,
        wght: 700,
        color: LestarTokens.ink,
      ),
    ),
  );
}

/// Harga jual, dengan harga asli dicoret kalau ada.
///
/// **Tanda tangan dikunci.**
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.originalPrice,
    this.size = 20,
  });

  final double price;
  final double? originalPrice;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tampilkanAsli = originalPrice != null && originalPrice! > price;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          Fmt.rupiah(price),
          style: LestarType.display(size: size, wght: 700, color: cs.onSurface),
        ),
        if (tampilkanAsli) ...[
          const SizedBox(width: 6),
          Text(
            Fmt.rupiah(originalPrice!),
            style: LestarType.body(
              size: size * 0.65,
              color: cs.onSurface.withValues(alpha: 0.5),
            ).copyWith(decoration: TextDecoration.lineThrough),
          ),
        ],
      ],
    );
  }
}

/// Hitung mundur sampai `expiresAt`. Memperbarui dirinya sendiri tiap menit;
/// di bawah satu jam, tiap detik.
///
/// **Tanda tangan dikunci.**
class CountdownChip extends StatefulWidget {
  const CountdownChip({
    super.key,
    required this.expiresAt,
    this.compact = false,
  });

  final DateTime expiresAt;
  final bool compact;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  late Duration _sisa;
  Stream<void>? _tick;

  @override
  void initState() {
    super.initState();
    _hitung();
    _tick = Stream<void>.periodic(const Duration(seconds: 1));
  }

  void _hitung() => _sisa = widget.expiresAt.difference(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _tick,
      builder: (context, _) {
        _hitung();
        final mendesak = _sisa.inMinutes < 60;
        final habis = _sisa.isNegative;

        final latar = habis
            ? LestarTokens.surfaceGrey
            : mendesak
            ? LestarTokens.orangeTint
            : LestarTokens.emeraldTint;
        final warnaTeks = habis
            ? LestarTokens.muted
            : mendesak
            ? LestarTokens.orangeText
            : LestarTokens.forest;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 10,
            vertical: widget.compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: latar,
            borderRadius: BorderRadius.circular(LestarTokens.radiusChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: widget.compact ? 12 : 14,
                color: warnaTeks,
              ),
              const SizedBox(width: 5),
              Text(
                Fmt.sisaWaktu(_sisa),
                style: LestarType.label(color: warnaTeks),
              ),
            ],
          ),
        );
      },
    );
  }
}
