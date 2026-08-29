import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routing/router.dart';
import 'core/supabase/session.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/theme_for_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data locale untuk DateFormat('...', 'id_ID'). Tanpa ini, setiap
  // pemformatan tanggal melempar LocaleDataException saat runtime.
  await initializeDateFormatting('id_ID');

  await initSupabase();

  runApp(const ProviderScope(child: LestarApp()));
}

class LestarApp extends ConsumerWidget {
  const LestarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema mengikuti role: konsumen terang, merchant gelap, pengepul polos.
    // Selama profil belum terbaca, tema konsumen yang dipakai.
    final role = ref.watch(currentProfileProvider).value?.role;

    return MaterialApp.router(
      title: 'Lestar',
      theme: themeForRole(role),
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
