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
    final nifty = _idx('NIFTY');
    final sensex = _idx('SENSEX');
    final bank = _idx('BANK');
    final vix = _idx('VIX');

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('MARKET PULSE', style: AppTheme.sectionLabel),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _pulseGrid(nifty, sensex, bank, vix),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _regimeLine(vix),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('MARKET MAP', style: AppTheme.sectionLabel),
                  const Spacer(),
                  Text(
                    'NIFTY 500 · size = share · color = 1D',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectorTreemap(
                height: 248,
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tap a sector → concentration → company → calculation audit. '
                'Shares are structural placeholders until live market-cap pipeline.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('SECTOR LEADERS', style: AppTheme.sectionLabel),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _sectorLeaders(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Strongest multi-factor setups · analytical only',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? const ShimmerRecommendationList()
                  : _error != null
                      ? _errorBox()
                      : _recs.isEmpty
                          ? Text('No rankings yet.', style: AppTheme.body)
                          : Column(
                              children: [
                                for (var i = 0; i < _recs.length; i++)
                                  _radarRow(i + 1, _recs[i]),
                              ],
                            ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Analytical signals only · never places orders\n'
                'Methodology: multi-factor + India VIX regime weights',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseGrid(
    Map<String, dynamic>? nifty,
    Map<String, dynamic>? sensex,
    Map<String, dynamic>? bank,
    Map<String, dynamic>? vix,
  ) {
    return Row(
      children: [
        Expanded(child: _pulseCell('Nifty 50', nifty)),
        Container(width: 1, height: 48, color: AppTheme.borderSubtle),
        Expanded(child: _pulseCell('Sensex', sensex)),
        Container(width: 1, height: 48, color: AppTheme.borderSubtle),
        Expanded(child: _pulseCell('Bank Nifty', bank)),
        Container(width: 1, height: 48, color: AppTheme.borderSubtle),
        Expanded(child: _pulseCell('India VIX', vix, isVix: true)),
      ],
    );
  }

  Widget _pulseCell(String label, Map<String, dynamic>? data, {bool isVix = false}) {
    final last = data == null ? '—' : '${data['last'] ?? '—'}';
    final ch = (data?['change_pct'] as num?)?.toDouble();
    final up = (ch ?? 0) >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
          if (ch != null && !isVix)
            Text(
              '${up ? '+' : ''}${ch.toStringAsFixed(2)}%',
              style: TextStyle(
                color: up ? AppTheme.green : AppTheme.red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (isVix)
            const Text('vol gauge', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _regimeLine(Map<String, dynamic>? vix) {
    final v = (vix?['last'] as num?)?.toDouble();
    String regime = 'mid';
    String hint = 'Balanced factor weights';
    if (v != null) {
      if (v < 15) {
        regime = 'low';
        hint = 'Momentum · volume · RSI favoured';
      } else if (v > 22) {
        regime = 'high';
        hint = 'Low-vol · quality favoured';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Regime ${regime.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          if (v != null) ...[
            const SizedBox(width: 8),
            Text('VIX ${v.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectorLeaders() {
    final leaders = [...kMarketSectors]..sort((a, b) => b.changePct.compareTo(a.changePct));
    return Column(
      children: leaders.take(5).map((s) {
        final up = s.changePct >= 0;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SectorDetailScreen(sector: s)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                Text(
                  '${up ? '+' : ''}${s.changePct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: up ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _radarRow(int rank, Recommendation r) {
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

    final factors = r.factors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = factors.take(2).map((e) {
      final label = Recommendation.factorLabels[e.key] ?? e.key.replaceAll('score_', '');
      return label;
    }).toList();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: r.symbol)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rank.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        r.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: setupColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          setup,
                          style: TextStyle(
                            color: setupColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r.finalScore.toStringAsFixed(1)}  ·  ${(r.confidenceScore * 100).round()}% conf'
                    '${top.isNotEmpty ? '  ·  ${top.join('  ·  ')}' : ''}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? AppTheme.accent.withOpacity(0.5) : AppTheme.border),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.red.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Couldn't load radar",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Engine offline or cold-start. Pull to retry.',
            style: AppTheme.body,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
