import 'enums.dart';
import 'json.dart';

/// Tabel `partners`. `partners.id` = `profiles.id` = `auth.uid()`.
class Partner {
  const Partner({
    required this.id,
    required this.orgName,
    this.partnerType,
    required this.wastePreference,
    this.vehicleType,
    this.licensePlate,
    required this.serviceRadiusKm,
    required this.baseLat,
    required this.baseLng,
    required this.totalPickups,
    this.subscriptionExpiry,
  });

  final String id;
  final String orgName;

  /// Bebas: `maggot`, `kompos`, `peternakan`, dst.
  final String? partnerType;

  /// Kolom `waste_type[]` di Postgres: `{wet}`, `{dry}`, `{wet,dry}`.
  final List<WasteType> wastePreference;

  final String? vehicleType;
  final String? licensePlate;
  final double serviceRadiusKm;
  final double baseLat;
  final double baseLng;
  final int totalPickups;
  final DateTime? subscriptionExpiry;

  bool get langgananAktif =>
      subscriptionExpiry != null &&
      subscriptionExpiry!.isAfter(DateTime.now());

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
    id: toStr(json['id']),
    orgName: toStr(json['org_name']),
    partnerType: toStrOpsional(json['partner_type']),
    wastePreference: WasteType.parseList(json['waste_preference']),
    vehicleType: toStrOpsional(json['vehicle_type']),
    licensePlate: toStrOpsional(json['license_plate']),
    serviceRadiusKm: toDouble(json['service_radius_km'], 10),
    baseLat: toDouble(json['base_lat']),
    baseLng: toDouble(json['base_lng']),
    totalPickups: toInt(json['total_pickups']),
    subscriptionExpiry: dtOpsional(json['subscription_expiry']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'org_name': orgName,
    'partner_type': partnerType,
    'waste_preference': wastePreference.map((e) => e.wire).toList(),
    'vehicle_type': vehicleType,
    'license_plate': licensePlate,
    'service_radius_km': serviceRadiusKm,
    'base_lat': baseLat,
    'base_lng': baseLng,
    'total_pickups': totalPickups,
    'subscription_expiry': subscriptionExpiry?.toUtc().toIso8601String(),
  });

  Partner copyWith({
    String? orgName,
    String? partnerType,
    List<WasteType>? wastePreference,
    String? vehicleType,
    String? licensePlate,
    double? serviceRadiusKm,
    double? baseLat,
    double? baseLng,
    int? totalPickups,
    DateTime? subscriptionExpiry,
  }) => Partner(
    id: id,
    orgName: orgName ?? this.orgName,
    partnerType: partnerType ?? this.partnerType,
    wastePreference: wastePreference ?? this.wastePreference,
    vehicleType: vehicleType ?? this.vehicleType,
    licensePlate: licensePlate ?? this.licensePlate,
    serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
    baseLat: baseLat ?? this.baseLat,
    baseLng: baseLng ?? this.baseLng,
    totalPickups: totalPickups ?? this.totalPickups,
    subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
  );
}
