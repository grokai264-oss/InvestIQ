import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

/// Spider chart of multi-factor exposures (0–100).
class FactorRadar extends StatelessWidget {
  final Map<String, double> factors;
  const FactorRadar({super.key, required this.factors});

  static const _order = [
    'score_momentum',
    'score_rsi',
    'score_vwap',
    'score_ema',
    'score_rvol',
    'score_low_vol',
    'score_value',
    'score_delivery',
    'score_fii',
    'score_macd',
  ];

  @override
  Widget build(BuildContext context) {
    final keys = _order.where((k) => factors.containsKey(k)).toList();
    if (keys.length < 3) {
      return const SizedBox.shrink();
    }
    final values = keys.map((k) => (factors[k] ?? 0).clamp(0, 100).toDouble()).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Factor exposure', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Multi-factor profile (0–100). Shape shifts with India VIX regime.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                    fillColor: AppTheme.accent.withOpacity(0.25),
                    borderColor: AppTheme.accent,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: AppTheme.border),
                tickBorderData: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                gridBorderData: BorderSide(color: AppTheme.border.withOpacity(0.4)),
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                tickCount: 4,
                titlePositionPercentageOffset: 0.18,
                getTitle: (index, angle) {
                  final key = keys[index % keys.length];
                  final label = Recommendation.factorLabels[key] ?? key.replaceAll('score_', '');
                  return RadarChartTitle(
                    text: label,
                    angle: 0,
                  );
                },
                titleTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
