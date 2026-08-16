import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';
import 'search_screen.dart';
import 'stock_detail_screen.dart';
import 'superstar_investors_screen.dart';

/// Market home — Pulse → Movers → Radar
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _api = ApiService();
  List<Recommendation> _recs = [];
  List<Map<String, dynamic>> _indices = [];
  List<Map<String, dynamic>> _gainers = [];
  List<Map<String, dynamic>> _losers = [];
  String _timeframe = 'daily';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recs = await _api.getTopRecommendations(timeframe: _timeframe, limit: 12);
      final idx = await _api.getIndices();
      final gainers = await _api.getMovers(kind: 'gainers', limit: 5);
      final losers = await _api.getMovers(kind: 'losers', limit: 5);
      if (!mounted) return;
      setState(() {
        _recs = recs;
        _indices = idx;
        _gainers = gainers;
        _losers = losers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _idx(String key) {
    for (final i in _indices) {
      final s = (i['symbol'] ?? i['name'] ?? '').toString().toUpperCase();
      if (s.contains(key.toUpperCase())) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _pulseStrip()),
              if (!_loading && (_gainers.isNotEmpty || _losers.isNotEmpty))
                SliverToBoxAdapter(child: _moversSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text('InvestIQ Radar', style: AppTheme.sectionLabel),
                      const Spacer(),
                      _tfChip('daily'),
                      _tfChip('monthly'),
                      _tfChip('yearly'),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerLoading(itemCount: 4),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(child: _errorBox())
              else if (_recs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No rankings yet.', style: AppTheme.body),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _radarRow(_recs[i]),
                    childCount: _recs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text('Market', style: AppTheme.display.copyWith(fontSize: 26)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseStrip() {
    final nifty = _idx('NIFTY');
    final bank = _idx('BANK');
    final vix = _idx('VIX');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(child: _pulseCell('Nifty 50', nifty)),
            Container(width: 1, height: 36, color: AppTheme.borderSubtle),
            Expanded(child: _pulseCell('Bank Nifty', bank)),
            Container(width: 1, height: 36, color: AppTheme.borderSubtle),
            Expanded(child: _vixCell(vix)),
          ],
        ),
      ),
    );
  }

  Widget _pulseCell(String label, Map<String, dynamic>? d) {
    final ch = (d?['change_pct'] as num?)?.toDouble();
    final up = (ch ?? 0) >= 0;
    final ltp = (d?['ltp'] as num?)?.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(ltp != null ? ltp.toStringAsFixed(0) : '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          if (ch != null)
            Text('${up ? '+' : ''}${ch.toStringAsFixed(2)}%', style: TextStyle(color: up ? AppTheme.green : AppTheme.red, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _vixCell(Map<String, dynamic>? d) {
    final ltp = (d?['ltp'] as num?)?.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('India VIX', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(ltp != null ? ltp.toStringAsFixed(1) : '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _tfChip(String tf) {
    final sel = _timeframe == tf;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () { setState(() => _timeframe = tf); _load(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: sel ? AppTheme.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Text(tf[0].toUpperCase() + tf.substring(1, 3), style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppTheme.accent : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _errorBox() => Padding(padding: const EdgeInsets.all(16), child: Text(_error ?? 'Error', style: AppTheme.body));

  Widget _radarRow(Recommendation r) {
    final setup = AppTheme.setupLabel(r.finalScore);
    final setupColor = AppTheme.setupColor(r.finalScore);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: r.symbol))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SizedBox(width: 88, child: Text(r.symbol, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Expanded(child: Text(r.finalScore.toStringAsFixed(1), style: AppTheme.mono.copyWith(fontSize: 15))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: setupColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text(setup, style: TextStyle(color: setupColor, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
        ]),
      ),
    );
  }

  Widget _moversSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Market movers', style: AppTheme.sectionLabel),
          const Spacer(),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperstarInvestorsScreen())), child: const Text('Superstars', style: TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 8),
        if (_gainers.isNotEmpty) ...[
          const Text('GAINERS', style: TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          ..._gainers.take(4).map(_moverRow),
          const SizedBox(height: 12),
        ],
        if (_losers.isNotEmpty) ...[
          const Text('LOSERS', style: TextStyle(color: AppTheme.red, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          ..._losers.take(4).map(_moverRow),
        ],
      ]),
    );
  }

  Widget _moverRow(Map<String, dynamic> m) {
    final sym = (m['symbol'] ?? '').toString();
    final ch = (m['change_pct'] as num?)?.toDouble() ?? 0;
    final ltp = (m['ltp'] as num?)?.toDouble();
    final score = (m['final_score'] as num?)?.toDouble();
    final up = ch >= 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: sym))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(flex: 3, child: Text(sym, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          Expanded(flex: 2, child: Text(ltp != null ? '₹${ltp.toStringAsFixed(2)}' : '—', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('${up ? '+' : ''}${ch.toStringAsFixed(2)}%', textAlign: TextAlign.right, style: TextStyle(color: up ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.w700, fontSize: 12))),
          SizedBox(width: 48, child: Text(score != null ? score.toStringAsFixed(0) : '—', textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
      ),
    );
  }
}
