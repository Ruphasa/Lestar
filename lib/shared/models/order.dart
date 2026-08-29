import 'enums.dart';
import 'json.dart';

/// Tabel `orders`. Baris `order_items` dipisah ke [OrderItem].
class Order {
  const Order({
    required this.id,
    required this.consumerId,
    required this.merchantId,
    required this.subtotal,
    required this.greenFee,
    required this.total,
    required this.status,
    this.qrToken,
    this.qrExpiresAt,
    this.paymentMethod,
    required this.orderedAt,
    this.paidAt,
    this.claimedAt,
    this.items = const [],
  });

  final String id;
  final String consumerId;
  final String merchantId;
  final double subtotal;
  final double greenFee;
  final double total;
  final OrderStatus status;

  /// Unik. Dibuat saat pembayaran, bukan saat pemesanan.
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final String? paymentMethod;
  final DateTime orderedAt;
  final DateTime? paidAt;
  final DateTime? claimedAt;

  /// Diisi lewat `OrderRepository.itemsOf` atau select bersarang.
  /// Tidak ikut `toJson` — `order_items` tabel terpisah.
  final List<OrderItem> items;

  /// QR masih bisa dipakai: token ada, belum kedaluwarsa, order sudah dibayar.
  bool get qrValid =>
      qrToken != null &&
      status == OrderStatus.paid &&
      (qrExpiresAt == null || qrExpiresAt!.isAfter(DateTime.now()));

  int get totalPorsi => items.fold(0, (a, e) => a + e.qty);

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'];
    return Order(
      id: toStr(json['id']),
      consumerId: toStr(json['consumer_id']),
      merchantId: toStr(json['merchant_id']),
      subtotal: toDouble(json['subtotal']),
      greenFee: toDouble(json['green_fee']),
      total: toDouble(json['total']),
      status: OrderStatus.parse(json['status']),
      qrToken: toStrOpsional(json['qr_token']),
      qrExpiresAt: dtOpsional(json['qr_expires_at']),
      paymentMethod: toStrOpsional(json['payment_method']),
      orderedAt: dtWajib(json['ordered_at']),
      paidAt: dtOpsional(json['paid_at']),
      claimedAt: dtOpsional(json['claimed_at']),
      items: rawItems is List
          ? rawItems
                .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => tanpaNull({
    'consumer_id': consumerId,
    'merchant_id': merchantId,
    'subtotal': subtotal,
    'green_fee': greenFee,
    'total': total,
    'status': status.wire,
    'qr_token': qrToken,
    'qr_expires_at': qrExpiresAt?.toUtc().toIso8601String(),
    'payment_method': paymentMethod,
    'paid_at': paidAt?.toUtc().toIso8601String(),
    'claimed_at': claimedAt?.toUtc().toIso8601String(),
  });

  Order copyWith({
    OrderStatus? status,
    String? qrToken,
    DateTime? qrExpiresAt,
    String? paymentMethod,
    DateTime? paidAt,
    DateTime? claimedAt,
    List<OrderItem>? items,
  }) => Order(
    id: id,
    consumerId: consumerId,
    merchantId: merchantId,
    subtotal: subtotal,
    greenFee: greenFee,
    total: total,
    status: status ?? this.status,
    qrToken: qrToken ?? this.qrToken,
    qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    orderedAt: orderedAt,
    paidAt: paidAt ?? this.paidAt,
    claimedAt: claimedAt ?? this.claimedAt,
    items: items ?? this.items,
  );
}

/// Tabel `order_items`. `name_snapshot` dan `unit_price` sengaja disalin saat
/// pemesanan — harga listing bisa berubah, nota tidak boleh ikut berubah.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    this.listingId,
    required this.nameSnapshot,
    required this.qty,
    required this.unitPrice,
  });

  final String id;
  final String orderId;
  final String? listingId;
  final String nameSnapshot;
  final int qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: toStr(json['id']),
    orderId: toStr(json['order_id']),
    listingId: toStrOpsional(json['listing_id']),
    nameSnapshot: toStr(json['name_snapshot']),
    qty: toInt(json['qty']),
    unitPrice: toDouble(json['unit_price']),
  );

  Map<String, dynamic> toJson() => tanpaNull({
    'order_id': orderId,
    'listing_id': listingId,
    'name_snapshot': nameSnapshot,
    'qty': qty,
    'unit_price': unitPrice,
  });

  /// Item yang belum punya order — dipakai `OrderRepository.createOrder`,
  /// yang mengisi `orderId` setelah order induknya lahir.
  factory OrderItem.baru({
    required String listingId,
    required String nameSnapshot,
    required int qty,
    required double unitPrice,
  }) => OrderItem(
    id: '',
    orderId: '',
    listingId: listingId,
    nameSnapshot: nameSnapshot,
    qty: qty,
    unitPrice: unitPrice,
  );
}
