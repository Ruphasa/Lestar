import 'enums.dart';
import 'json.dart';

/// Tabel `listings` — surplus yang dijual ke konsumen.
///
/// Gerbang validasi fisik ditegakkan database: `status = 'live'` ditolak
/// kalau `physical_validated` false atau `triage_score < 70`.
class Listing {
  const Listing({
    required this.id,
    required this.merchantId,
    required this.name,
    this.description,
    required this.category,
    this.imageUrl,
    required this.qtyTotal,
    required this.qtyRemaining,
    required this.originalPrice,
    required this.price,
    required this.cookedAt,
    required this.expiresAt,
    this.triageScore,
    this.triageReason,
    required this.physicalValidated,
    this.physicalValidatedAt,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String merchantId;
  final String name;
  final String? description;

  /// Salah satu dari `LestarConstants.kategoriListing`.
  final String category;

  /// Masih null untuk seluruh baris seed — lihat `A-HANDOFF.md` §8.2.
  /// D dan E wajib menyiapkan placeholder, ini kondisi sekarang.
  final String? imageUrl;

  final int qtyTotal;
  final int qtyRemaining;
  final double originalPrice;
  final double price;
  final DateTime cookedAt;
  final DateTime expiresAt;
  final int? triageScore;
  final String? triageReason;
  final bool physicalValidated;
  final DateTime? physicalValidatedAt;
  final ListingStatus status;
  final DateTime createdAt;

  /// 0.52 berarti diskon 52%.
  double get discountPercent =>
      originalPrice <= 0 ? 0 : (originalPrice - price) / originalPrice;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Duration get sisaWaktu => expiresAt.difference(DateTime.now());

  /// Layak tampil di radar konsumen.
  bool get tampilDiRadar =>
      status == ListingStatus.live && qtyRemaining > 0 && !isExpired;

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: toStr(json['id']),
    merchantId: toStr(json['merchant_id']),
    name: toStr(json['name']),
    description: toStrOpsional(json['description']),
    category: toStr(json['category'], 'lainnya'),
    imageUrl: toStrOpsional(json['image_url']),
    qtyTotal: toInt(json['qty_total']),
    qtyRemaining: toInt(json['qty_remaining']),
    originalPrice: toDouble(json['original_price']),
    price: toDouble(json['price']),
    cookedAt: dtWajib(json['cooked_at']),
    expiresAt: dtWajib(json['expires_at']),
    triageScore: toIntOpsional(json['triage_score']),
    triageReason: toStrOpsional(json['triage_reason']),
    physicalValidated: toBool(json['physical_validated']),
    physicalValidatedAt: dtOpsional(json['physical_validated_at']),
    status: ListingStatus.parse(json['status']),
    createdAt: dtWajib(json['created_at']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'merchant_id': merchantId,
    'name': name,
    'description': description,
    'category': category,
    'image_url': imageUrl,
    'qty_total': qtyTotal,
    'qty_remaining': qtyRemaining,
    'original_price': originalPrice,
    'price': price,
    'cooked_at': cookedAt.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'triage_score': triageScore,
    'triage_reason': triageReason,
    'physical_validated': physicalValidated,
    'physical_validated_at': physicalValidatedAt?.toUtc().toIso8601String(),
    'status': status.wire,
  });

  Listing copyWith({
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    int? qtyTotal,
    int? qtyRemaining,
    double? originalPrice,
    double? price,
    DateTime? cookedAt,
    DateTime? expiresAt,
    int? triageScore,
    String? triageReason,
    bool? physicalValidated,
    DateTime? physicalValidatedAt,
    ListingStatus? status,
  }) => Listing(
    id: id,
    merchantId: merchantId,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    qtyTotal: qtyTotal ?? this.qtyTotal,
    qtyRemaining: qtyRemaining ?? this.qtyRemaining,
    originalPrice: originalPrice ?? this.originalPrice,
    price: price ?? this.price,
    cookedAt: cookedAt ?? this.cookedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    triageScore: triageScore ?? this.triageScore,
    triageReason: triageReason ?? this.triageReason,
    physicalValidated: physicalValidated ?? this.physicalValidated,
    physicalValidatedAt: physicalValidatedAt ?? this.physicalValidatedAt,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
