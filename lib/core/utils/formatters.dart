import 'package:intl/intl.dart';

/// Format tampilan yang dipakai bersama D/E/F.
///
/// Semuanya memakai locale `id_ID` supaya pemisah ribuan titik, bukan koma.
class Fmt {
  const Fmt._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _angka = NumberFormat.decimalPattern('id_ID');
  static final _tanggal = DateFormat('d MMM yyyy', 'id_ID');
  static final _tanggalPanjang = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _jam = DateFormat('HH:mm', 'id_ID');

  /// `Rp 12.000`. Tanpa desimal — rupiah tidak punya sen dalam praktik.
  static String rupiah(num v) => _rupiah.format(v);

  /// `1.240`
  static String angka(num v) => _angka.format(v);

  /// `-52%`
  static String diskon(double rasio) => '-${(rasio * 100).round()}%';

  /// `9,2 kg` — satu desimal, koma sebagai pemisah desimal.
  static String kg(num v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} kg';

  /// `1,1 km` di bawah 10 km, `12 km` di atasnya, `450 m` di bawah 1 km.
  static String jarak(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
    return '${km.round()} km';
  }

  static String tanggal(DateTime d) => _tanggal.format(d);
  static String tanggalPanjang(DateTime d) => _tanggalPanjang.format(d);
  static String jam(DateTime d) => _jam.format(d);

  /// Sisa waktu untuk hitung mundur: `2j 15m`, `45m`, `Habis`.
  static String sisaWaktu(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Habis';
    final jam = d.inHours;
    final menit = d.inMinutes % 60;
    if (jam >= 24) return '${d.inDays} hari';
    if (jam > 0) return '${jam}j ${menit}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}d';
  }

  /// `2 jam lalu`, `kemarin`, `3 hari lalu`.
  static String sejak(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'kemarin';
    if (d.inDays < 30) return '${d.inDays} hari lalu';
    return tanggal(t);
  }

  /// `nasi_lauk` → `Nasi Lauk`.
  static String kategori(String wire) => wire
      .split('_')
      .map((k) => k.isEmpty ? k : '${k[0].toUpperCase()}${k.substring(1)}')
      .join(' ');
}
