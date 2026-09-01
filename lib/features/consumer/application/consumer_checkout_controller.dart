import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';

final consumerCheckoutControllerProvider = Provider(
  (ref) => ConsumerCheckoutController(ref),
);

class CheckoutValueNotifier<T> extends Notifier<T> {
  CheckoutValueNotifier(this.initialValue);

  final T initialValue;

  @override
  T build() => initialValue;

  void setValue(T value) => state = value;
}

final checkoutBusyProvider = NotifierProvider.autoDispose
    .family<CheckoutValueNotifier<bool>, bool, String>(
      (id) => CheckoutValueNotifier(false),
    );

final checkoutErrorProvider = NotifierProvider.autoDispose
    .family<CheckoutValueNotifier<String?>, String?, String>(
      (id) => CheckoutValueNotifier(null),
    );

final checkoutPaymentMethodProvider = NotifierProvider.autoDispose
    .family<CheckoutValueNotifier<String>, String, String>(
      (id) => CheckoutValueNotifier('QRIS'),
    );

class ConsumerCheckoutController {
  const ConsumerCheckoutController(this._ref);

  final Ref _ref;

  Future<Order> createOrder(NearbyListing listing, {int quantity = 1}) {
    if (quantity < 1 || quantity > listing.qtyRemaining) {
      throw ArgumentError('Jumlah pesanan tidak tersedia.');
    }
    return _ref
        .read(orderRepositoryProvider)
        .createOrder(
          merchantId: listing.merchantId,
          items: [
            OrderItem.baru(
              listingId: listing.id,
              nameSnapshot: listing.name,
              qty: quantity,
              unitPrice: listing.price,
            ),
          ],
        );
  }

  Future<Order> pay(Order pending, String paymentMethod) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final paid = await _ref
        .read(orderRepositoryProvider)
        .pay(pending.id, paymentMethod: paymentMethod);
    return paid.copyWith(items: pending.items);
  }
}
