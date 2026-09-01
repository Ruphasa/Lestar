import 'package:flutter/material.dart';

import '../../../../core/theme/dark_glass.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/merchant_inventory_controller.dart';

class FoodSafetyResultCard extends StatelessWidget {
  const FoodSafetyResultCard({
    super.key,
    required this.submission,
    required this.busy,
    required this.onValidate,
    required this.onRouteB2b,
  });

  final TriageSubmission submission;
  final bool busy;
  final VoidCallback onValidate;
  final VoidCallback onRouteB2b;

  @override
  Widget build(BuildContext context) {
    final b2c = submission.canPublishB2c;
    final accent = b2c ? LestarTokens.emerald : LestarTokens.orange;
    return DarkGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                b2c ? Icons.verified_user_outlined : Icons.recycling_outlined,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Skor Keamanan Pangan',
                  style: LestarType.judulKartu(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '${submission.triage.score} / 100',
              style: LestarType.display(size: 42, wght: 700, color: accent),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                b2c ? '● Jalur B2C' : '● Jalur B2B',
                style: LestarType.label(color: accent),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            submission.triage.reason,
            style: LestarType.isi(color: Colors.white.withValues(alpha: 0.68)),
          ),
          if (submission.triage.fromFallback) ...[
            const SizedBox(height: 10),
            Text(
              'Skor dihitung secara lokal karena layanan sedang tidak tersedia.',
              style: LestarType.caption(
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (b2c) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1),
              duration: MediaQuery.maybeOf(context)?.disableAnimations ?? false
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onValidate,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: LestarTokens.emeraldDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    'Validasi Kondisi Fisik Aman',
                    style: LestarType.display(size: 18, wght: 700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dengan menekan tombol ini, Anda menyatakan telah memeriksa '
              'aroma, tekstur, dan tampilan makanan secara langsung.',
              textAlign: TextAlign.center,
              style: LestarType.body(
                size: 12,
                color: Colors.white.withValues(alpha: 0.48),
                height: 1.45,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onRouteB2b,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: LestarTokens.orange,
                  foregroundColor: LestarTokens.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LestarTokens.ink,
                        ),
                      )
                    : const Icon(Icons.recycling),
                label: Text(
                  'Alihkan ke Jalur B2B',
                  style: LestarType.display(
                    size: 16,
                    wght: 700,
                    color: LestarTokens.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MerchantListingList extends StatelessWidget {
  const MerchantListingList({
    super.key,
    required this.listings,
    required this.waste,
  });

  final List<Listing> listings;
  final List<WasteBatch> waste;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const EmptyState(
        title: 'Belum ada listing',
        message: 'Tambahkan surplus pertama untuk memulai alur kaskade.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final cascadeByListing = <String, WasteBatch>{
      for (final batch in waste)
        if (batch.sourceListingId != null) batch.sourceListingId!: batch,
    };
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _ListingCard(
          key: ValueKey(listing.id),
          listing: listing,
          cascade: cascadeByListing[listing.id],
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({super.key, required this.listing, required this.cascade});

  final Listing listing;
  final WasteBatch? cascade;

  @override
  Widget build(BuildContext context) => DarkGlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListingImage(imageUrl: listing.imageUrl),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LestarType.display(
                            size: 16,
                            wght: 650,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: listing.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${Fmt.kategori(listing.category)} · '
                    '${listing.qtyRemaining}/${listing.qtyTotal} tersisa',
                    style: LestarType.body(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PriceText(
                    price: listing.price,
                    originalPrice: listing.originalPrice,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (cascade != null) ...[
          const SizedBox(height: 14),
          _CascadeTrail(listing: listing, batch: cascade!),
        ],
      ],
    ),
  );
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: DarkGlassTheme.narrative,
      alignment: Alignment.center,
      child: const Icon(
        Icons.bakery_dining_outlined,
        color: LestarTokens.emerald,
        size: 32,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 82,
        height: 82,
        child: imageUrl == null || imageUrl!.trim().isEmpty
            ? placeholder
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ListingStatus.live => ('LIVE', LestarTokens.emerald),
      ListingStatus.cascaded => ('KASKADE', LestarTokens.orange),
      ListingStatus.soldOut => ('HABIS', Colors.white54),
      ListingStatus.expired => ('LEWAT', LestarTokens.orange),
      ListingStatus.draft => ('DRAFT', Colors.white54),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: LestarType.body(size: 9, wght: 700, color: color),
      ),
    );
  }
}

class _CascadeTrail extends StatelessWidget {
  const _CascadeTrail({required this.listing, required this.batch});

  final Listing listing;
  final WasteBatch batch;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LestarTokens.orange.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 5,
          children: [
            Text(
              '${listing.name} ${listing.qtyRemaining} pcs',
              style: LestarType.body(size: 11, wght: 600, color: Colors.white),
            ),
            const Icon(Icons.arrow_forward, size: 13, color: Colors.white38),
            Text(
              'tidak terklaim ${Fmt.jam(batch.createdAt)}',
              style: LestarType.caption(color: Colors.white54),
            ),
            const Icon(Icons.arrow_forward, size: 13, color: Colors.white38),
            Text(
              batch.matchedPartnerId == null
                  ? 'dialihkan ke radar B2B'
                  : 'dialihkan ke mitra',
              style: LestarType.body(
                size: 11,
                wght: 600,
                color: LestarTokens.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
