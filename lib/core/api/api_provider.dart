import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lestar_api.dart';

/// Satu klien API untuk seluruh aplikasi. D/E/F memakai
/// `ref.watch(lestarApiProvider)`, tidak membuat instans sendiri, supaya
/// koneksi HTTP dipakai ulang.
final lestarApiProvider = Provider<LestarApi>((ref) {
  final api = LestarApi();
  ref.onDispose(api.dispose);
  return api;
});
