import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'esg_repository.dart';
import 'forecast_repository.dart';
import 'listing_repository.dart';
import 'order_repository.dart';
import 'profile_repository.dart';
import 'waste_repository.dart';

/// Tujuh repository sebagai provider.
///
/// Semuanya tanpa keadaan internal — klien Supabase diambil dari singleton
/// `supabase`, jadi instans repository boleh dibuat ulang kapan saja tanpa
/// kehilangan sesi. D/E/F cukup `ref.watch(listingRepositoryProvider)`.

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(profileRepository: ref.watch(profileRepositoryProvider)),
);

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(),
);

final wasteRepositoryProvider = Provider<WasteRepository>(
  (ref) => WasteRepository(),
);

final forecastRepositoryProvider = Provider<ForecastRepository>(
  (ref) => ForecastRepository(),
);

final esgRepositoryProvider = Provider<EsgRepository>(
  (ref) => EsgRepository(),
);
