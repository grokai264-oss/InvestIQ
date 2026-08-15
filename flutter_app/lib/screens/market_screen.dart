import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/indices_strip.dart';
import '../widgets/regime_banner.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/shimmer_loading.dart';
import 'search_screen.dart';
import 'stock_detail_screen.dart';

/// Market research home: overview → sector map → signal board.
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

  static const _sectors = [
    _Sector('IT', 0.18, Color(0xFF2DD4BF)),
    _Sector('Financials', 0.22, Color(0xFF818CF8)),
    _Sector('Energy', 0.12, Color(0xFFFBBF24)),
    _Sector('Auto', 0.08, Color(0xFF34D399)),
    _Sector('Pharma', 0.07, Color(0xFFF87171)),
    _Sector('Defence', 0.04, Color(0xFFD4A574)),
    _Sector('Metals', 0.06, Color(0xFF94A3B8)),
    _Sector('FMCG', 0.09, Color(0xFFA78BFA)),
    _Sector('Infra', 0.05, Color(0xFF38BDF8)),
    _Sector('Others', 0.09, Color(0xFF64748B)),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Market'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 16, color: AppTheme.indigo),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Research universe · NIFTY 500 structure',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    Text(
                      _timeframe.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_indices.isNotEmpty) IndicesStrip(indices: _indices),
            RegimeBanner(indices: _indices),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('SECTOR MAP', style: AppTheme.sectionTitle.copyWith(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
              )),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Industry classification · macro → sector (prototype shares)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sectors.map((s) {
                        final w = (s.share * 280).clamp(56.0, 140.0);
                        final h = (s.share * 220).clamp(44.0, 88.0);
                        return GestureDetector(
                          onTap: () => _openSector(s.name),
                          child: Container(
                            width: w,
                            height: h,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: s.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: s.color.withOpacity(0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(s.name, style: TextStyle(color: s.color, fontWeight: FontWeight.w700, fontSize: 12)),
                                Text('${(s.share * 100).toStringAsFixed(0)}%', style: TextStyle(color: s.color.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Shares are structural placeholders. Live market-cap aggregation ships with NIFTY 500 pipeline.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('SIGNAL BOARD', style: AppTheme.sectionTitle.copyWith(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.2)),
                  const Spacer(),
                  _tfChip('daily'),
                  const SizedBox(width: 6),
                  _tfChip('monthly'),
                  const SizedBox(width: 6),
                  _tfChip('yearly'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? const ShimmerLoading()
                  : _error != null
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration(borderColor: AppTheme.red.withOpacity(0.4)),
                          child: Text('Engine offline or cold-start. Pull to retry.\n$_error', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        )
                      : _recs.isEmpty
                          ? const Text('No rankings yet.', style: TextStyle(color: AppTheme.textSecondary))
                          : Column(
                              children: _recs.map((r) => RecommendationCard(
                                rec: r,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: r.symbol))),
                              )).toList(),
                            ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Analytical only · never places orders · methodology: multi-factor + VIX regime weights',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
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
          color: on ? AppTheme.accentSoft : AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppTheme.accent : AppTheme.cardBorder),
        ),
        child: Text(
          tf[0].toUpperCase() + tf.substring(1),
          style: TextStyle(color: on ? AppTheme.accent : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openSector(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name · open names via Search or Signal Board'), backgroundColor: AppTheme.cardElevated, duration: const Duration(seconds: 2)),
    );
  }
}

class _Sector {
  final String name;
  final double share;
  final Color color;
  const _Sector(this.name, this.share, this.color);
}
