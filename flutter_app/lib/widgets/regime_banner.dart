import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Top ribbon: India VIX regime + hint on weight shift.
class RegimeBanner extends StatelessWidget {
  final List<Map<String, dynamic>> indices;
  final String? regimeHint;

  const RegimeBanner({super.key, required this.indices, this.regimeHint});

  @override
  Widget build(BuildContext context) {
    double? vix;
    for (final i in indices) {
      if ((i['symbol'] ?? '').toString().toUpperCase().contains('VIX')) {
        vix = (i['last'] as num?)?.toDouble();
      }
    }
    final regime = vix == null
        ? 'unknown'
        : (vix < 15 ? 'low' : (vix > 22 ? 'high' : 'mid'));
    final color = regime == 'low'
        ? AppTheme.green
        : (regime == 'high' ? AppTheme.red : AppTheme.accent);
    final weightHint = regime == 'low'
        ? 'Weights favor Momentum · Volume · RSI'
        : (regime == 'high'
            ? 'Weights favor Low-Vol · VWAP · Value'
            : 'Balanced multi-factor weights');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), AppTheme.card],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VIX ${vix?.toStringAsFixed(1) ?? '—'}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regime: ${regime.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  regimeHint ?? weightHint,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
