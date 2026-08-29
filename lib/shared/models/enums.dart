/// Tujuh enum Postgres, dipetakan ke Dart.
///
/// `wire` adalah nilai persis yang dipakai database — jangan diubah.
/// Setiap `parse` menerima `dynamic` dan tidak pernah melempar: nilai yang
/// tidak dikenal (kolom baru, enum yang berkembang, data korup) jatuh ke
/// nilai default. Layar yang salah lebih baik daripada layar yang mati.
library;

enum UserRole {
  consumer('consumer'),
  merchant('merchant'),
  partner('partner');

  const UserRole(this.wire);
  final String wire;

  static UserRole parse(dynamic v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => UserRole.consumer);
}

enum ListingStatus {
  draft('draft'),
  live('live'),
  soldOut('sold_out'),
  expired('expired'),
  cascaded('cascaded');

  const ListingStatus(this.wire);
  final String wire;

  static ListingStatus parse(dynamic v) => values.firstWhere(
    (e) => e.wire == v,
    orElse: () => ListingStatus.draft,
  );
}

enum WasteType {
  wet('wet'),
  dry('dry');

  const WasteType(this.wire);
  final String wire;

  static WasteType parse(dynamic v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => WasteType.wet);

  /// `waste_preference` di Postgres adalah array enum: `{wet,dry}`.
  static List<WasteType> parseList(dynamic v) {
    if (v is List) return v.map(WasteType.parse).toList();
    // Postgres kadang mengembalikan array sebagai literal '{wet,dry}'.
    if (v is String) {
      final isi = v.replaceAll(RegExp(r'[{}"]'), '').trim();
      if (isi.isEmpty) return const [];
      return isi.split(',').map((e) => WasteType.parse(e.trim())).toList();
    }
    return const [];
  }
}

enum WasteStatus {
  available('available'),
  matched('matched'),
  pickedUp('picked_up'),
  completed('completed'),
  cancelled('cancelled');

  const WasteStatus(this.wire);
  final String wire;

  static WasteStatus parse(dynamic v) => values.firstWhere(
    (e) => e.wire == v,
    orElse: () => WasteStatus.available,
  );
}

enum OrderStatus {
  pending('pending'),
  paid('paid'),
  ready('ready'),
  claimed('claimed'),
  cancelled('cancelled'),
  expired('expired');

  const OrderStatus(this.wire);
  final String wire;

  static OrderStatus parse(dynamic v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => OrderStatus.pending);
}

enum ForecastSource {
  lstmGemini('lstm_gemini'),
  lstmOnly('lstm_only'),
  heuristic('heuristic');

  const ForecastSource(this.wire);
  final String wire;

  /// Default sengaja `heuristic`: sumber yang tidak dikenali tidak boleh
  /// menyamar jadi hasil model. `forecasts.source` selalu jujur.
  static ForecastSource parse(dynamic v) => values.firstWhere(
    (e) => e.wire == v,
    orElse: () => ForecastSource.heuristic,
  );
}

enum EsgEventType {
  b2cRescued('b2c_rescued'),
  b2bDiverted('b2b_diverted');

  const EsgEventType(this.wire);
  final String wire;

  static EsgEventType parse(dynamic v) => values.firstWhere(
    (e) => e.wire == v,
    orElse: () => EsgEventType.b2cRescued,
  );
}
