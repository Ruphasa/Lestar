import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/consumer_providers.dart';
import 'widgets/consumer_widgets.dart';

class ConsumerQrPresentation {
  const ConsumerQrPresentation({
    required this.order,
    required this.storeName,
    required this.storeAddress,
  });

  final Order order;
  final String storeName;
  final String storeAddress;
}

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key, this.initialData});

  final ConsumerQrPresentation? initialData;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maximize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maximize();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _restore();
    }
  }

  Future<void> _maximize() async {
    try {
      await ref.read(consumerScreenBrightnessProvider).maximize();
    } catch (_) {
      // QR tetap berguna jika perangkat menolak override brightness.
    }
  }

  Future<void> _restore() async {
    try {
      await ref.read(consumerScreenBrightnessProvider).restore();
    } catch (_) {
      // Tidak ada aksi lanjutan saat activity sudah ditutup.
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialData;
    return Scaffold(
      appBar: AppBar(title: const Text('QR Pengambilan')),
      body: ConsumerBackdrop(
        child: initial != null
            ? _QrBody(data: initial)
            : ref
                  .watch(activeConsumerQrProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => ConsumerErrorState(
                      message: pesanError(error),
                      onRetry: () => ref.invalidate(activeConsumerQrProvider),
                    ),
                    data: (active) {
                      if (active == null) {
                        return const EmptyState(
                          icon: Icons.qr_code_2,
                          title: 'Belum ada QR aktif',
                          message:
                              'Pesan dan bayar flash deal untuk menerbitkan QR pengambilan.',
                        );
                      }
                      return _QrBody(
                        data: ConsumerQrPresentation(
                          order: active.order,
                          storeName: active.merchant.storeName,
                          storeAddress: active.merchant.storeAddress,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _QrBody extends StatelessWidget {
  const _QrBody({required this.data});

  final ConsumerQrPresentation data;

  @override
  Widget build(BuildContext context) {
    final token = data.order.qrToken;
    if (token == null || token.isEmpty) {
      return const EmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'QR belum diterbitkan',
        message: 'Selesaikan pembayaran terlebih dahulu.',
      );
    }
    final shortOrderId = data.order.id.length <= 8
        ? data.order.id
        : data.order.id.substring(0, 8);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Tunjukkan ke kasir',
          textAlign: TextAlign.center,
          style: LestarType.judulLayar(color: LestarTokens.forest),
        ),
        const SizedBox(height: 6),
        Text(
          'Kecerahan layar dinaikkan otomatis agar mudah dipindai.',
          textAlign: TextAlign.center,
          style: LestarType.label(color: LestarTokens.muted),
        ),
        const SizedBox(height: 20),
        Center(
          child: QrDisplay(
            data: token,
            size: (MediaQuery.sizeOf(context).width.clamp(280.0, 340.0) - 64)
                .toDouble(),
            caption: 'Kode pengambilan $shortOrderId',
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: CountdownChip(
            expiresAt: data.order.qrExpiresAt ?? DateTime.now(),
          ),
        ),
        const SizedBox(height: 22),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.storeName,
                style: LestarType.judulKartu(color: LestarTokens.forest),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: LestarTokens.emeraldDeep,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      data.storeAddress,
                      style: LestarType.label(color: LestarTokens.muted),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              Text('Item', style: LestarType.label(color: LestarTokens.muted)),
              const SizedBox(height: 9),
              for (final item in data.order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.qty}× ${item.nameSnapshot}',
                          style: LestarType.isi(),
                        ),
                      ),
                      Text(
                        Fmt.rupiah(item.lineTotal),
                        style: LestarType.label(color: LestarTokens.orangeText),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: LestarTokens.emeraldTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.eco_outlined, color: LestarTokens.emeraldDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pesanan ini membantu menyelamatkan makanan dari terbuang.',
                  style: LestarType.label(color: LestarTokens.forest),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
