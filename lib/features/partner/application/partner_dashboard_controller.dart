import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

final partnerNearbyWasteProvider =
    StreamProvider.family<List<NearbyWaste>, Partner>((ref, partner) async* {
      final repository = ref.watch(wasteRepositoryProvider);

      Future<List<NearbyWaste>> load() async {
        final rows = await repository.nearbyWaste(
          lat: partner.baseLat,
          lng: partner.baseLng,
          radiusKm: partner.serviceRadiusKm,
        );
        final preferences = partner.wastePreference.toSet();
        return rows
            .where((row) => preferences.contains(row.wasteType))
            .toList(growable: false);
      }

      yield await load();
      await for (final _ in repository.availableStream()) {
        yield await load();
      }
    });

class PartnerHistoryItem {
  const PartnerHistoryItem({required this.batch, required this.storeName});

  final WasteBatch batch;
  final String storeName;
}

final partnerHistoryProvider =
    StreamProvider.family<List<PartnerHistoryItem>, String>((
      ref,
      partnerId,
    ) async* {
      final wasteRepository = ref.watch(wasteRepositoryProvider);
      final profileRepository = ref.watch(profileRepositoryProvider);

      await for (final batches in wasteRepository.partnerWaste(partnerId)) {
        final completed = batches
            .where((batch) => batch.status == WasteStatus.completed)
            .toList(growable: false);
        final items = await Future.wait(
          completed.map((batch) async {
            try {
              final merchant = await profileRepository.getMerchant(
                batch.sourceMerchantId,
              );
              return PartnerHistoryItem(
                batch: batch,
                storeName: merchant?.storeName ?? 'Titik penjemputan',
              );
            } catch (_) {
              return PartnerHistoryItem(
                batch: batch,
                storeName: 'Titik penjemputan',
              );
            }
          }),
        );
        yield items;
      }
    });
