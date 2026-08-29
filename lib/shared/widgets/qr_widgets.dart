import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/tokens.dart';

/// QR yang ditunjukkan konsumen ke merchant.
///
/// **Tanda tangan dikunci.**
class QrDisplay extends StatelessWidget {
  const QrDisplay({
    super.key,
    required this.data,
    this.size = 240,
    this.caption,
  });

  final String data;
  final double size;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Latar QR selalu putih apa pun temanya — pemindai butuh kontras
            // penuh, dan tema merchant berlatar hitam.
            color: Colors.white,
            borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
          ),
          child: QrImageView(
            data: data,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: LestarTokens.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: LestarTokens.ink,
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 12),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: LestarType.label(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Pemindai QR untuk merchant.
///
/// [onDetect] dipanggil **satu kali** per pemindaian — pemindai mengunci
/// dirinya setelah kode pertama terbaca supaya satu QR tidak memicu klaim
/// berkali-kali dalam sedetik.
///
/// **Tanda tangan dikunci.**
class QrScanner extends StatefulWidget {
  const QrScanner({super.key, required this.onDetect, this.hint});

  final void Function(String kode) onDetect;
  final String? hint;

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final _controller = MobileScannerController();
  bool _terkunci = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tangani(BarcodeCapture capture) {
    if (_terkunci) return;
    final kode = capture.barcodes.firstOrNull?.rawValue;
    if (kode == null || kode.isEmpty) return;
    setState(() => _terkunci = true);
    widget.onDetect(kode);
  }

  /// Dipanggil layar pemanggil setelah menampilkan hasil, supaya pemindai
  /// siap membaca QR berikutnya.
  void bukaKunci() => setState(() => _terkunci = false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _tangani),
        // Bingkai bidik.
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: LestarTokens.emerald, width: 3),
              borderRadius: BorderRadius.circular(LestarTokens.radiusKartu),
            ),
          ),
        ),
        if (widget.hint != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              widget.hint!,
              textAlign: TextAlign.center,
              style: LestarType.isi(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
