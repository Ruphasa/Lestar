import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';

/// Dipanggil sekali dari `main()`, sebelum `runApp`.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: LestarConstants.supabaseUrl,
    publishableKey: LestarConstants.supabaseAnonKey,
  );
}

/// Klien tunggal. Repository memakai ini, bukan menyimpan instansnya sendiri,
/// supaya pergantian sesi (mis. pintasan demo) langsung terlihat di semuanya.
SupabaseClient get supabase => Supabase.instance.client;

/// `auth.uid()` yang sedang berlaku, atau null kalau belum masuk.
String? get uidSekarang => supabase.auth.currentUser?.id;
