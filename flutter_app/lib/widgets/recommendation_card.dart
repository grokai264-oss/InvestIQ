import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final VoidCallback? onTap;

  const RecommendationCard({super.key, required this.rec, this.onTap});

  Color get _actionColor {
    switch (rec.action) {
      case 'STRONG BUY':
      case 'BUY':
        return AppTheme.green;
      case 'SELL':
        return AppTheme.red;
      default:
        return AppTheme.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rec.symbol,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _actionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rec.action,
                    style: TextStyle(
                      color: _actionColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('Score', rec.finalScore.toStringAsFixed(1)),
                _metric('Confidence', '${(rec.confidenceScore * 100).toStringAsFixed(0)}%'),
                if (rec.entryPrice != null)
                  _metric('Entry', rec.entryPrice!.toStringAsFixed(1)),
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
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
