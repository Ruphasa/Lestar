import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class PartnerPrimaryButton extends StatelessWidget {
  const PartnerPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
    height: 140,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x42009966),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LestarTokens.emeraldDeep,
        foregroundColor: Colors.white,
        disabledBackgroundColor: LestarTokens.emeraldDeep,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 38,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 42),
                  const SizedBox(width: 18),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: LestarType.display(
                      size: 32,
                      wght: 800,
                      height: 1.15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

class PartnerOutlineButton extends StatelessWidget {
  const PartnerOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 72,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: LestarTokens.ink,
        side: const BorderSide(color: LestarTokens.ink, width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: LestarType.display(size: 20, wght: 700),
      ),
    ),
  );
}

class PartnerSectionCard extends StatelessWidget {
  const PartnerSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: LestarTokens.ink, width: 2),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PartnerScreenTitle extends StatelessWidget {
  const PartnerScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: LestarType.display(size: 30, wght: 800, color: LestarTokens.ink),
  );
}

class PartnerStatTile extends StatelessWidget {
  const PartnerStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueSize = 28,
  });

  final String label;
  final String value;
  final IconData icon;
  final double valueSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 34, color: LestarTokens.emeraldDeep),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: LestarType.body(
                size: 13,
                wght: 700,
                color: LestarTokens.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LestarType.display(
                size: valueSize,
                wght: 800,
                color: LestarTokens.ink,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
