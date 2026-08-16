import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import '../widgets/factor_radar.dart';
import '../widgets/execution_preflight.dart';
import '../widgets/iq_primitives.dart';
import '../widgets/live_stock_chart.dart';

/// Flagship company research — Overview | Factors | Audit
class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _store = ProfileStore();
  Recommendation? _rec;
  QuoteTick? _quote;
  bool _watched = false;
  bool _loading = true;
  bool _chartLoading = true;
  List<FlSpot> _spots = const [];
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await _api.getSingleRecommendation(symbol: widget.symbol);
      final w = await _store.isWatched(widget.symbol);
      final quotes = await _api.getQuotes([widget.symbol]);
      if (!mounted) return;
      setState(() {
        _rec = r;
        _watched = w;
        _quote = quotes[widget.symbol.toUpperCase()];
        _loading = false;
      });
      // Load chart after overview so the desk paints quickly
      _loadChart('1M');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _chartLoading = false;
      });
    }
  }

  Future<void> _loadChart(String range) async {
    setState(() => _chartLoading = true);
    try {
      final points = await _api.getHistory(widget.symbol, range: range);
      final spots = <FlSpot>[];
      for (var i = 0; i < points.length; i++) {
        final c = points[i]['c'];
        if (c is num) spots.add(FlSpot(i.toDouble(), c.toDouble()));
      }
      if (!mounted) return;
      setState(() {
        _spots = spots;
        _chartLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _spots = const [];
        _chartLoading = false;
      });
    }
  }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    await _store.toggleWatch(widget.symbol);
    final w = await _store.isWatched(widget.symbol);
    if (!mounted) return;
    setState(() => _watched = w);
  }

  @override
  Widget build(BuildContext context) {
    final r = _rec;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        actions: [
          IconButton(
            onPressed: _toggle,
            icon: Icon(_watched ? Icons.star : Icons.star_border, color: AppTheme.accent),
          ),
        ],
        bottom: _loading || r == null
            ? null
            : TabBar(
                controller: _tabs,
                indicatorColor: AppTheme.accent,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Factors'),
                  Tab(text: 'Audit'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : r == null
              ? SoftStatus(
                  title: 'No research data',
                  body: 'Could not load ${widget.symbol}. Check backend or try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : TabBarView(
                  controller: _tabs,
                  children: [_overview(r), _factors(r), _audit(r)],
                ),
    );
  }

  Widget _overview(Recommendation r) {
    final live = _quote?.ltp;
    final change = _quote?.changePct;
    final price = live ?? r.entryPrice;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        ResearchBreadcrumb(items: [
          BreadcrumbItem('Market', onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
          BreadcrumbItem(widget.symbol),
        ]),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.symbol, style: AppTheme.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 4),
                  if (price != null)
                    Text('₹${price.toStringAsFixed(2)}', style: AppTheme.monoLarge)
                  else
                    Text('Price on request', style: AppTheme.body),
                  if (change != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: AppTheme.performance(change),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            FreshnessPill(
              state: live != null ? DataFreshness.live : DataFreshness.cached,
              label: live != null ? 'LIVE' : 'RESEARCH',
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProvenanceLine(
          source: r.dataSource.toUpperCase(),
          updatedAt: r.generatedAt.isNotEmpty ? r.generatedAt : null,
          note: 'Engine ${r.engineVersion}',
        ),
        const SizedBox(height: 16),
        LiveStockChart(
          symbol: widget.symbol,
          isLoading: _chartLoading,
          pricePoints: _spots,
          note: _spots.isEmpty && !_chartLoading
              ? 'No history returned for this range yet.'
              : null,
          onTimeframeChanged: (tf) => _loadChart(tf),
        ),
        const SizedBox(height: 24),
        ScoreAnatomy(
          score: r.finalScore,
          setup: AppTheme.setupLabel(r.finalScore),
          setupColor: AppTheme.setupColor(r.finalScore),
          confidence: r.confidenceScore,
        ),
        const SizedBox(height: 28),
        Text('FACTOR SNAPSHOT', style: AppTheme.sectionLabel),
        const SizedBox(height: 12),
        ..._topFactors(r).map((e) => FactorBar(
              label: e.$1,
              value: e.$2,
              color: e.$2 >= 60 ? AppTheme.green : (e.$2 < 40 ? AppTheme.red : AppTheme.accent),
            )),
        if (r.rationale.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('WHY THIS SCORE', style: AppTheme.sectionLabel),
          const SizedBox(height: 10),
          ...r.rationale.take(5).map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('·  ', style: TextStyle(color: AppTheme.accent)),
                    Expanded(child: Text(line, style: AppTheme.body)),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 20),
        ExecutionPreflight(rec: r),
      ],
    );
  }

  List<(String, double)> _topFactors(Recommendation r) {
    final entries = r.factors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((e) {
      final label = Recommendation.factorLabels[e.key] ?? e.key.replaceAll('score_', '');
      return (label, e.value);
    }).toList();
  }

  Widget _factors(Recommendation r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text('FACTOR PROFILE', style: AppTheme.sectionLabel),
        const SizedBox(height: 12),
        if (r.factors.isNotEmpty)
          SizedBox(height: 220, child: FactorRadar(factors: r.factors))
        else
          Text('No factor breakdown available.', style: AppTheme.body),
        const SizedBox(height: 24),
        Text('ALL FACTORS', style: AppTheme.sectionLabel),
        const SizedBox(height: 12),
        ...r.factors.entries.map((e) {
          final label = Recommendation.factorLabels[e.key] ?? e.key.replaceAll('score_', '');
          return FactorBar(label: label, value: e.value);
        }),
        if (r.regime != null) ...[
          const SizedBox(height: 20),
          Text('REGIME', style: AppTheme.sectionLabel),
          const SizedBox(height: 8),
          Text(r.regime!, style: AppTheme.body),
        ],
      ],
    );
  }

  Widget _audit(Recommendation r) {
    final order = Recommendation.auditOrder;
    final keys = <String>[
      ...order.where((k) => r.factors.containsKey(k)),
      ...r.factors.keys.where((k) => !order.contains(k)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text('SCORE ANATOMY', style: AppTheme.sectionLabel),
        const SizedBox(height: 14),
        ScoreAnatomy(
          score: r.finalScore,
          setup: AppTheme.setupLabel(r.finalScore),
          setupColor: AppTheme.setupColor(r.finalScore),
          confidence: r.confidenceScore,
        ),
        const SizedBox(height: 28),
        Text('CALCULATION AUDIT', style: AppTheme.sectionLabel),
        const SizedBox(height: 4),
        Text('Tap a factor to expand weight, contribution, and raw inputs', style: AppTheme.caption),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 20),
          child: Row(children: const [
            Expanded(flex: 3, child: Text('Factor', style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
            Expanded(child: Text('Score', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
            Expanded(child: Text('Wgt', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
            Expanded(child: Text('Contrib', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textMuted, fontSize: 11))),
          ]),
        ),
        if (keys.isEmpty)
          Text('No factor breakdown available for this symbol.', style: AppTheme.body)
        else
          ...keys.map((k) {
            final label = Recommendation.factorLabels[k] ?? k.replaceAll('score_', '');
            final score = r.factors[k] ?? 0.0;
            final wKey = Recommendation.weightKeyMap[k] ?? k.replaceAll('score_', '');
            final weight = r.weights[wKey] ?? r.weights[k] ?? 0.0;
            final contrib = r.contributions[k] ?? (score * weight);
            final stem = wKey.toLowerCase();
            final related = <String, dynamic>{};
            for (final e in r.rawInputs.entries) {
              if (e.key.toLowerCase().contains(stem) || stem.contains(e.key.toLowerCase().split('_').first)) {
                related[e.key] = e.value;
              }
            }
            return ExpandableAuditRow(
              label: label,
              score: score,
              weight: weight,
              contribution: contrib,
              rawInputs: related.isNotEmpty ? related : r.rawInputs,
              regimeNote: r.regime,
            );
          }),
        const Divider(color: AppTheme.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Expanded(flex: 3, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700))),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
            Expanded(
              child: Text(
                r.finalScore.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.accent),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Text('RAW INPUTS', style: AppTheme.sectionLabel),
        const SizedBox(height: 10),
        if (r.rawInputs.isEmpty)
          Text('Raw inputs not returned by engine for this symbol.', style: AppTheme.body)
        else
          ...r.rawInputs.entries.map((e) {
            final label = e.key.replaceAll('_', ' ');
            final val = e.value;
            final display = val is num
                ? (val is int ? val.toString() : (val as num).toStringAsFixed(2))
                : val.toString();
            final note = e.key.toLowerCase().contains('fii') ? ' (market-wide)' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text('$label$note', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                Text(display, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            );
          }),
        const SizedBox(height: 20),
        Text(
          'Engine ${r.engineVersion} · Confidence is score-distance, not calibrated hit-rate.\n'
          'LOB / OFI / Max Pain require Level-2 feeds — not in this build.',
          style: AppTheme.caption,
        ),
      ],
    );
  }
}
