import 'dart:convert';
import 'package:flutter/services.dart';

class EquityEntry {
  final String symbol;
  final String name;
  const EquityEntry(this.symbol, this.name);
}

List<EquityEntry> _catalog = [];
bool _loaded = false;

/// Call once at app start (or first search). Loads full NSE master from assets.
Future<void> ensureEquityCatalogLoaded() async {
  if (_loaded && _catalog.isNotEmpty) return;
  try {
    final raw = await rootBundle.loadString('assets/nse_equity.json');
    final list = jsonDecode(raw) as List;
    _catalog = [
      for (final e in list)
        EquityEntry(
          (e['s'] ?? e['symbol'] ?? '').toString(),
          (e['n'] ?? e['name'] ?? '').toString(),
        )
    ];
    _loaded = true;
  } catch (_) {
    _catalog = const [
      EquityEntry('RELIANCE', 'Reliance Industries'),
      EquityEntry('SUZLON', 'Suzlon Energy'),
      EquityEntry('BEL', 'Bharat Electronics'),
      EquityEntry('HPCL', 'Hindustan Petroleum'),
      EquityEntry('HINDPETRO', 'Hindustan Petroleum'),
    ];
    _loaded = true;
  }
}

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
  if (q.isEmpty) {
    return catalog.take(limit).toList();
  }
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
