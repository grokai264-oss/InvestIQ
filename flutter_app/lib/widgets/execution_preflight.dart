import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';

/// Read-only SEBI/STT awareness panel — never executes trades.
class ExecutionPreflight extends StatelessWidget {
  final Recommendation rec;
  const ExecutionPreflight({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final entry = rec.entryPrice ?? 0;
    final target = rec.targetPrice ?? entry;
    final stop = rec.stopLoss ?? entry;
    // Illustrative: 1 lot notional = 1 share for equity display
    final notional = entry;
    final marginPct = 0.20; // peak margin style 5x max → 20% upfront illustrative
    final marginReq = notional * marginPct;
    final sttSell = target * 0.00025; // 0.025% sell-side cash equity intraday illustrative
    final otherFees = notional * 0.0003;
    final grossIfTarget = target - entry;
    final netIfTarget = grossIfTarget - sttSell - otherFees;
    final risk = entry - stop;

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
          Row(
            children: [
              Text('Pre-flight (illustrative)', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('READ-ONLY', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Educational cost model only. App never places orders or checks live margins with your broker.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 14),
          _line('Illustrative upfront margin (~20%)', '₹${marginReq.toStringAsFixed(2)}'),
          _line('Risk to stop (1 share)', '₹${risk.toStringAsFixed(2)}'),
          _line('Gross to target (1 share)', '₹${grossIfTarget.toStringAsFixed(2)}'),
          _line('Est. STT + fees (sell side)', '₹${(sttSell + otherFees).toStringAsFixed(2)}'),
          const Divider(height: 20, color: AppTheme.border),
          _line('Est. net if target hit', '₹${netIfTarget.toStringAsFixed(2)}', bold: true),
          if (netIfTarget < 0 && rec.isBuy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Edge may be thin after friction — treat signal as analytical only.',
                style: TextStyle(color: AppTheme.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
