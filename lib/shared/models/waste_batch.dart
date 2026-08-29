import 'enums.dart';
import 'json.dart';

/// Tabel `waste_batches` — jalur B2B.
///
/// `sourceListingId` terisi berarti batch ini lahir dari kaskade B2C:
/// makanan yang tidak terklaim dialihkan, bukan dibuang. Itu jejak yang
/// ditampilkan di radar pengepul.
class WasteBatch {
  const WasteBatch({
    required this.id,
    required this.sourceMerchantId,
    this.sourceListingId,
    required this.wasteType,
    this.description,
    required this.weightKg,
    required this.price,
    required this.pickupAddress,
    required this.lat,
    required this.lng,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    this.imageUrl,
    required this.status,
    this.matchedPartnerId,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String sourceMerchantId;
  final String? sourceListingId;
  final WasteType wasteType;
  final String? description;
  final double weightKg;
  final double price;
  final String pickupAddress;
  final double lat;
  final double lng;
  final DateTime? pickupWindowStart;
  final DateTime? pickupWindowEnd;
  final String? imageUrl;
  final WasteStatus status;
  final String? matchedPartnerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get dariKaskade => sourceListingId != null;

  double get co2DihindariKg => weightKg * 0.25;

  factory WasteBatch.fromJson(Map<String, dynamic> json) => WasteBatch(
    id: toStr(json['id']),
    sourceMerchantId: toStr(json['source_merchant_id']),
    sourceListingId: toStrOpsional(json['source_listing_id']),
    wasteType: WasteType.parse(json['waste_type']),
    description: toStrOpsional(json['description']),
    weightKg: toDouble(json['weight_kg']),
    price: toDouble(json['price']),
    pickupAddress: toStr(json['pickup_address']),
    lat: toDouble(json['lat']),
    lng: toDouble(json['lng']),
    pickupWindowStart: dtOpsional(json['pickup_window_start']),
    pickupWindowEnd: dtOpsional(json['pickup_window_end']),
    imageUrl: toStrOpsional(json['image_url']),
    status: WasteStatus.parse(json['status']),
    matchedPartnerId: toStrOpsional(json['matched_partner_id']),
    createdAt: dtWajib(json['created_at']),
    completedAt: dtOpsional(json['completed_at']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'source_merchant_id': sourceMerchantId,
    'source_listing_id': sourceListingId,
    'waste_type': wasteType.wire,
    'description': description,
    'weight_kg': weightKg,
    'price': price,
    'pickup_address': pickupAddress,
    'lat': lat,
    'lng': lng,
    'pickup_window_start': pickupWindowStart?.toUtc().toIso8601String(),
    'pickup_window_end': pickupWindowEnd?.toUtc().toIso8601String(),
    'image_url': imageUrl,
    'status': status.wire,
    'matched_partner_id': matchedPartnerId,
    'completed_at': completedAt?.toUtc().toIso8601String(),
  });

  WasteBatch copyWith({
    WasteType? wasteType,
    String? description,
    double? weightKg,
    double? price,
    String? pickupAddress,
    double? lat,
    double? lng,
    DateTime? pickupWindowStart,
    DateTime? pickupWindowEnd,
    String? imageUrl,
    WasteStatus? status,
    String? matchedPartnerId,
    DateTime? completedAt,
  }) => WasteBatch(
    id: id,
    sourceMerchantId: sourceMerchantId,
    sourceListingId: sourceListingId,
    wasteType: wasteType ?? this.wasteType,
    description: description ?? this.description,
    weightKg: weightKg ?? this.weightKg,
    price: price ?? this.price,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
    pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    matchedPartnerId: matchedPartnerId ?? this.matchedPartnerId,
    createdAt: createdAt,
    completedAt: completedAt ?? this.completedAt,
  );
}
