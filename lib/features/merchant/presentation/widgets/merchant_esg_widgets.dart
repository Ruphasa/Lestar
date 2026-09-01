import 'package:flutter/material.dart';

import '../../../../core/theme/dark_glass.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/merchant_esg_controller.dart';

class MerchantEsgReportView extends StatelessWidget {
  const MerchantEsgReportView({
    super.key,
    required this.data,
    required this.onExport,
  });

  final MerchantEsgData data;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final report = data.report;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Dampak',
                    style: LestarType.judulLayar(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${Fmt.tanggal(report.periodStart)} – '
                    '${Fmt.tanggal(report.periodEnd)}',
                    style: LestarType.isi(
                      color: Colors.white.withValues(alpha: 0.46),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: DarkGlassTheme.badge,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.fromCache ? 'Laporan tersimpan' : 'Baru dibuat',
                style: LestarType.body(
                  size: 11,
                  wght: 600,
                  color: LestarTokens.emerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _ImpactTile(
                    icon: Icons.restaurant_outlined,
                    value: Fmt.kg(report.totalWeightKg),
                    label: 'Makanan diselamatkan',
                    color: LestarTokens.emerald,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ImpactTile(
                    icon: Icons.cloud_outlined,
                    value: Fmt.kg(report.totalCo2Kg),
                    label: 'CO₂eq tidak dilepaskan',
                    color: LestarTokens.emerald,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ImpactTile(
                    icon: Icons.payments_outlined,
                    value: Fmt.rupiah(report.totalRevenueRecovered),
                    label: 'Nilai dipulihkan',
                    color: LestarTokens.orange,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ImpactTile(
                    icon: Icons.people_alt_outlined,
                    value: Fmt.angka(report.mealsRescued),
                    label: 'Porsi sampai ke konsumen',
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        DarkGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: LestarTokens.emerald,
                  ),
                  const SizedBox(width: 9),
                  // Expanded wajib: tanpa ini Row meluber 128 px di lebar HP
                  // 400 dp. Tidak terlihat di surface test 800 px bawaan.
                  Expanded(
                    child: Text(
                      'Narasi green branding',
                      style: LestarType.judulKartu(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                report.narrative ??
                    'Belum ada narasi karena periode ini belum memiliki data.',
                style: LestarType.isi(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DarkGlassTheme.narrative,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: LestarTokens.emerald,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        data.eventCount > 0
                            ? 'Semua angka diringkas dari ${data.eventCount} '
                                  'baris esg_events pada periode ini.'
                            : 'Angka berasal dari laporan tersimpan; jejak '
                                  'esg_events belum dapat dimuat saat ini.',
                        style: LestarType.body(
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!data.saved) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LestarTokens.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'Laporan tampil, tetapi belum tersimpan ke cache. '
              'Periksa koneksi sebelum menutup aplikasi.',
              style: LestarType.label(color: LestarTokens.orange),
            ),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onExport,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ),
      ],
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 142),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DarkGlassTheme.tile,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: color),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: LestarType.display(size: 25, wght: 700, color: color),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LestarType.body(
            size: 12,
            color: Colors.white.withValues(alpha: 0.46),
          ),
        ),
      ],
    ),
  );
}
