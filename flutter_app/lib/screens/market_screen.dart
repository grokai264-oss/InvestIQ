import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sector_treemap.dart';
import '../widgets/shimmer_loading.dart';
import 'search_screen.dart';
import 'sector_detail_screen.dart';
import 'stock_detail_screen.dart';

/// Market home — research hierarchy:
/// Pulse → Map → Leaders → Radar → Company audit
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _api = ApiService();
  List<Recommendation> _recs = [];
  List<Map<String, dynamic>> _indices = [];
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
      if (!mounted) return;
      setState(() {
        _recs = recs;
        _indices = idx;
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text('MARKET MAP', style: AppTheme.sectionLabel),
                      const Spacer(),
                      Text('NIFTY 500 structure', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectorTreemap(
                    height: 228,
                    onTap: (s) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SectorDetailScreen(sector: s),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Text('INVESTIQ RADAR', style: AppTheme.sectionLabel),
                      const Spacer(),
                      _tfChip('daily'),
                      const SizedBox(width: 6),
                      _tfChip('monthly'),
                      const SizedBox(width: 6),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            ch == null ? '—' : '${up ? '+' : ''}${ch.toStringAsFixed(2)}%',
            style: TextStyle(
              color: ch == null ? AppTheme.textMuted : (up ? AppTheme.green : AppTheme.red),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vixCell(Map<String, dynamic>? d) {
    final v = (d?['ltp'] as num?)?.toDouble() ?? (d?['value'] as num?)?.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('India VIX', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            v == null ? '—' : v.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tfChip(String tf) {
    final on = _timeframe == tf;
    return GestureDetector(
      onTap: () {
        if (_timeframe == tf) return;
        setState(() => _timeframe = tf);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? AppTheme.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppTheme.accent : AppTheme.border),
        ),
        child: Text(
          tf[0].toUpperCase() + tf.substring(1),
          style: TextStyle(
            color: on ? AppTheme.accent : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(borderColor: AppTheme.red.withOpacity(0.4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend offline', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: AppTheme.body),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radarRow(Recommendation r) {
    String setup;
    Color setupColor;
    if (r.finalScore >= 75) {
      setup = 'Strong';
      setupColor = AppTheme.green;
    } else if (r.finalScore >= 60) {
      setup = 'Watch';
      setupColor = AppTheme.accent;
    } else if (r.finalScore >= 40) {
      setup = 'Neutral';
      setupColor = AppTheme.textMuted;
    } else {
      setup = 'Weak';
      setupColor = AppTheme.red;
    }
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: r.symbol)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                r.symbol,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
              ),
            ),
            Expanded(
              child: Text(
                r.finalScore.toStringAsFixed(1),
                style: AppTheme.mono.copyWith(fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: setupColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                setup,
                style: TextStyle(color: setupColor, fontSize: 11, fontWeight: FontWeight.w600),
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
