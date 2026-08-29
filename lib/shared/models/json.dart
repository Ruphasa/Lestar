/// Pembantu pembacaan JSON dari PostgREST.
///
/// Semua model memakai berkas ini supaya aturan konversi hidup di satu tempat:
/// `timestamptz` selalu jadi `DateTime` lokal, `date` tetap tanggal polos,
/// dan `numeric` bisa datang sebagai `num` maupun `String`.
library;

/// `timestamptz` wajib. Nilai hilang atau rusak jatuh ke `DateTime.now()`
/// supaya layar tetap tampil, bukan crash.
DateTime dtWajib(dynamic v) => dtOpsional(v) ?? DateTime.now();

/// `timestamptz` opsional. `.toLocal()` supaya jam yang tampil adalah jam
/// pengguna, bukan UTC.
DateTime? dtOpsional(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// Kolom `date` Postgres ('2026-08-29'). Tidak di-`toLocal()` — menggeser
/// tanggal polos ke zona waktu lokal bisa memundurkannya satu hari.
DateTime dateWajib(dynamic v) => dateOpsional(v) ?? DateTime.now();

DateTime? dateOpsional(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return DateTime(v.year, v.month, v.day);
  final t = DateTime.tryParse(v.toString());
  return t == null ? null : DateTime(t.year, t.month, t.day);
}

/// Format `date` untuk dikirim balik ke Postgres.
String dateKeWire(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// `numeric` PostgREST bisa datang sebagai num atau String.
double toDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? toDoubleOpsional(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? toIntOpsional(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String toStr(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

String? toStrOpsional(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

bool toBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v == 'true' || v == 't' || v == '1';
  if (v is num) return v != 0;
  return fallback;
}

/// Buang pasangan bernilai null sebelum dikirim ke PostgREST — kolom yang
/// tidak disebut akan memakai default database.
Map<String, dynamic> tanpaNull(Map<String, dynamic> m) =>
    Map.fromEntries(m.entries.where((e) => e.value != null));
