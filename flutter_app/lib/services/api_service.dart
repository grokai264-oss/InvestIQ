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

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://investiq-g92v.onrender.com',
  );

  static const _cold = Duration(seconds: 70);

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
}
