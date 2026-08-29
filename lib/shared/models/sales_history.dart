import 'json.dart';

/// Tabel `sales_history` — bahan mentah forecast.
///
/// **`dayOfWeek` 0 = Senin, 6 = Minggu** (Postgres `extract(isodow) - 1`).
/// Bukan konvensi `DateTime.weekday` Dart yang 1 = Senin. Konversi dari
/// `DateTime` lewat [dayOfWeekDari].
class SalesHistory {
  const SalesHistory({
    required this.id,
    required this.merchantId,
    required this.date,
    required this.portionsSold,
    required this.revenue,
    required this.dayOfWeek,
    required this.isHoliday,
    this.weatherCode,
    required this.surplusKg,
  });

  final String id;
  final String merchantId;

  /// Kolom `date`. Unik per `(merchant_id, date)`.
  final DateTime date;

  final int portionsSold;
  final double revenue;

  /// 0 = Senin … 6 = Minggu.
  final int dayOfWeek;

  final bool isHoliday;

  /// 0 cerah · 1 berawan · 2 mendung · 3 hujan.
  final int? weatherCode;

  final double surplusKg;

  /// Konversi `DateTime.weekday` (1=Senin) ke konvensi tabel (0=Senin).
  static int dayOfWeekDari(DateTime d) => d.weekday - 1;

  factory SalesHistory.fromJson(Map<String, dynamic> json) => SalesHistory(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    date: dateWajib(json['date']),
    portionsSold: toInt(json['portions_sold']),
    revenue: toDouble(json['revenue']),
    dayOfWeek: toInt(json['day_of_week']),
    isHoliday: toBool(json['is_holiday']),
    weatherCode: toIntOpsional(json['weather_code']),
    surplusKg: toDouble(json['surplus_kg']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'merchant_id': merchantId,
    'date': dateKeWire(date),
    'portions_sold': portionsSold,
    'revenue': revenue,
    'day_of_week': dayOfWeek,
    'is_holiday': isHoliday,
    'weather_code': weatherCode,
    'surplus_kg': surplusKg,
  });
}
