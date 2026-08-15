import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/portfolio.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
    setState(() { _data = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('Portfolio', style: AppTheme.serifTitle.copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              const Text('Read-only holdings · Never places orders', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.accent)))
              else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(_data!.linked ? Icons.link : Icons.link_off, size: 18, color: _data!.linked ? AppTheme.green : AppTheme.yellow),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_data!.linked ? 'Kotak session linked' : 'Kotak not linked on server', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                    ]),
                    const SizedBox(height: 10),
                    Text(_data!.message, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
                    if (_data!.linked && _data!.holdings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(fmt.format(_data!.totalValue), style: AppTheme.serifTitle.copyWith(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        '${_data!.totalPnl >= 0 ? '+' : ''}${fmt.format(_data!.totalPnl)}  (${_data!.totalPnlPct.toStringAsFixed(2)}%)',
                        style: TextStyle(color: _data!.totalPnl >= 0 ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                if (_data!.holdings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: const Text(
                      'When Kotak Neo is linked on the backend, your CNC holdings appear here.\n\nUntil then: rankings on Desk still work. No buy/sell is ever sent.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 13),
                    ),
                  )
                else
                  ..._data!.holdings.map((h) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.cardDecoration(),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Qty ${h.quantity.toStringAsFixed(0)} · Avg ${h.avgPrice.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(h.ltp.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${h.pnl >= 0 ? '+' : ''}${h.pnl.toStringAsFixed(0)}', style: TextStyle(color: h.pnl >= 0 ? AppTheme.green : AppTheme.red, fontSize: 12)),
                          ]),
                        ]),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
