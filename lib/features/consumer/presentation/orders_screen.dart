import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_providers.dart';
import 'qr_screen.dart';
import 'widgets/consumer_widgets.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(consumerOrdersProvider);
    return ConsumerBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan',
                  style: LestarType.judulLayar(color: LestarTokens.forest),
                ),
                const SizedBox(height: 5),
                Text(
                  'Jejak makanan yang kamu selamatkan.',
                  style: LestarType.isi(color: LestarTokens.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ConsumerErrorState(
                message: pesanError(error),
                onRetry: () => ref.invalidate(consumerOrdersProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada pesanan',
                    message: 'Flash deal yang kamu pesan akan muncul di sini.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(consumerOrdersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => _OrderCard(
                      order: items[index],
                      onOpenQr: items[index].qrValid
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const QrScreen(),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onOpenQr});

  final Order order;
  final VoidCallback? onOpenQr;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: LestarTokens.emeraldTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: LestarTokens.emeraldDeep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesanan #${_shortId(order.id)}',
                    style: LestarType.display(size: 17, wght: 600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Fmt.tanggal(order.orderedAt),
                    style: LestarType.label(color: LestarTokens.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _OrderStatusChip(status: order.status),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total',
                style: LestarType.label(color: LestarTokens.muted),
              ),
            ),
            Text(
              Fmt.rupiah(order.total),
              style: LestarType.judulKartu(color: LestarTokens.orangeText),
            ),
          ],
        ),
        if (onOpenQr != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenQr,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Tampilkan QR'),
            ),
          ),
        ],
      ],
    ),
  );

  static String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      OrderStatus.pending => (
        'Menunggu',
        LestarTokens.orangeText,
        LestarTokens.orangeTint,
      ),
      OrderStatus.paid => (
        'Dibayar',
        LestarTokens.forest,
        LestarTokens.emeraldTint,
      ),
      OrderStatus.ready => (
        'Siap',
        LestarTokens.forest,
        LestarTokens.emeraldTint,
      ),
      OrderStatus.claimed => (
        'Diambil',
        LestarTokens.forest,
        LestarTokens.emeraldTint,
      ),
      OrderStatus.cancelled => (
        'Dibatalkan',
        LestarTokens.danger,
        const Color(0xFFFFEAEA),
      ),
      OrderStatus.expired => (
        'Kedaluwarsa',
        LestarTokens.muted,
        LestarTokens.surfaceGrey,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: LestarType.caption(color: color)),
    );
  }
}
