import 'json.dart';

/// Tabel `merchants`. `merchants.id` = `profiles.id` = `auth.uid()`.
/// Tidak ada kolom `merchant_id` terpisah di tabel ini.
class Merchant {
  const Merchant({
    required this.id,
    required this.storeName,
    required this.storeAddress,
    required this.lat,
    required this.lng,
    this.storeImage,
    this.category,
    this.operatingHours,
    required this.cutoffTime,
    required this.rating,
    required this.totalEarnings,
    required this.totalWasteSavedKg,
    required this.level,
  });

  final String id;
  final String storeName;
  final String storeAddress;
  final double lat;
  final double lng;
  final String? storeImage;
  final String? category;
  final String? operatingHours;

  /// Kolom `time` Postgres, mis. `22:00:00`. Disimpan apa adanya sebagai
  /// String — tidak ada tanggal yang menempel padanya, jadi `DateTime`
  /// justru menyesatkan. Pakai [cutoffJam] / [cutoffMenit] untuk berhitung.
  final String cutoffTime;

  final double rating;
  final double totalEarnings;
  final double totalWasteSavedKg;
  final int level;

  int get cutoffJam => toInt(cutoffTime.split(':').firstOrNull);
  int get cutoffMenit => toInt(cutoffTime.split(':').elementAtOrNull(1));

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
    id: toStr(json['id']),
    storeName: toStr(json['store_name']),
    storeAddress: toStr(json['store_address']),
    lat: toDouble(json['lat']),
    lng: toDouble(json['lng']),
    storeImage: toStrOpsional(json['store_image']),
    category: toStrOpsional(json['category']),
    operatingHours: toStrOpsional(json['operating_hours']),
    cutoffTime: toStr(json['cutoff_time'], '22:00:00'),
    rating: toDouble(json['rating']),
    totalEarnings: toDouble(json['total_earnings']),
    totalWasteSavedKg: toDouble(json['total_waste_saved_kg']),
    level: toInt(json['level'], 1),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'store_name': storeName,
    'store_address': storeAddress,
    'lat': lat,
    'lng': lng,
    'store_image': storeImage,
    'category': category,
    'operating_hours': operatingHours,
    'cutoff_time': cutoffTime,
    'rating': rating,
    'total_earnings': totalEarnings,
    'total_waste_saved_kg': totalWasteSavedKg,
    'level': level,
  });

  Merchant copyWith({
    String? storeName,
    String? storeAddress,
    double? lat,
    double? lng,
    String? storeImage,
    String? category,
    String? operatingHours,
    String? cutoffTime,
    double? rating,
    double? totalEarnings,
    double? totalWasteSavedKg,
    int? level,
  }) => Merchant(
    id: id,
    storeName: storeName ?? this.storeName,
    storeAddress: storeAddress ?? this.storeAddress,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    storeImage: storeImage ?? this.storeImage,
    category: category ?? this.category,
    operatingHours: operatingHours ?? this.operatingHours,
    cutoffTime: cutoffTime ?? this.cutoffTime,
    rating: rating ?? this.rating,
    totalEarnings: totalEarnings ?? this.totalEarnings,
    totalWasteSavedKg: totalWasteSavedKg ?? this.totalWasteSavedKg,
    level: level ?? this.level,
  );
}
