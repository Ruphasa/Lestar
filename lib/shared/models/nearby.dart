import 'enums.dart';
import 'json.dart';

/// Baris hasil RPC `nearby_listings(p_lat, p_lng, p_radius_km)`.
///
/// Bukan tabel — ini gabungan `listings` + `merchants` + jarak, kolomnya
/// persis seperti di `A-HANDOFF.md` §2. Hasil selalu terurut `jarak_km`
/// menaik, dan RPC sudah menyaring `status='live'`, `qty_remaining > 0`,
/// dan `expires_at > now()`.
class NearbyListing {
  const NearbyListing({
    required this.id,
    required this.merchantId,
    required this.storeName,
    required this.storeAddress,
    this.storeImage,
    required this.name,
    this.description,
    required this.category,
    this.imageUrl,
    required this.qtyRemaining,
    required this.originalPrice,
    required this.price,
    required this.cookedAt,
    required this.expiresAt,
    this.triageScore,
    this.triageReason,
    required this.lat,
    required this.lng,
    required this.jarakKm,
  });

  final String id;
  final String merchantId;
  final String storeName;
  final String storeAddress;
  final String? storeImage;
  final String name;
  final String? description;
  final String category;
  final String? imageUrl;
  final int qtyRemaining;
  final double originalPrice;
  final double price;
  final DateTime cookedAt;
  final DateTime expiresAt;
  final int? triageScore;
  final String? triageReason;

  /// Koordinat **toko**, bukan koordinat listing.
  final double lat;
  final double lng;

  final double jarakKm;

  double get discountPercent =>
      originalPrice <= 0 ? 0 : (originalPrice - price) / originalPrice;

  Duration get sisaWaktu => expiresAt.difference(DateTime.now());

  factory NearbyListing.fromJson(Map<String, dynamic> json) => NearbyListing(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    storeName: toStr(json['store_name']),
    storeAddress: toStr(json['store_address']),
    storeImage: toStrOpsional(json['store_image']),
    name: toStr(json['name']),
    description: toStrOpsional(json['description']),
    category: toStr(json['category'], 'lainnya'),
    imageUrl: toStrOpsional(json['image_url']),
    qtyRemaining: toInt(json['qty_remaining']),
    originalPrice: toDouble(json['original_price']),
    price: toDouble(json['price']),
    cookedAt: dtWajib(json['cooked_at']),
    expiresAt: dtWajib(json['expires_at']),
    triageScore: toIntOpsional(json['triage_score']),
    triageReason: toStrOpsional(json['triage_reason']),
    lat: toDouble(json['lat']),
    lng: toDouble(json['lng']),
    jarakKm: toDouble(json['jarak_km']),
  );
}

/// Baris hasil RPC `nearby_waste(p_lat, p_lng, p_radius_km)`.
/// Hanya batch `status = 'available'`, terurut `jarak_km` menaik.
class NearbyWaste {
  const NearbyWaste({
    required this.id,
    required this.sourceMerchantId,
    required this.storeName,
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
    required this.createdAt,
    required this.jarakKm,
  });

  final String id;
  final String sourceMerchantId;
  final String storeName;

  /// Tidak null = batch ini lahir dari kaskade B2C.
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
  final DateTime createdAt;
  final double jarakKm;

  bool get dariKaskade => sourceListingId != null;

  factory NearbyWaste.fromJson(Map<String, dynamic> json) => NearbyWaste(
    id: toStr(json['id']),
    sourceMerchantId: toStr(json['source_merchant_id']),
    storeName: toStr(json['store_name']),
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
    createdAt: dtWajib(json['created_at']),
    jarakKm: toDouble(json['jarak_km']),
  );
}
