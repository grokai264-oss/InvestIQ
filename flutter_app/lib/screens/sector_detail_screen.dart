import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sector_treemap.dart';
import 'stock_detail_screen.dart';

/// Sector intelligence: Market → Sector → Company.
class SectorDetailScreen extends StatelessWidget {
  final SectorNode sector;
  const SectorDetailScreen({super.key, required this.sector});

  @override
  Widget build(BuildContext context) {
    final up = sector.changePct >= 0;
    final changeColor = up ? AppTheme.green : AppTheme.red;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(sector.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(sector.name, style: AppTheme.display.copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(sector.share * 100).toStringAsFixed(1)}% of NIFTY 500',
                style: AppTheme.body,
              ),
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${up ? '+' : ''}${sector.changePct.toStringAsFixed(2)}% today',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Structural share · live market-cap aggregation pending NIFTY 500 pipeline',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 28),
          Text('SECTOR PULSE', style: AppTheme.sectionLabel),
          const SizedBox(height: 12),
          _pulseRow('Momentum', _pulseFromChange(sector.changePct)),
          _pulseRow('Breadth', 0.72),
          _pulseRow('Relative strength', 0.65 + sector.changePct / 20),
          _pulseRow('Volume', 0.68),
          const SizedBox(height: 28),
          Text('WHO IS DRIVING IT', style: AppTheme.sectionLabel),
          const SizedBox(height: 4),
          Text(
            'Tap a name for company research + calculation audit',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ...sector.topSymbols.asMap().entries.map((e) {
            final i = e.key;
            final sym = e.value;
            final strength = 1.0 - (i * 0.12);
            return _driverRow(context, rank: i + 1, symbol: sym, strength: strength);
          }),
          const SizedBox(height: 28),
          Text('RESEARCH PATH', style: AppTheme.sectionLabel),
          const SizedBox(height: 10),
          Text(
            'Market  →  ${sector.short}  →  company  →  calculation audit',
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'InvestIQ scores are multi-factor with VIX regime weights. '
            'FII/DII flows are market-wide, never stock-specific.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  double _pulseFromChange(double ch) {
    return (0.55 + ch / 4).clamp(0.25, 0.95);
  }

  Widget _pulseRow(String label, double value) {
    final v = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppTheme.borderSubtle,
                color: AppTheme.accent.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              (v * 100).round().toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverRow(BuildContext context, {required int rank, required String symbol, required double strength}) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: symbol)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rank.toString().padLeft(2, '0'),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                symbol,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2),
              ),
            ),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: strength.clamp(0.15, 1.0),
                  minHeight: 5,
                  backgroundColor: AppTheme.borderSubtle,
                  color: AppTheme.accent.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
