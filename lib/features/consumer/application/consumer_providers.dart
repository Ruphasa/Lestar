import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../../../core/constants.dart';
import '../../../core/supabase/session.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

class ConsumerLocation {
  const ConsumerLocation({
    required this.lat,
    required this.lng,
    required this.label,
    this.isFallback = false,
  });

  final double lat;
  final double lng;
  final String label;
  final bool isFallback;

  static const malangFallback = ConsumerLocation(
    lat: -7.9826,
    lng: 112.6308,
    label: 'Pusat Malang · lokasi cadangan',
    isFallback: true,
  );
}

abstract interface class ConsumerLocationService {
  Future<ConsumerLocation> current();
}

class DeviceConsumerLocationService implements ConsumerLocationService {
  const DeviceConsumerLocationService();

  @override
  Future<ConsumerLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return ConsumerLocation.malangFallback;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return ConsumerLocation.malangFallback;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return ConsumerLocation(
        lat: position.latitude,
        lng: position.longitude,
        label: 'Lokasi saya',
      );
    } catch (_) {
      return ConsumerLocation.malangFallback;
    }
  }
}

final consumerLocationServiceProvider = Provider<ConsumerLocationService>(
  (ref) => const DeviceConsumerLocationService(),
);

class ConsumerValueNotifier<T> extends Notifier<T> {
  ConsumerValueNotifier(this.initialValue);

  final T initialValue;

  @override
  T build() => initialValue;

  void setValue(T value) => state = value;
}

final consumerSearchQueryProvider =
    NotifierProvider.autoDispose<ConsumerValueNotifier<String>, String>(
      () => ConsumerValueNotifier(''),
    );
final selectedConsumerListingIdProvider =
    NotifierProvider.autoDispose<ConsumerValueNotifier<String?>, String?>(
      () => ConsumerValueNotifier(null),
    );
final consumerSignOutBusyProvider =
    NotifierProvider.autoDispose<ConsumerValueNotifier<bool>, bool>(
      () => ConsumerValueNotifier(false),
    );

abstract interface class ConsumerScreenBrightness {
  Future<void> maximize();
  Future<void> restore();
}

class AndroidConsumerScreenBrightness implements ConsumerScreenBrightness {
  const AndroidConsumerScreenBrightness();

  static const _channel = MethodChannel('id.lestar/screen_brightness');

  @override
  Future<void> maximize() => _channel.invokeMethod<void>('set', {'value': 1.0});

  @override
  Future<void> restore() => _channel.invokeMethod<void>('reset');
}

final consumerScreenBrightnessProvider = Provider<ConsumerScreenBrightness>(
  (ref) => const AndroidConsumerScreenBrightness(),
);

class ConsumerRadarData {
  const ConsumerRadarData({required this.location, required this.listings});

  final ConsumerLocation location;
  final List<NearbyListing> listings;
}

/// RPC geo tetap menjadi sumber data kartu/pin. Stream realtime hanya menjadi
/// pemicu pemuatan ulang RPC, sehingga jarak dan data merchant tidak pernah
/// dihitung atau ditebak di klien.
final consumerRadarProvider = StreamProvider.autoDispose<ConsumerRadarData>((
  ref,
) async* {
  final location = await ref.watch(consumerLocationServiceProvider).current();
  final repository = ref.watch(listingRepositoryProvider);

  Future<ConsumerRadarData> load() async => ConsumerRadarData(
    location: location,
    listings: await repository.nearbyListings(
      lat: location.lat,
      lng: location.lng,
      radiusKm: LestarConstants.radiusKonsumenKm,
    ),
  );

  yield await load();
  await for (final _ in repository.liveListingsStream()) {
    yield await load();
  }
});

final consumerOrdersProvider = StreamProvider.autoDispose<List<Order>>((
  ref,
) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    yield const [];
    return;
  }
  yield* ref.watch(orderRepositoryProvider).consumerOrders(profile.id);
});

class ConsumerActiveQr {
  const ConsumerActiveQr({required this.order, required this.merchant});

  final Order order;
  final Merchant merchant;
}

final activeConsumerQrProvider = FutureProvider.autoDispose<ConsumerActiveQr?>((
  ref,
) async {
  final orders = await ref.watch(consumerOrdersProvider.future);
  Order? active;
  for (final order in orders) {
    if (order.qrValid) {
      active = order;
      break;
    }
  }
  if (active == null) return null;

  final orderRepository = ref.watch(orderRepositoryProvider);
  final items = active.items.isEmpty
      ? await orderRepository.itemsOf(active.id)
      : active.items;
  final merchant = await ref
      .watch(profileRepositoryProvider)
      .getMerchant(active.merchantId);
  if (merchant == null) return null;
  return ConsumerActiveQr(
    order: active.copyWith(items: items),
    merchant: merchant,
  );
});
