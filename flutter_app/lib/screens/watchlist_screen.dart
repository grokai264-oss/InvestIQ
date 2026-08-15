import 'package:flutter/material.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});
  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _store = ProfileStore();
  List<String> _symbols = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await _store.getWatchlist();
    if (!mounted) return;
    setState(() => _symbols = w);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('Watchlist', style: AppTheme.serifTitle.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            const Text('Star symbols from Desk · saved on this device only', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            if (_symbols.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(),
                child: const Text('No symbols yet. Open a stock from Desk and add it to watch.', style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              ..._symbols.map((s) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.cardBorder)),
                    tileColor: AppTheme.card,
                    title: Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailScreen(symbol: s))).then((_) => _load()),
                  )),
          ],
        ),
      ),
    );
  }
}
