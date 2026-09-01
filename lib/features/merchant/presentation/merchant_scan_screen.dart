import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dark_glass.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/providers.dart';
import '../../../shared/widgets/widgets.dart';

class MerchantScanScreen extends ConsumerStatefulWidget {
  const MerchantScanScreen({super.key});

  @override
  ConsumerState<MerchantScanScreen> createState() => _MerchantScanScreenState();
}

class _MerchantScanScreenState extends ConsumerState<MerchantScanScreen> {
  bool _busy = false;
  Order? _claimed;
  String? _error;
  int _scannerGeneration = 0;

  Future<void> _claim(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(orderRepositoryProvider).claimByQr(code);
      if (!mounted) return;
      setState(() => _claimed = order);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = pesanError(error);
        _scannerGeneration++;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manualCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkGlassTheme.card,
        title: Text(
          'Masukkan kode manual',
          style: LestarType.judulKartu(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Kode QR pesanan',
            prefixIcon: Icon(Icons.password),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Klaim'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code != null) await _claim(code);
  }

  void _scanAgain() => setState(() {
    _claimed = null;
    _error = null;
    _scannerGeneration++;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DarkGlassTheme.background,
    appBar: AppBar(title: const Text('Scan QR Pesanan')),
    body: SafeArea(
      top: false,
      child: _claimed == null ? _scannerView() : _successView(_claimed!),
    ),
  );

  Widget _scannerView() => Column(
    children: [
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            QrScanner(
              key: ValueKey(_scannerGeneration),
              onDetect: _claim,
              hint: 'Arahkan kamera ke QR konsumen',
            ),
            if (_busy)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.54),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(color: DarkGlassTheme.surfaceDeep),
        child: Column(
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LestarTokens.orange.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: LestarType.label(color: LestarTokens.orange),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _manualCode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Masukkan kode manual'),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _successView(Order order) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: DarkGlassCard(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: DarkGlassTheme.badge,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: LestarTokens.emerald,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pesanan berhasil diklaim',
              textAlign: TextAlign.center,
              style: LestarType.judulKartu(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Status berubah menjadi CLAIMED dan peristiwa ESG '
              'dicatat otomatis.',
              textAlign: TextAlign.center,
              style: LestarType.isi(
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DarkGlassTheme.tile,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Pesanan',
                    value:
                        '#${order.id.substring(0, order.id.length.clamp(0, 8))}',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Total', value: Fmt.rupiah(order.total)),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Diklaim',
                    value: Fmt.jam(order.claimedAt ?? DateTime.now()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _scanAgain,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: LestarTokens.emeraldDeep,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  'Pindai pesanan berikutnya',
                  style: LestarType.display(size: 18, wght: 700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: LestarType.label(color: Colors.white.withValues(alpha: 0.44)),
      ),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: LestarType.label(color: Colors.white),
        ),
      ),
    ],
  );
}
