import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EquityEntry {
  final String symbol;
  final String name;
  const EquityEntry(this.symbol, this.name);
}

List<EquityEntry> _catalog = [];
bool _loaded = false;

const _cacheKey = 'nse_equity_master_v1';

/// Official-style EQUITY_L mirror (full NSE equity list).
const _masterUrl =
    'https://raw.githubusercontent.com/USRJ78/stock-prediction-app/main/data/EQUITY_L.csv';

/// Loads ~2200+ NSE symbols: cache first, else download once.
Future<void> ensureEquityCatalogLoaded() async {
  if (_loaded && _catalog.isNotEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(_cacheKey);
  if (cached != null && cached.isNotEmpty) {
    _catalog = _parseMasterJson(cached);
    if (_catalog.length > 500) {
      _loaded = true;
      return;
    }
  }

  try {
    final res = await http
        .get(Uri.parse(_masterUrl))
        .timeout(const Duration(seconds: 45));
    if (res.statusCode == 200 && res.body.length > 1000) {
      final parsed = _parseEquityCsv(res.body);
      if (parsed.length > 500) {
        _catalog = parsed;
        await prefs.setString(
          _cacheKey,
          jsonEncode([
            for (final e in parsed) {'s': e.symbol, 'n': e.name},
          ]),
        );
        _loaded = true;
        return;
      }
    }
  } catch (_) {}

  // Seed fallback (still usable offline)
  _catalog = _seedFallback();
  _loaded = true;
}

List<EquityEntry> _parseMasterJson(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final e in list)
        EquityEntry(
          (e['s'] ?? '').toString(),
          (e['n'] ?? '').toString(),
        )
    ];
  } catch (_) {
    return [];
  }
}

List<EquityEntry> _parseEquityCsv(String body) {
  final lines = const LineSplitter().convert(body);
  if (lines.isEmpty) return [];
  final out = <EquityEntry>[];
  final seen = <String>{};
  // header: SYMBOL,NAME OF COMPANY,SERIES,...
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
  // Alias often searched
  if (!seen.contains('HPCL') && seen.contains('HINDPETRO')) {
    final n = out.firstWhere((e) => e.symbol == 'HINDPETRO').name;
    out.add(EquityEntry('HPCL', n));
  }
  out.sort((a, b) => a.symbol.compareTo(b.symbol));
  return out;
}

List<String> _splitCsvLine(String line) {
  // Simple CSV split handling quotes
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
