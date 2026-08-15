import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

/// Compact analytical row for lists that still need a card (e.g. search).
/// Market Radar uses inline rows instead — no giant BUY badges.
class RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final VoidCallback? onTap;
  const RecommendationCard({super.key, required this.rec, this.onTap});

  String get _setup {
    if (rec.finalScore >= 75) return 'Strong';
    if (rec.finalScore >= 60) return 'Watch';
    if (rec.finalScore >= 40) return 'Neutral';
    return 'Weak';
  }

  Color get _setupColor {
    if (rec.finalScore >= 75) return AppTheme.green;
    if (rec.finalScore >= 60) return AppTheme.accent;
    if (rec.finalScore >= 40) return AppTheme.textMuted;
    return AppTheme.red;
  }

  @override
  Widget build(BuildContext context) {
    final factors = rec.factors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = factors.take(2).map((e) {
      return Recommendation.factorLabels[e.key] ?? e.key.replaceAll('score_', '');
    }).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rec.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _setupColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _setup,
                          style: TextStyle(
                            color: _setupColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${rec.finalScore.toStringAsFixed(1)}  ·  ${(rec.confidenceScore * 100).round()}% conf'
                    '${top.isNotEmpty ? '  ·  ${top.join('  ·  ')}' : ''}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
