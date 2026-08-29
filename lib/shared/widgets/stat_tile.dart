import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Satu angka besar dengan labelnya. Dipakai dashboard merchant dan layar
/// pengepul.
///
/// **Tanda tangan dikunci.**
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.trailing,
    this.valueSize = 32,
  });

  final String label;

  /// Sudah diformat oleh pemanggil (`Fmt.rupiah`, `Fmt.kg`, dst.) — widget ini
  /// tidak menebak satuan.
  final String value;

  final String? unit;
  final IconData? icon;
  final Widget? trailing;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: cs.primary),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: LestarType.label(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: LestarType.display(
                        size: valueSize,
                        wght: 700,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit!,
                      style: LestarType.label(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
