import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_checkout_controller.dart';
import 'qr_screen.dart';
import 'widgets/consumer_widgets.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final NearbyListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(checkoutBusyProvider(listing.id));
    final error = ref.watch(checkoutErrorProvider(listing.id));
    final expired = listing.expiresAt.isBefore(DateTime.now());
    final available = !expired && listing.qtyRemaining > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton.filledTonal(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ConsumerBackdrop(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 320,
              child: Hero(
                tag: 'listing-${listing.id}',
                child: ConsumerFoodImage(
                  imageUrl: listing.imageUrl,
                  category: listing.category,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.name,
                          style: LestarType.judulLayar(
                            color: LestarTokens.forest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DiscountPill(percent: listing.discountPercent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listing.storeName} · ${Fmt.jarak(listing.jarakKm)}',
                    style: LestarType.isi(color: LestarTokens.muted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    listing.storeAddress,
                    style: LestarType.label(color: LestarTokens.muted),
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PriceText(
                          price: listing.price,
                          originalPrice: listing.originalPrice,
                          size: 25,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            CountdownChip(expiresAt: listing.expiresAt),
                            _InfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: 'Sisa ${listing.qtyRemaining} porsi',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (listing.description?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 20),
                    Text('Tentang makanan ini', style: LestarType.judulKartu()),
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: LestarType.isi(color: LestarTokens.muted),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: LestarType.label(color: LestarTokens.danger),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: available && !busy
                          ? () => _order(context, ref)
                          : null,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_bag_outlined),
                      label: Text(
                        expired ? 'Penawaran berakhir' : 'Pesan sekarang',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _order(BuildContext context, WidgetRef ref) async {
    final busy = ref.read(checkoutBusyProvider(listing.id).notifier);
    final error = ref.read(checkoutErrorProvider(listing.id).notifier);
    busy.setValue(true);
    error.setValue(null);
    try {
      final order = await ref
          .read(consumerCheckoutControllerProvider)
          .createOrder(listing);
      if (!context.mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) =>
              ConsumerPaymentScreen(order: order, listing: listing),
        ),
      );
    } catch (exception) {
      error.setValue(pesanError(exception));
    } finally {
      busy.setValue(false);
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: LestarTokens.emeraldTint,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: LestarTokens.emeraldDeep),
        const SizedBox(width: 6),
        Text(label, style: LestarType.label(color: LestarTokens.forest)),
      ],
    ),
  );
}

class ConsumerPaymentScreen extends ConsumerWidget {
  const ConsumerPaymentScreen({
    super.key,
    required this.order,
    required this.listing,
  });

  final Order order;
  final NearbyListing listing;

  static const methods = ['QRIS', 'GoPay', 'Tunai di toko'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(checkoutPaymentMethodProvider(order.id));
    final busy = ref.watch(checkoutBusyProvider(order.id));
    final error = ref.watch(checkoutErrorProvider(order.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ConsumerBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GlassCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: ConsumerFoodImage(
                        imageUrl: listing.imageUrl,
                        category: listing.category,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LestarType.display(size: 17, wght: 600),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          listing.storeName,
                          style: LestarType.label(color: LestarTokens.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Pilih metode',
              style: LestarType.judulKartu(color: LestarTokens.forest),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: method,
                onChanged: busy
                    ? (_) {}
                    : (value) {
                        if (value != null) {
                          ref
                              .read(
                                checkoutPaymentMethodProvider(
                                  order.id,
                                ).notifier,
                              )
                              .setValue(value);
                        }
                      },
                child: Column(
                  children: [
                    for (final item in methods)
                      RadioListTile<String>(
                        value: item,
                        enabled: !busy,
                        activeColor: LestarTokens.emeraldDeep,
                        title: Text(item),
                        secondary: Icon(
                          _paymentIcon(item),
                          color: LestarTokens.emeraldDeep,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Rincian harga',
              style: LestarType.judulKartu(color: LestarTokens.forest),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  _PriceLine(label: 'Subtotal', value: order.subtotal),
                  const SizedBox(height: 12),
                  _PriceLine(
                    label: 'Green Fee',
                    value: LestarConstants.greenFee.toDouble(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _PriceLine(
                    label: 'Total',
                    value: order.total,
                    emphasized: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LestarTokens.emeraldTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Green Fee mendukung mesin kalkulasi emisi dan infrastruktur realtime Lestar.',
                      style: LestarType.label(color: LestarTokens.forest),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(error, style: LestarType.label(color: LestarTokens.danger)),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: busy ? null : () => _pay(context, ref, method),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                busy
                    ? 'Memproses pembayaran...'
                    : 'Bayar ${Fmt.rupiah(order.total)}',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pembayaran ini simulasi untuk demo. Tidak ada dana yang dipindahkan.',
              textAlign: TextAlign.center,
              style: LestarType.caption(color: LestarTokens.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, String method) async {
    final busy = ref.read(checkoutBusyProvider(order.id).notifier);
    final error = ref.read(checkoutErrorProvider(order.id).notifier);
    busy.setValue(true);
    error.setValue(null);
    try {
      final paid = await ref
          .read(consumerCheckoutControllerProvider)
          .pay(order, method);
      if (!context.mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => QrScreen(
            initialData: ConsumerQrPresentation(
              order: paid,
              storeName: listing.storeName,
              storeAddress: listing.storeAddress,
            ),
          ),
        ),
      );
    } catch (exception) {
      error.setValue(pesanError(exception));
    } finally {
      busy.setValue(false);
    }
  }

  IconData _paymentIcon(String method) => switch (method) {
    'QRIS' => Icons.qr_code_2,
    'GoPay' => Icons.account_balance_wallet_outlined,
    _ => Icons.storefront_outlined,
  };
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: emphasized
              ? LestarType.judulKartu(color: LestarTokens.inkSoft)
              : LestarType.isi(color: LestarTokens.muted),
        ),
      ),
      Text(
        Fmt.rupiah(value),
        style: emphasized
            ? LestarType.judulKartu(color: LestarTokens.orangeText)
            : LestarType.body(size: 15, wght: 600, color: LestarTokens.inkSoft),
      ),
    ],
  );
}
