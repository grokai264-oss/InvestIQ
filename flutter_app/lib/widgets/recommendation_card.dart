import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final VoidCallback? onTap;
  const RecommendationCard({super.key, required this.rec, this.onTap});

  Color get _actionColor {
    if (rec.action.contains('BUY')) return AppTheme.green;
    if (rec.action == 'SELL') return AppTheme.red;
    return AppTheme.yellow;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(rec.symbol, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _actionColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(rec.action, style: TextStyle(color: _actionColor, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _m('Score', rec.finalScore.toStringAsFixed(1)),
            _m('Confidence', '${(rec.confidenceScore * 100).round()}%'),
            _m('Entry', rec.entryPrice?.toStringAsFixed(1) ?? '—'),
          ]),
          if (rec.rationale.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(rec.rationale.first, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35)),
          ],
        ]),
      ),
    );
  }

  Widget _m(String k, String v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      );
}
