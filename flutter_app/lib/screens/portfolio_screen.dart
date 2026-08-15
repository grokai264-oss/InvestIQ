import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/portfolio.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// Portfolio intelligence — holdings + concentration + research link.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _api = ApiService();
  PortfolioSummary? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _api.getPortfolio();
    if (!mounted) return;
    setState(() {
      _data = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final d = _data;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text('Portfolio', style: AppTheme.display.copyWith(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                d?.linked == true
                    ? 'Read-only · Kotak linked'
                    : 'Read-only view · link Kotak on server for holdings',
                style: AppTheme.body,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                )
              else if (d == null || !d.linked)
                _unlinked(d?.message ?? 'Not linked')
              else ...[
                Text(
                  fmt.format(d.totalValue),
                  style: AppTheme.monoLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 6),
                Text(
                  '${d.totalPnl >= 0 ? '+' : ''}${fmt.format(d.totalPnl)}  ·  '
                  '${d.totalPnlPct >= 0 ? '+' : ''}${d.totalPnlPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: d.totalPnl >= 0 ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                Text('HOLDINGS (${d.holdings.length})', style: AppTheme.sectionLabel),
                const SizedBox(height: 12),
                if (d.holdings.isEmpty)
                  Text('No CNC holdings in linked session.', style: AppTheme.body)
                else
                  ...d.holdings.map((h) => _holdingTile(h, fmt)),
                const SizedBox(height: 28),
                Text('PORTFOLIO INTELLIGENCE', style: AppTheme.sectionLabel),
                const SizedBox(height: 12),
                _intelRow(
                  'Concentration',
                  d.holdings.length <= 1
                      ? 'High — ${d.holdings.isEmpty ? 'none' : d.holdings.first.symbol}'
                      : '${d.holdings.length} names',
                ),
                _intelRow(
                  'InvestIQ coverage',
                  d.holdings.isEmpty
                      ? '—'
                      : 'Research available for ${d.holdings.map((e) => e.symbol).join(', ')}',
                ),
                _intelRow(
                  'Risk note',
                  d.holdings.length <= 1
                      ? 'Single-name exposure — diversify if thesis changes'
                      : 'Multi-name book',
                ),
                const SizedBox(height: 16),
                Text(
                  'Holdings are read-only from Kotak. InvestIQ never places orders.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _unlinked(String msg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Broker not linked',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(msg, style: AppTheme.body),
          const SizedBox(height: 12),
          Text(
            'Set Kotak env vars on Render to load holdings. '
            'The app remains analytical-only either way.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _holdingTile(Holding h, NumberFormat fmt) {
    final up = h.pnl >= 0;
    final invested = h.avgPrice * h.quantity;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: h.symbol)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  h.symbol,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  h.ltp.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Qty ${h.quantity.toStringAsFixed(0)}  ·  Avg ${h.avgPrice.toStringAsFixed(2)}  ·  '
              'Invested ${fmt.format(invested)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${up ? '+' : ''}${fmt.format(h.pnl)}  (${up ? '+' : ''}${h.pnlPct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: up ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Research →',
                  style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _intelRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
