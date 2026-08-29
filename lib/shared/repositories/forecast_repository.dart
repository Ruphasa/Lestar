import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// `forecasts` + `sales_history` — bahan Buffer Intelligence.
class ForecastRepository {
  /// Ramalan yang sudah tersimpan untuk satu merchant pada satu tanggal.
  ///
  /// Layar merchant memanggil ini dulu; kalau null, barulah ia menembak
  /// `/forecast` (atau `FallbackEngine`) lalu menyimpannya lewat
  /// [saveForecast]. Satu kali hitung per hari, bukan setiap layar dibuka.
  Future<Forecast?> getForecast(String merchantId, DateTime date) async {
    final row = await supabase
        .from('forecasts')
        .select()
        .eq('merchant_id', merchantId)
        .eq('forecast_date', dateKeWire(date))
        .maybeSingle();
    return row == null ? null : Forecast.fromJson(row);
  }

  /// `upsert` supaya menghitung ulang di hari yang sama menimpa, bukan
  /// menumpuk baris kedua.
  Future<Forecast> saveForecast(Forecast forecast) async {
    final row = await supabase
        .from('forecasts')
        .upsert(forecast.toJson(), onConflict: 'merchant_id,forecast_date')
        .select()
        .single();
    return Forecast.fromJson(row);
  }

  /// 14 baris terakhir, terbaru dulu — urutan yang diharapkan
  /// `FallbackEngine.forecast` (`history.first` = hari kemarin).
  Future<List<SalesHistory>> recentSalesHistory(
    String merchantId, {
    int days = 14,
  }) async {
    final rows = await supabase
        .from('sales_history')
        .select()
        .eq('merchant_id', merchantId)
        .order('date', ascending: false)
        .limit(days);
    return rows.map(SalesHistory.fromJson).toList();
  }
}
