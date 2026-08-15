import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import '../widgets/factor_radar.dart';
import '../widgets/execution_preflight.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final _api = ApiService();
  final _store = ProfileStore();
  Recommendation? _rec;
  bool _watched = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _api.getSingleRecommendation(symbol: widget.symbol);
      final w = await _store.isWatched(widget.symbol);
      if (!mounted) return;
      setState(() {
        _rec = r;
        _watched = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    await _store.toggleWatch(widget.symbol);
    final w = await _store.isWatched(widget.symbol);
    if (!mounted) return;
    setState(() => _watched = w);
  }

  Color _actionColor(String a) {
    if (a.contains('BUY')) return AppTheme.green;
    if (a == 'SELL') return AppTheme.red;
    return AppTheme.yellow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        actions: [
          IconButton(
            onPressed: _toggle,
            icon: Icon(_watched ? Icons.star : Icons.star_border, color: AppTheme.accent),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _rec == null
              ? const Center(
                  child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // Signal hero
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.cardDecoration(
                        borderColor: _actionColor(_rec!.action).withOpacity(0.45),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _actionColor(_rec!.action).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _rec!.action,
                                  style: TextStyle(
                                    color: _actionColor(_rec!.action),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _rec!.dataSource.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Score ${_rec!.finalScore.toStringAsFixed(1)}',
                            style: AppTheme.serifTitle.copyWith(fontSize: 32),
                          ),
                          Text(
                            'Confidence ${(_rec!.confidenceScore * 100).round()}% · ${_rec!.timeframe}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          if (_rec!.regimeFromRationale != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _rec!.regimeFromRationale!,
                              style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Levels
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        children: [
                          _row('Entry', _rec!.entryPrice?.toStringAsFixed(2)),
                          _row('Stop loss', _rec!.stopLoss?.toStringAsFixed(2)),
                          _row('Target', _rec!.targetPrice?.toStringAsFixed(2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FactorRadar(factors: _rec!.factors),
                    const SizedBox(height: 14),
                    // Factor bars
                    if (_rec!.factors.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Factor bars', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
                            const SizedBox(height: 12),
                            ..._rec!.factors.entries.map((e) {
                              final label = Recommendation.factorLabels[e.key] ??
                                  e.key.replaceAll('score_', '');
                              final v = e.value.clamp(0, 100);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        const Spacer(),
                                        Text(v.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: v / 100,
                                        minHeight: 6,
                                        backgroundColor: AppTheme.border,
                                        color: v >= 70
                                            ? AppTheme.green
                                            : (v <= 35 ? AppTheme.red : AppTheme.accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    ExecutionPreflight(rec: _rec!),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rationale', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
                          const SizedBox(height: 10),
                          ..._rec!.rationale.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('•  ', style: TextStyle(color: AppTheme.accent)),
                                  Expanded(
                                    child: Text(t, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _rec!.disclaimer,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LOB heatmap, OFI meter, Max Pain & live CoC require Level-2 / F&O feeds — not enabled in this build.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.35),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String k, String? v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ),
            Text(v ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
}
