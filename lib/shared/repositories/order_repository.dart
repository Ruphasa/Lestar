import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/models.dart';

/// `orders` + `order_items`.
///
/// Catatan penting dari Agent A: stok berkurang saat `claimed`, bukan saat
/// `paid`, lewat trigger `sync_qty_remaining` di `orders`. Aplikasi tidak
/// perlu — dan tidak boleh — mengurangi `qty_remaining` sendiri.
/// `esg_events` juga lahir dari trigger, bukan dari sini.
class OrderRepository {
  static const _uuid = Uuid();

  /// Membuat pesanan `pending` beserta itemnya.
  ///
  /// `subtotal` dihitung dari item, `green_fee` dari konstanta bersama, dan
  /// `total` adalah jumlah keduanya. `name_snapshot` dan `unit_price` disalin
  /// saat ini juga supaya nota tidak berubah kalau harga listing bergerak.
  Future<Order> createOrder({
    required String merchantId,
    required List<OrderItem> items,
  }) async {
    final consumerId = uidSekarang;
    if (consumerId == null) {
      throw StateError('Belum masuk — tidak bisa membuat pesanan.');
    }
    if (items.isEmpty) {
      throw ArgumentError('Pesanan tanpa item.');
    }

    final subtotal = items.fold<double>(0, (a, e) => a + e.lineTotal);
    final greenFee = LestarConstants.greenFee.toDouble();

    final orderRow = await supabase
        .from('orders')
        .insert({
          'consumer_id': consumerId,
          'merchant_id': merchantId,
          'subtotal': subtotal,
          'green_fee': greenFee,
          'total': subtotal + greenFee,
          'status': OrderStatus.pending.wire,
        })
        .select()
        .single();

    final orderId = orderRow['id'] as String;

    final itemRows = await supabase
        .from('order_items')
        .insert([
          for (final i in items)
            {
              'order_id': orderId,
              'listing_id': i.listingId,
              'name_snapshot': i.nameSnapshot,
              'qty': i.qty,
              'unit_price': i.unitPrice,
            },
        ])
        .select();

    return Order.fromJson(orderRow).copyWith(
      items: itemRows.map(OrderItem.fromJson).toList(),
    );
  }

  /// Pembayaran simulasi. QR baru lahir di sini — sebelum dibayar, tidak ada
  /// yang bisa diklaim.
  Future<Order> pay(String orderId, {String paymentMethod = 'simulasi'}) async {
    final now = DateTime.now();
    final row = await supabase
        .from('orders')
        .update({
          'status': OrderStatus.paid.wire,
          'payment_method': paymentMethod,
          'paid_at': now.toUtc().toIso8601String(),
          'qr_token': _uuid.v4(),
          'qr_expires_at': now
              .add(const Duration(hours: LestarConstants.qrMasaBerlakuJam))
              .toUtc()
              .toIso8601String(),
        })
        .eq('id', orderId)
        .select()
        .single();
    return Order.fromJson(row);
  }

  /// Merchant memindai QR konsumen.
  ///
  /// Masa berlaku dan status diperiksa di sini karena database sengaja tidak
  /// membatasi transisi status (keputusan Agent A no. 13) — lapisan aplikasi
  /// yang memutuskan. Melempar [StateError] dengan pesan siap tampil.
  Future<Order> claimByQr(String qrToken) async {
    final row = await supabase
        .from('orders')
        .select()
        .eq('qr_token', qrToken)
        .maybeSingle();

    if (row == null) {
      throw StateError('QR tidak dikenali.');
    }

    final order = Order.fromJson(row);
    if (order.status == OrderStatus.claimed) {
      throw StateError('QR ini sudah pernah diklaim.');
    }
    if (order.status != OrderStatus.paid) {
      throw StateError('Pesanan belum dibayar.');
    }
    if (order.qrExpiresAt != null &&
        order.qrExpiresAt!.isBefore(DateTime.now())) {
      throw StateError('QR sudah kedaluwarsa.');
    }

    final updated = await supabase
        .from('orders')
        .update({
          'status': OrderStatus.claimed.wire,
          'claimed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', order.id)
        .select()
        .single();
    return Order.fromJson(updated);
  }

  /// Realtime aktif di `orders`. Difilter ulang di klien — lihat catatan yang
  /// sama di `ListingRepository.liveListingsStream`.
  Stream<List<Order>> consumerOrders(String consumerId) => supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(Order.fromJson)
                .where((o) => o.consumerId == consumerId)
                .toList()
              ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt)),
      );

  Stream<List<Order>> merchantOrders(String merchantId) => supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows
                .map(Order.fromJson)
                .where((o) => o.merchantId == merchantId)
                .toList()
              ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt)),
      );

  /// `.stream()` tidak bisa membawa join, jadi item diambil terpisah saat
  /// layar detail membutuhkannya.
  Future<List<OrderItem>> itemsOf(String orderId) async {
    final rows = await supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId);
    return rows.map(OrderItem.fromJson).toList();
  }

  /// Satu pesanan lengkap dengan itemnya, lewat select bersarang.
  Future<Order?> getOrder(String orderId) async {
    final row = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : Order.fromJson(row);
  }
}
