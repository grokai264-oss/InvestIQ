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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rec.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _actionColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _actionColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    rec.action,
                    style: TextStyle(
                      color: _actionColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('Score', rec.finalScore.toStringAsFixed(1), AppTheme.accent),
                _metric('Conv.', '${(rec.confidenceScore * 100).round()}%', AppTheme.textPrimary),
                _metric('Entry', rec.entryPrice != null ? '₹${rec.entryPrice!.toStringAsFixed(0)}' : '—', AppTheme.textPrimary),
                _metric(rec.timeframe, '', AppTheme.textMuted),
              ],
            ),
            if (rec.rationale.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                rec.rationale.first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String k, String v, Color vc) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            if (v.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: vc)),
            ],
          ],
        ),
      );
}
