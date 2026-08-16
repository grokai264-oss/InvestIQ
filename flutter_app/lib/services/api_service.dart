import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';
import '../models/portfolio.dart';

enum BackendState { online, waking, offline }

class BackendException implements Exception {
  final String message;
  final BackendState state;
  BackendException(this.message, this.state);
  @override
  String toString() => message;
}

class EquityHit {
  final String symbol;
  final String name;
  final String segment;
  EquityHit({required this.symbol, required this.name, this.segment = 'EQ'});
  factory EquityHit.fromJson(Map<String, dynamic> j) => EquityHit(
        symbol: (j['symbol'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        segment: (j['segment'] ?? 'EQ').toString(),
      );
}

class QuoteTick {
  final String symbol;
  final double? ltp;
  final double? changePct;
  final String source;
  QuoteTick({required this.symbol, this.ltp, this.changePct, this.source = 'market'});
  factory QuoteTick.fromJson(Map<String, dynamic> j) => QuoteTick(
        symbol: (j['symbol'] ?? '').toString(),
        ltp: (j['ltp'] as num?)?.toDouble(),
        changePct: (j['change_pct'] as num?)?.toDouble(),
        source: (j['source'] ?? 'market').toString(),
      );
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://investiq-g92v.onrender.com',
  );

  static const _cold = Duration(seconds: 70);
  static const _fast = Duration(seconds: 25);

  Future<List<Recommendation>> getTopRecommendations({
    String timeframe = 'daily',
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/top?timeframe=$timeframe&limit=$limit',
    );
    try {
      final response = await http.get(uri).timeout(_cold);
      if (response.statusCode != 200) {
        throw BackendException('Server error HTTP ${response.statusCode}.', BackendState.offline);
      }
      final data = jsonDecode(response.body);
      final list = data['recommendations'] as List? ?? [];
      return list.map((e) => Recommendation.fromJson(e)).toList();
    } on TimeoutException {
      throw BackendException(
        'Server waking up. Open $baseUrl in browser, then Retry.',
        BackendState.waking,
      );
    } on SocketException {
      throw BackendException(
        'No network path.\n1) Open $baseUrl in Chrome\n2) Tap Retry',
        BackendState.offline,
      );
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Connection failed. Try $baseUrl in browser.', BackendState.offline);
    }
  }

  Future<Recommendation> getSingleRecommendation({
    required String symbol,
    String timeframe = 'daily',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/${symbol.toUpperCase()}?timeframe=$timeframe',
    );
    final response = await http.get(uri).timeout(_cold);
    if (response.statusCode != 200) {
      throw BackendException('No data for $symbol', BackendState.offline);
    }
    return Recommendation.fromJson(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> getIndices() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/v1/indices')).timeout(_cold);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['indices'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<PortfolioSummary> getPortfolio() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/portfolio/summary'))
          .timeout(_cold);
      if (response.statusCode != 200) {
        return PortfolioSummary(
          linked: false,
          message: 'Portfolio unavailable (HTTP ${response.statusCode}).',
          totalValue: 0,
          totalPnl: 0,
          totalPnlPct: 0,
          holdings: [],
        );
      }
      return PortfolioSummary.fromJson(jsonDecode(response.body));
    } catch (_) {
      return PortfolioSummary(
        linked: false,
        message: 'Could not load portfolio. Backend offline or Kotak not linked.',
        totalValue: 0,
        totalPnl: 0,
        totalPnlPct: 0,
        holdings: [],
      );
    }
  }

  Future<List<EquityHit>> searchEquities(String query, {int limit = 25}) async {
    final uri = Uri.parse('$baseUrl/api/v1/search').replace(queryParameters: {
      'q': query,
      'limit': '$limit',
    });
    try {
      final response = await http.get(uri).timeout(_fast);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final list = data['results'] as List? ?? [];
      return list.map((e) => EquityHit.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, QuoteTick>> getQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    final joined = symbols.map((s) => s.toUpperCase()).toSet().join(',');
    final uri = Uri.parse('$baseUrl/api/v1/quotes').replace(queryParameters: {
      'symbols': joined,
    });
    try {
      final response = await http.get(uri).timeout(_fast);
      if (response.statusCode != 200) return {};
      final data = jsonDecode(response.body);
      final list = data['quotes'] as List? ?? [];
      final map = <String, QuoteTick>{};
      for (final e in list) {
        final q = QuoteTick.fromJson(Map<String, dynamic>.from(e));
        map[q.symbol] = q;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String symbol, {String range = '1M'}) async {
    final uri = Uri.parse('$baseUrl/api/v1/stocks/${symbol.toUpperCase()}/history')
        .replace(queryParameters: {'range': range});
    try {
      final response = await http.get(uri).timeout(_cold);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final list = data['points'] as List? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
