import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class ConsumerBackdrop extends StatelessWidget {
  const ConsumerBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFECFAEF), Color(0xFFF9FDFA)],
      ),
    ),
    child: SafeArea(child: child),
  );
}

class ConsumerFoodImage extends StatelessWidget {
  const ConsumerFoodImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String category;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return _FoodPlaceholder(category: category);
    return Image.network(
      url,
      fit: fit,
      cacheWidth: 720,
      errorBuilder: (context, error, stackTrace) =>
          _FoodPlaceholder(category: category),
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('food-placeholder'),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF1E4), Color(0xFFECFAEF)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bakery_dining_outlined,
            color: LestarTokens.forest,
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            Fmt.kategori(category),
            style: LestarType.caption(color: LestarTokens.forest),
          ),
        ],
      ),
    ),
  );
}

class ConsumerDiscountMarker extends StatelessWidget {
  const ConsumerDiscountMarker({super.key, required this.listing});

  final NearbyListing listing;

  @override
  Widget build(BuildContext context) {
    final normalized = listing.discountPercent.clamp(0.0, .7) / .7;
    final shadow = 8 + normalized * 10;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LestarTokens.orange,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: LestarTokens.orange.withValues(alpha: .28),
            blurRadius: shadow,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 + normalized * 5,
          vertical: 4 + normalized * 2,
        ),
        child: Text(
          Fmt.diskon(listing.discountPercent),
          style: LestarType.display(
            size: 11 + normalized * 3,
            wght: 800,
            color: LestarTokens.ink,
          ),
        ),
      ),
    );
  }
}

class AiDiscountBadge extends StatelessWidget {
  const AiDiscountBadge({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: LestarTokens.emeraldTint,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: LestarTokens.emerald),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 12,
            color: LestarTokens.emeraldDeep,
          ),
          const SizedBox(width: 4),
          Text(
            'AI ${Fmt.diskon(percent)}',
            style: LestarType.label(color: LestarTokens.forest),
          ),
        ],
      ),
    ),
  );
}

class ConsumerDealCard extends StatelessWidget {
  const ConsumerDealCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.compact = false,
  });

  final NearbyListing listing;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: EdgeInsets.zero,
    child: compact
        ? _CompactDeal(listing: listing)
        : _WideDeal(listing: listing),
  );
}

class _WideDeal extends StatelessWidget {
  const _WideDeal({required this.listing});

  final NearbyListing listing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 154,
    child: Row(
      children: [
        SizedBox(
          width: 116,
          height: double.infinity,
          child: ConsumerFoodImage(
            imageUrl: listing.imageUrl,
            category: listing.category,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LestarType.display(
                    size: 17,
                    wght: 600,
                    color: LestarTokens.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.storeName} · ${Fmt.jarak(listing.jarakKm)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LestarType.label(color: LestarTokens.muted),
                ),
                const Spacer(),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      Fmt.rupiah(listing.price),
                      style: LestarType.display(
                        size: 18,
                        wght: 750,
                        color: LestarTokens.orangeText,
                      ),
                    ),
                    Text(
                      Fmt.rupiah(listing.originalPrice),
                      style: LestarType.caption(
                        color: LestarTokens.muted,
                      ).copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CountdownChip(expiresAt: listing.expiresAt, compact: true),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompactDeal extends StatelessWidget {
  const _CompactDeal({required this.listing});

  final NearbyListing listing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: 1.35,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ConsumerFoodImage(
              imageUrl: listing.imageUrl,
              category: listing.category,
            ),
            Positioned(
              left: 8,
              top: 8,
              child: AiDiscountBadge(percent: listing.discountPercent),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LestarType.display(
                size: 14,
                wght: 650,
                color: LestarTokens.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              listing.storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LestarType.caption(color: LestarTokens.muted),
            ),
            const SizedBox(height: 8),
            Text(
              Fmt.rupiah(listing.price),
              style: LestarType.display(
                size: 16,
                wght: 750,
                color: LestarTokens.orangeText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class ConsumerListingEntrance extends StatelessWidget {
  const ConsumerListingEntrance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: child,
      ),
    ),
  );
}

class ConsumerErrorState extends StatelessWidget {
  const ConsumerErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'Radar belum bisa dimuat',
    message:
        message ??
        'Periksa koneksi lalu coba lagi. Daftar akan tetap bisa disegarkan.',
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Coba lagi'),
    ),
  );
}
