import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});
  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _store = ProfileStore();
  final _api = ApiService();
  List<String> _symbols = [];
  Map<String, QuoteTick> _quotes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final w = await _store.getWatchlist();
    final quotes = await _api.getQuotes(w);
    if (!mounted) return;
    setState(() {
      _symbols = w;
      _quotes = quotes;
      _loading = false;
    });
  }

  Future<void> _remove(String s) async {
    await _store.toggleWatch(s);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Watchlist', style: AppTheme.serifTitle.copyWith(fontSize: 26)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ).then((_) => _load()),
                    icon: const Icon(Icons.search, color: AppTheme.accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Equity only · Prices: Kotak LTP if held in linked account, else market · On-device list',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ))
              else if (_symbols.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No symbols yet',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search equities and tap the star, or star from Desk analysis.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        ).then((_) => _load()),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search equities'),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                      ),
                    ],
                  ),
                )
              else
                ..._symbols.map((s) {
                  final q = _quotes[s];
                  final ltp = q?.ltp;
                  final src = q?.source;
                  final chg = q?.changePct;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      tileColor: AppTheme.card,
                      title: Text(s, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        src == 'kotak'
                            ? 'Kotak Neo LTP'
                            : (src == 'market' ? 'Market quote' : 'Price unavailable'),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ltp != null ? '₹${ltp.toStringAsFixed(2)}' : '—',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              if (chg != null)
                                Text(
                                  '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: chg >= 0 ? AppTheme.green : AppTheme.red,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.star, color: AppTheme.accent, size: 20),
                            onPressed: () => _remove(s),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: s)),
                      ).then((_) => _load()),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
