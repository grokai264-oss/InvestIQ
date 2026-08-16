import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

/// Illustrative risk / reward panel — never an order ticket.
class ExecutionPreflight extends StatelessWidget {
  final Recommendation rec;
  const ExecutionPreflight({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final entry = rec.entryPrice ?? 0;
    final target = rec.targetPrice ?? entry;
    final stop = rec.stopLoss ?? entry;

    final upsidePct = entry > 0 ? ((target - entry) / entry) * 100.0 : 0.0;
    final downsidePct = entry > 0 ? ((entry - stop) / entry) * 100.0 : 0.0;
    final rr = downsidePct.abs() > 0.01 ? (upsidePct / downsidePct.abs()) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Risk & Scenario', style: AppTheme.title.copyWith(fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ILLUSTRATIVE',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Scenario analysis only — not an order, margin check, or trade recommendation. '
            'InvestIQ never places orders.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 14),
          _line('Downside to stop', '${downsidePct >= 0 ? '−' : ''}${downsidePct.abs().toStringAsFixed(1)}%'),
          _line('Potential upside', '+${upsidePct.toStringAsFixed(1)}%'),
          _line('Reward / risk', rr > 0 ? '${rr.toStringAsFixed(1)} : 1' : '—'),
          if (entry > 0) ...[
            const Divider(height: 20, color: AppTheme.border),
            _line('Reference entry', '₹${entry.toStringAsFixed(2)}'),
            if (rec.stopLoss != null) _line('Illustrative stop', '₹${stop.toStringAsFixed(2)}'),
            if (rec.targetPrice != null) _line('Illustrative target', '₹${target.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  Widget _line(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
