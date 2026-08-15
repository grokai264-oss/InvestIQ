import 'dart:async';
import 'package:flutter/material.dart';
import '../data/equity_catalog.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// Instant local equity search over full NSE master; LTP loads in background.
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
  bool _catalogReady = false;
  int _catalogCount = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await ensureEquityCatalogLoaded();
    final w = await _store.getWatchlist();
    if (!mounted) return;
    setState(() {
      _catalogReady = true;
      _catalogCount = kEquityCatalog.length;
      _watched = w.map((e) => e.toUpperCase()).toSet();
      _hits = searchLocal(_ctrl.text);
    });
    _fetchQuotesBackground();
  }

  void _onQuery(String q) {
    setState(() {
      _hits = searchLocal(q);
    });
    _quoteDebounce?.cancel();
    _quoteDebounce =
        Timer(const Duration(milliseconds: 450), _fetchQuotesBackground);
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
      appBar: AppBar(title: const Text('Search InvestIQ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onQuery,
              enabled: _catalogReady,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _catalogReady
                    ? 'Company, sector or theme…'
                    : 'Loading NSE master…',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _catalogReady
                    ? '$_catalogCount NSE symbols · Instant offline · Prices in background'
                    : 'Loading full NSE equity list…',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ),
          if (_quotesLoading || !_catalogReady)
            const LinearProgressIndicator(color: AppTheme.accent, minHeight: 2),
          Expanded(
            child: !_catalogReady
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent))
                : _hits.isEmpty
                    ? _emptyState()
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
                            title: Text(h.symbol,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              '${h.name}'
                              '${src == 'kotak' ? ' · Kotak' : (src == 'market' ? ' · Market' : '')}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (ltp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '₹${ltp.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
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
                              MaterialPageRoute(
                                builder: (_) =>
                                    StockDetailScreen(symbol: h.symbol),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) {
      return const Center(
        child: Text(
          'No match. Try exact NSE symbol (e.g. SUZLON).',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    const popular = ['BEL', 'Defence', 'HDFCBANK', 'TCS', 'RELIANCE', 'SUZLON'];
    const tryAsk = [
      'Top Defence companies',
      'BEL calculation',
      'Best momentum stocks',
      'NIFTY 500 structure',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'POPULAR',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popular.map((s) {
            return ActionChip(
              label: Text(s),
              backgroundColor: AppTheme.surface,
              side: const BorderSide(color: AppTheme.border),
              labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              onPressed: () {
                _ctrl.text = s;
                _onQuery(s);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'TRY ASKING',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ...tryAsk.map(
          (s) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accent),
            title: Text(s, style: const TextStyle(fontSize: 14)),
            onTap: () {
              final parts = s.split(' ');
              final token = parts.firstWhere(
                (w) => w.length >= 3 && w.toUpperCase() == w,
                orElse: () => parts.last,
              );
              _ctrl.text = token;
              _onQuery(token);
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Search routes into company research and calculation audit.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}
