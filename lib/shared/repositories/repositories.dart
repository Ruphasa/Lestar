/// Satu impor untuk seluruh repository Lestar.
///
/// ```dart
/// import 'package:lestar/shared/repositories/repositories.dart';
/// ```
///
/// Untuk memakainya lewat Riverpod, pakai provider di `providers.dart`
/// (ikut ter-export dari sini) alih-alih membuat instans sendiri.
library;

export 'auth_repository.dart';
export 'esg_repository.dart';
export 'forecast_repository.dart';
export 'listing_repository.dart';
export 'order_repository.dart';
export 'profile_repository.dart';
export 'providers.dart';
export 'waste_repository.dart';
