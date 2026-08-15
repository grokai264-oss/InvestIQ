import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';

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
      setState(() { _rec = r; _watched = w; _loading = false; });
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
              ? const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(_rec!.action, style: TextStyle(color: _rec!.isBuy ? AppTheme.green : AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
                    const SizedBox(height: 8),
                    Text('Score ${_rec!.finalScore.toStringAsFixed(1)} · Confidence ${(_rec!.confidenceScore * 100).round()}%', style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    _row('Entry', _rec!.entryPrice?.toStringAsFixed(2)),
                    _row('Stop loss', _rec!.stopLoss?.toStringAsFixed(2)),
                    _row('Target', _rec!.targetPrice?.toStringAsFixed(2)),
                    const SizedBox(height: 16),
                    Text('Rationale', style: AppTheme.serifSmall),
                    const SizedBox(height: 8),
                    ..._rec!.rationale.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $t', style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
                        )),
                    const SizedBox(height: 20),
                    Text(_rec!.disclaimer, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4)),
                  ],
                ),
    );
  }

  Widget _row(String k, String? v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 100, child: Text(k, style: const TextStyle(color: AppTheme.textSecondary))),
          Text(v ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
