import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// Equity search (NSE EQ) — star to watchlist, open desk analysis.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _store = ProfileStore();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<EquityHit> _hits = [];
  Map<String, QuoteTick> _quotes = {};
  Set<String> _watched = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final w = await _store.getWatchlist();
    final hits = await _api.searchEquities('');
    final quotes = await _api.getQuotes(hits.map((e) => e.symbol).toList());
    if (!mounted) return;
    setState(() {
      _watched = w.map((e) => e.toUpperCase()).toSet();
      _hits = hits;
      _quotes = quotes;
    });
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    final hits = await _api.searchEquities(q);
    final quotes = await _api.getQuotes(hits.map((e) => e.symbol).toList());
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _quotes = quotes;
      _loading = false;
    });
  }

  Future<void> _toggle(String symbol) async {
    await _store.toggleWatch(symbol);
    final w = await _store.getWatchlist();
    if (!mounted) return;
    setState(() => _watched = w.map((e) => e.toUpperCase()).toSet());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _watched.contains(symbol.toUpperCase())
              ? '$symbol added to watchlist'
              : '$symbol removed from watchlist',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search equities'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onQuery,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Symbol or name (e.g. BEL, Reliance)',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.accent),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NSE equity (EQ) only · Star to watch · LTP from Kotak if held, else market',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: AppTheme.accent, minHeight: 2),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: _hits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final h = _hits[i];
                final q = _quotes[h.symbol];
                final watched = _watched.contains(h.symbol);
                final ltp = q?.ltp;
                final src = q?.source ?? '';
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  tileColor: AppTheme.card,
                  title: Text(h.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${h.name} · ${h.segment}'
                    '${src == 'kotak' ? ' · Kotak LTP' : (src == 'market' ? ' · Market' : '')}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ltp != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '₹${ltp.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          watched ? Icons.star : Icons.star_border,
                          color: AppTheme.accent,
                        ),
                        onPressed: () => _toggle(h.symbol),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: h.symbol)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
