import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengubah exception jadi kalimat yang boleh dilihat pengguna.
///
/// Klien API tidak pernah melempar, jadi yang sampai ke sini praktis hanya
/// kegagalan Supabase: kredensial salah, RLS menolak, atau tidak ada koneksi.
String pesanError(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Email atau kata sandi salah.';
    if (m.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi.';
    }
    return 'Gagal masuk. ${e.message}';
  }

  if (e is PostgrestException) {
    // Gerbang validasi fisik dan ambang triage ditegakkan database lewat
    // constraint; pesannya sudah ditulis Agent A dalam Bahasa Indonesia.
    if (e.code == '42501' || e.message.contains('row-level security')) {
      return 'Tidak punya izin untuk tindakan ini.';
    }
    if (e.code == '23505') return 'Data ini sudah ada.';
    return e.message;
  }

  if (e is StorageException) return 'Gagal mengunggah berkas. ${e.message}';

  if (e is SocketException || e is TimeoutException) {
    return 'Tidak ada koneksi. Sebagian data mungkin belum diperbarui.';
  }

  if (e is StateError) return e.message;

  return 'Terjadi kesalahan yang tidak terduga.';
}

/// True kalau kegagalan ini disebabkan jaringan, bukan kesalahan pengguna.
/// Dipakai `OfflineBanner`.
bool masalahJaringan(Object e) =>
    e is SocketException ||
    e is TimeoutException ||
    (e is PostgrestException && e.code == null);
