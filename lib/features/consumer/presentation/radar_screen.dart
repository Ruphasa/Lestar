import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_providers.dart';
import 'consumer_checkout_flow.dart';
import 'widgets/consumer_widgets.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final radar = ref.watch(consumerRadarProvider);
    final query = ref.watch(consumerSearchQueryProvider).trim().toLowerCase();

    return ConsumerBackdrop(
      child: radar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ConsumerErrorState(
          message: pesanError(error),
          onRetry: () => ref.invalidate(consumerRadarProvider),
        ),
        data: (data) {
          final listings = query.isEmpty
              ? data.listings
              : data.listings
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(query) ||
                          item.storeName.toLowerCase().contains(query) ||
                          item.category.toLowerCase().contains(query),
                    )
                    .toList();
          return _RadarContent(
            name: profile?.name ?? 'Amira',
            data: data,
            listings: listings,
            onQueryChanged: (value) =>
                ref.read(consumerSearchQueryProvider.notifier).setValue(value),
            onRefresh: () async {
              ref.invalidate(consumerRadarProvider);
              await ref.read(consumerRadarProvider.future);
            },
            onOpen: (listing) => _openListing(context, listing),
          );
        },
      ),
    );
  }

  void _openListing(BuildContext context, NearbyListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListingDetailScreen(listing: listing),
      ),
    );
  }
}

class _RadarContent extends ConsumerWidget {
  const _RadarContent({
    required this.name,
    required this.data,
    required this.listings,
    required this.onQueryChanged,
    required this.onRefresh,
    required this.onOpen,
  });

  final String name;
  final ConsumerRadarData data;
  final List<NearbyListing> listings;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<NearbyListing> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedConsumerListingIdProvider);
    final selected =
        listings.where((item) => item.id == selectedId).firstOrNull ??
        listings.firstOrNull;
    final firstName = name.trim().split(RegExp(r'\s+')).firstOrNull ?? 'Amira';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $firstName',
                      style: LestarType.isi(color: LestarTokens.forest),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live Flash Radar',
                      style: LestarType.judulLayar(color: LestarTokens.forest),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _LocationChip(location: data.location),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari makanan terselamatkan...',
            ),
          ),
          const SizedBox(height: 20),
          if (listings.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyState(
                icon: Icons.radar_outlined,
                title: 'Belum ada flash deal di dekatmu',
                message: 'Tarik layar untuk memeriksa listing terbaru.',
              ),
            )
          else ...[
            _RadarMap(
              data: data,
              listings: listings,
              selected: selected!,
              onSelect: (listing) => ref
                  .read(selectedConsumerListingIdProvider.notifier)
                  .setValue(listing.id),
              onOpen: onOpen,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Flash deals · segera berakhir',
                    style: LestarType.display(
                      size: 18,
                      wght: 600,
                      color: LestarTokens.inkSoft,
                    ),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Lihat semua')),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .62,
              ),
              itemCount: listings.length > 4 ? 4 : listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ConsumerListingEntrance(
                  key: ValueKey('radar-deal-${listing.id}'),
                  child: ConsumerDealCard(
                    listing: listing,
                    compact: true,
                    onTap: () => onOpen(listing),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.location});

  final ConsumerLocation location;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: location.label,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            location.isFallback
                ? Icons.location_searching
                : Icons.location_on_outlined,
            size: 16,
            color: LestarTokens.emeraldDeep,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              location.isFallback ? 'Malang' : 'Di dekatmu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LestarType.label(color: LestarTokens.inkSoft),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RadarMap extends StatelessWidget {
  const _RadarMap({
    required this.data,
    required this.listings,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final ConsumerRadarData data;
  final List<NearbyListing> listings;
  final NearbyListing selected;
  final ValueChanged<NearbyListing> onSelect;
  final ValueChanged<NearbyListing> onOpen;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 390,
      child: Stack(
        children: [
          Positioned.fill(
            child: LestarMap(
              center: LatLng(data.location.lat, data.location.lng),
              zoom: 13.8,
              showUser: !data.location.isFallback,
              markers: [
                for (final listing in listings)
                  LestarMapMarker(
                    point: LatLng(listing.lat, listing.lng),
                    width: 78,
                    height: 52,
                    payload: listing,
                    child: ConsumerDiscountMarker(listing: listing),
                  ),
              ],
              onMarkerTap: (marker) {
                final listing = marker.payload;
                if (listing is NearbyListing) onSelect(listing);
              },
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: ConsumerListingEntrance(
              key: ValueKey('selected-${selected.id}'),
              child: ConsumerDealCard(
                listing: selected,
                onTap: () => onOpen(selected),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
