import 'dart:async';
import 'package:flutter/material.dart';
import '../data/equity_catalog.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// Instant local equity search; LTP loads in background.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _store = ProfileStore();
  final _ctrl = TextEditingController();
  Timer? _quoteDebounce;
  List<EquityEntry> _hits = [];
  Map<String, QuoteTick> _quotes = {};
  Set<String> _watched = {};
  bool _quotesLoading = false;

  @override
  void initState() {
    super.initState();
    _hits = searchLocal('');
    _loadWatch();
    // quotes after first frame — never block list
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchQuotesBackground());
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatch() async {
    final w = await _store.getWatchlist();
    if (!mounted) return;
    setState(() => _watched = w.map((e) => e.toUpperCase()).toSet());
  }

  void _onQuery(String q) {
    // Instant local filter — no network
    setState(() {
      _hits = searchLocal(q);
    });
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 450), _fetchQuotesBackground);
  }

  Future<void> _fetchQuotesBackground() async {
    if (_hits.isEmpty) return;
    final symbols = _hits.take(20).map((e) => e.symbol).toList();
    setState(() => _quotesLoading = true);
    final map = await _api.getQuotes(symbols);
    if (!mounted) return;
    setState(() {
      _quotes = {..._quotes, ...map};
      _quotesLoading = false;
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
      appBar: AppBar(title: const Text('Search equities')),
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
                hintText: 'BEL, HPCL, Reliance…',
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
                'Instant local search · Prices load in background · EQ only',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ),
          if (_quotesLoading)
            const LinearProgressIndicator(color: AppTheme.accent, minHeight: 2),
          Expanded(
            child: _hits.isEmpty
                ? const Center(
                    child: Text(
                      'No match in catalog. Try BEL, HPCL, RELIANCE…',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
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
                          '${h.name}'
                          '${src == 'kotak' ? ' · Kotak' : (src == 'market' ? ' · Market' : '')}',
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
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textMuted),
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
