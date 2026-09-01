import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme/dark_glass.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

String modelAccuracyLabel() =>
    '${(LestarConstants.modelAkurasi * 100).round()}% · '
    '${LestarConstants.modelDasarUji}';

class MerchantForecastCard extends StatelessWidget {
  const MerchantForecastCard({
    super.key,
    required this.forecast,
    required this.history,
    required this.applied,
    required this.onApply,
  });

  final Forecast forecast;
  final List<SalesHistory> history;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final points = history.take(7).toList().reversed.toList();
    final currentPlan = points.isEmpty
        ? forecast.recommendedProduction.toDouble()
        : points.last.portionsSold +
              (points.last.surplusKg / LestarConstants.beratPorsiDefaultKg);
    final difference = currentPlan - forecast.recommendedProduction;

    return DarkGlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ForecastHeader(label: modelAccuracyLabel()),
          const SizedBox(height: 24),
          Text(
            'Persiapan besok · prediksi permintaan',
            style: LestarType.body(
              size: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  child: Text(
                    '${forecast.demandX.round()} kg',
                    key: ValueKey(
                      '${forecast.source.wire}-${forecast.demandX}',
                    ),
                    style: LestarType.angkaBesar(color: Colors.white),
                  ),
                ),
              ),
              _WarnChip(difference: difference),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 190, child: _DemandChart(history: points)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DarkGlassTheme.narrative,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              forecast.narrative ??
                  'Rekomendasi produksi dihitung dari pola penjualan terbaru.',
              style: LestarType.isi(
                color: Colors.white.withValues(alpha: 0.76),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: applied ? null : onApply,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: LestarTokens.emeraldDeep,
                disabledBackgroundColor: DarkGlassTheme.badge,
                foregroundColor: Colors.white,
                disabledForegroundColor: LestarTokens.emerald,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(applied ? Icons.check_circle : Icons.north_east),
              label: Text(
                applied
                    ? 'Rencana ${forecast.recommendedProduction} diterapkan'
                    : 'Terapkan rekomendasi produksi',
                style: LestarType.display(size: 18, wght: 700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SourceBadge(source: forecast.source, compact: true),
          ),
        ],
      ),
    );
  }
}

class _ForecastHeader extends StatelessWidget {
  const _ForecastHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DarkGlassTheme.badge,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.trending_up,
          color: LestarTokens.emerald,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Stock Forecast · Besok',
          style: LestarType.judulKartu(color: Colors.white),
        ),
      ),
      Container(
        constraints: const BoxConstraints(maxWidth: 128),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: DarkGlassTheme.badge,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: LestarType.body(
            size: 11,
            wght: 600,
            color: LestarTokens.emerald,
          ),
        ),
      ),
    ],
  );
}

class _WarnChip extends StatelessWidget {
  const _WarnChip({required this.difference});

  final double difference;

  @override
  Widget build(BuildContext context) {
    final rounded = difference.abs().round();
    final sign = difference >= 0 ? '−' : '+';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: LestarTokens.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: LestarTokens.orange,
          ),
          const SizedBox(width: 5),
          Text(
            '$sign$rounded kg vs plan',
            style: LestarType.body(
              size: 12,
              wght: 600,
              color: LestarTokens.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandChart extends StatelessWidget {
  const _DemandChart({required this.history});

  final List<SalesHistory> history;

  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'Belum ada riwayat untuk chart.',
          style: LestarType.label(color: Colors.white.withValues(alpha: 0.38)),
        ),
      );
    }

    final demand = <FlSpot>[];
    final plan = <FlSpot>[];
    var highest = 1.0;
    for (var i = 0; i < history.length; i++) {
      final row = history[i];
      final production =
          row.portionsSold +
          (row.surplusKg / LestarConstants.beratPorsiDefaultKg);
      demand.add(FlSpot(i.toDouble(), row.portionsSold.toDouble()));
      plan.add(FlSpot(i.toDouble(), production));
      highest = math.max(
        highest,
        math.max(row.portionsSold.toDouble(), production),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, history.length - 1).toDouble(),
        minY: 0,
        maxY: highest * 1.18,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: math.max(1, highest / 3),
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _days[history[index].dayOfWeek.clamp(0, 6)],
                    style: LestarType.caption(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: demand,
            isCurved: true,
            curveSmoothness: 0.25,
            color: LestarTokens.emerald,
            barWidth: 3.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: LestarTokens.emerald.withValues(alpha: 0.06),
            ),
          ),
          LineChartBarData(
            spots: plan,
            isCurved: true,
            curveSmoothness: 0.25,
            color: LestarTokens.orange,
            barWidth: 1.5,
            dashArray: [6, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
