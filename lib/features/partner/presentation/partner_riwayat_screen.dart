import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../application/partner_dashboard_controller.dart';
import 'partner_home_screen.dart';
import 'widgets/partner_plain_widgets.dart';

class PartnerRiwayatScreen extends ConsumerWidget {
  const PartnerRiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(currentPartnerProvider);
    return partnerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => PartnerLoadError(message: pesanError(error)),
      data: (partner) {
        if (partner == null) {
          return const PartnerLoadError(
            message: 'AKUN PENGEPUL TIDAK DITEMUKAN.',
          );
        }
        final history = ref.watch(partnerHistoryProvider(partner.id));
        return history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => PartnerLoadError(message: pesanError(error)),
          data: (items) => PartnerHistoryView(items: items),
        );
      },
    );
  }
}

class PartnerHistoryView extends StatelessWidget {
  PartnerHistoryView({super.key, required this.items, DateTime? now})
    : now = now ?? DateTime.now();

  final List<PartnerHistoryItem> items;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final monthly = items
        .where((item) {
          final date = item.batch.completedAt ?? item.batch.createdAt;
          return date.year == now.year && date.month == now.month;
        })
        .toList(growable: false);
    final totalKg = monthly.fold<double>(
      0,
      (sum, item) => sum + item.batch.weightKg,
    );
    final recovered = monthly.fold<double>(
      0,
      (sum, item) => sum + item.batch.price,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const PartnerScreenTitle('RIWAYAT PENJEMPUTAN'),
        const SizedBox(height: 20),
        PartnerSectionCard(
          child: PartnerStatTile(
            label: 'TOTAL BULAN INI',
            value: _kg(totalKg),
            icon: Icons.scale_outlined,
            valueSize: 28,
          ),
        ),
        const SizedBox(height: 10),
        PartnerSectionCard(
          child: PartnerStatTile(
            label: 'JUMLAH PENJEMPUTAN',
            value: '${monthly.length}',
            icon: Icons.local_shipping_outlined,
            valueSize: 28,
          ),
        ),
        const SizedBox(height: 10),
        PartnerSectionCard(
          child: PartnerStatTile(
            label: 'PERKIRAAN HEMAT BIAYA',
            value: Fmt.rupiah(recovered),
            icon: Icons.savings_outlined,
            valueSize: 24,
          ),
        ),
        const SizedBox(height: 26),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 44),
            child: Text(
              'BELUM ADA PENJEMPUTAN SELESAI',
              textAlign: TextAlign.center,
              style: LestarType.display(
                size: 24,
                wght: 700,
                color: LestarTokens.muted,
              ),
            ),
          )
        else
          for (final item in items) ...[
            PartnerSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.storeName.toUpperCase(),
                    style: LestarType.display(
                      size: 22,
                      wght: 800,
                      color: LestarTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _kg(item.batch.weightKg),
                    style: LestarType.display(
                      size: 34,
                      wght: 800,
                      color: LestarTokens.emeraldDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Fmt.tanggalPanjang(item.batch.completedAt ?? item.batch.createdAt).toUpperCase()} · ${Fmt.jam(item.batch.completedAt ?? item.batch.createdAt)}',
                    style: LestarType.body(
                      size: 15,
                      wght: 600,
                      color: LestarTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

String _kg(double value) {
  final number = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$number KG';
}
