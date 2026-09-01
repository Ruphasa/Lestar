import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/supabase/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/merchant_esg_controller.dart';
import 'widgets/merchant_esg_widgets.dart';

class MerchantEsgScreen extends ConsumerWidget {
  const MerchantEsgScreen({super.key});

  Future<void> _exportPdf(
    BuildContext context,
    Merchant merchant,
    EsgReport report,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pdfContext) => [
          pw.Text(
            'Lestar · Laporan Dampak',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            merchant.storeName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${Fmt.tanggal(report.periodStart)} – '
            '${Fmt.tanggal(report.periodEnd)}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfRow('Makanan diselamatkan', Fmt.kg(report.totalWeightKg)),
              _pdfRow('CO2eq tidak dilepaskan', Fmt.kg(report.totalCo2Kg)),
              _pdfRow(
                'Nilai dipulihkan',
                Fmt.rupiah(report.totalRevenueRecovered),
              ),
              _pdfRow(
                'Porsi sampai ke konsumen',
                Fmt.angka(report.mealsRescued),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Narasi green branding',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(report.narrative ?? 'Belum ada narasi untuk periode ini.'),
          pw.SizedBox(height: 28),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'Angka dalam laporan ini berasal dari buku besar esg_events Lestar.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        name:
            'Lestar-${merchant.storeName}-${report.periodStart.year}-'
            '${report.periodStart.month}.pdf',
        onLayout: (_) => document.save(),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pesanError(error))));
    }
  }

  pw.TableRow _pdfRow(String label, String value) => pw.TableRow(
    children: [
      pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text(label)),
      pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(currentMerchantProvider);
    return merchantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        title: 'Laporan belum dapat dimuat',
        message: pesanError(error),
      ),
      data: (merchant) {
        if (merchant == null) {
          return const EmptyState(title: 'Akun merchant tidak ditemukan');
        }
        final reportAsync = ref.watch(merchantEsgProvider(merchant.id));
        return reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Laporan belum dapat dibuat',
            message: pesanError(error),
            icon: Icons.eco_outlined,
            action: FilledButton.icon(
              onPressed: () => ref.invalidate(merchantEsgProvider(merchant.id)),
              style: FilledButton.styleFrom(
                backgroundColor: LestarTokens.forest,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ),
          data: (data) => MerchantEsgReportView(
            data: data,
            onExport: () => _exportPdf(context, merchant, data.report),
          ),
        );
      },
    );
  }
}
