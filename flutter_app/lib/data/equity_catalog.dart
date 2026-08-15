import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EquityEntry {
  final String symbol;
  final String name;
  const EquityEntry(this.symbol, this.name);
}

List<EquityEntry> _catalog = [];
bool _loaded = false;

const _cacheKey = 'nse_equity_master_v2';
const _assetPath = 'assets/nse_equity.json';

/// Official-style EQUITY_L mirrors (tried in order for background refresh).
const _masterUrls = [
  'https://raw.githubusercontent.com/USRJ78/stock-prediction-app/main/data/EQUITY_L.csv',
  'https://raw.githubusercontent.com/feroze/YFinance-stock-history/master/EQUITY_L.csv',
];

/// Instant load from bundled full NSE master (~2235 symbols).
/// Then optionally refreshes from network + SharedPreferences in background.
Future<void> ensureEquityCatalogLoaded() async {
  if (_loaded && _catalog.length > 1000) return;

  // 1) SharedPreferences cache (fastest after first run)
  try {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.length > 5000) {
      final parsed = _parseMasterJson(cached);
      if (parsed.length > 1000) {
        _catalog = parsed;
        _loaded = true;
        // still try background refresh
        _refreshInBackground(prefs);
        return;
      }
    }
  } catch (_) {}

  // 2) Bundled asset (shipped with APK – 100% offline, instant)
  try {
    final raw = await rootBundle.loadString(_assetPath);
    final parsed = _parseMasterJson(raw);
    if (parsed.length > 1000) {
      _catalog = parsed;
      _loaded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, raw);
      _refreshInBackground(prefs);
      return;
    }
  } catch (_) {}

  // 3) Network download once
  final downloaded = await _downloadMaster();
  if (downloaded.length > 500) {
    _catalog = downloaded;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode([for (final e in downloaded) {'s': e.symbol, 'n': e.name}]),
      );
    } catch (_) {}
    return;
  }

  // 4) Tiny seed so UI never blocks
  _catalog = _seedFallback();
  _loaded = true;
}

void _refreshInBackground(SharedPreferences prefs) {
  Future(() async {
    final fresh = await _downloadMaster();
    if (fresh.length > _catalog.length) {
      _catalog = fresh;
      await prefs.setString(
        _cacheKey,
        jsonEncode([for (final e in fresh) {'s': e.symbol, 'n': e.name}]),
      );
    }
  });
}

Future<List<EquityEntry>> _downloadMaster() async {
  for (final url in _masterUrls) {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 40));
      if (res.statusCode == 200 && res.body.length > 1000) {
        final parsed = _parseEquityCsv(res.body);
        if (parsed.length > 500) return parsed;
      }
    } catch (_) {}
  }
  return [];
}

List<EquityEntry> _parseMasterJson(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final e in list)
        EquityEntry(
          (e['s'] ?? '').toString().toUpperCase(),
          (e['n'] ?? '').toString(),
        )
    ]..sort((a, b) => a.symbol.compareTo(b.symbol));
  } catch (_) {
    return [];
  }
}

List<EquityEntry> _parseEquityCsv(String body) {
  final lines = const LineSplitter().convert(body);
  if (lines.isEmpty) return [];
  final out = <EquityEntry>[];
  final seen = <String>{};
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = _splitCsvLine(line);
    if (parts.isEmpty) continue;
    final sym = parts[0].trim().toUpperCase();
    if (sym.isEmpty || seen.contains(sym)) continue;
    final name = parts.length > 1 ? parts[1].trim() : sym;
    final series = parts.length > 2 ? parts[2].trim().toUpperCase() : 'EQ';
    if (series.isNotEmpty &&
        !const {'EQ', 'BE', 'SM', 'ST', 'BZ'}.contains(series)) {
      continue;
    }
    seen.add(sym);
    out.add(EquityEntry(sym, name.isEmpty ? sym : name));
  }
  // Common search aliases
  if (!seen.contains('HPCL') && seen.contains('HINDPETRO')) {
    final n = out.firstWhere((e) => e.symbol == 'HINDPETRO').name;
    out.add(EquityEntry('HPCL', n));
  }
  out.sort((a, b) => a.symbol.compareTo(b.symbol));
  return out;
}

List<String> _splitCsvLine(String line) {
  final result = <String>[];
  final buf = StringBuffer();
  var inQ = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQ = !inQ;
      continue;
    }
    if (c == ',' && !inQ) {
      result.add(buf.toString());
      buf.clear();
      continue;
    }
    buf.write(c);
  }
  result.add(buf.toString());
  return result;
}

List<EquityEntry> _seedFallback() => const [
      EquityEntry('RELIANCE', 'Reliance Industries'),
      EquityEntry('TCS', 'Tata Consultancy Services'),
      EquityEntry('INFY', 'Infosys'),
      EquityEntry('HDFCBANK', 'HDFC Bank'),
      EquityEntry('ICICIBANK', 'ICICI Bank'),
      EquityEntry('SBIN', 'State Bank of India'),
      EquityEntry('BEL', 'Bharat Electronics'),
      EquityEntry('SUZLON', 'Suzlon Energy'),
      EquityEntry('HPCL', 'Hindustan Petroleum'),
      EquityEntry('HINDPETRO', 'Hindustan Petroleum'),
      EquityEntry('BPCL', 'Bharat Petroleum'),
      EquityEntry('IOC', 'Indian Oil'),
    ];

List<EquityEntry> get kEquityCatalog => _catalog;

List<EquityEntry> searchLocal(String query, {int limit = 40}) {
  final q = query.trim().toUpperCase();
  final catalog = kEquityCatalog;
  if (catalog.isEmpty) {
    if (q.isEmpty) return const [];
    final valid = RegExp(r'^[A-Z0-9&-]{2,15}$');
    if (valid.hasMatch(q)) {
      return [EquityEntry(q, 'NSE equity (loading master…)')];
    }
    return const [];
  }
  if (q.isEmpty) return catalog.take(limit).toList();
  final out = <EquityEntry>[];
  // prefix matches first
  for (final e in catalog) {
    if (e.symbol.startsWith(q)) {
      out.add(e);
      if (out.length >= limit) return out;
    }
  }
  for (final e in catalog) {
    if (out.any((x) => x.symbol == e.symbol)) continue;
    if (e.symbol.contains(q) || e.name.toUpperCase().contains(q)) {
      out.add(e);
      if (out.length >= limit) break;
    }
  }
  final valid = RegExp(r'^[A-Z0-9&-]{2,15}$');
  if (out.isEmpty && valid.hasMatch(q)) {
    out.add(EquityEntry(q, 'NSE equity (open to analyse)'));
  }
  return out;
}
