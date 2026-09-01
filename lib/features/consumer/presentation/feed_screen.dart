import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_providers.dart';
import 'consumer_checkout_flow.dart';
import 'widgets/consumer_widgets.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(consumerRadarProvider);
    return ConsumerBackdrop(
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ConsumerErrorState(
          message: pesanError(error),
          onRetry: () => ref.invalidate(consumerRadarProvider),
        ),
        data: (radar) => _FeedGrid(
          listings: radar.listings,
          onRefresh: () async {
            ref.invalidate(consumerRadarProvider);
            await ref.read(consumerRadarProvider.future);
          },
          onOpen: (listing) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ListingDetailScreen(listing: listing),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedGrid extends StatelessWidget {
  const _FeedGrid({
    required this.listings,
    required this.onRefresh,
    required this.onOpen,
  });

  final List<NearbyListing> listings;
  final Future<void> Function() onRefresh;
  final ValueChanged<NearbyListing> onOpen;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flash Deal',
                  style: LestarType.judulLayar(color: LestarTokens.forest),
                ),
                const SizedBox(height: 6),
                Text(
                  'Makanan enak, harga turun, dampak naik.',
                  style: LestarType.isi(color: LestarTokens.muted),
                ),
              ],
            ),
          ),
        ),
        if (listings.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.local_fire_department_outlined,
              title: 'Belum ada deal aktif',
              message: 'Tarik layar untuk memeriksa lagi.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .62,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final listing = listings[index];
                return ConsumerListingEntrance(
                  key: ValueKey('feed-${listing.id}'),
                  child: ConsumerDealCard(
                    listing: listing,
                    compact: true,
                    onTap: () => onOpen(listing),
                  ),
                );
              }, childCount: listings.length),
            ),
          ),
      ],
    ),
  );
}
