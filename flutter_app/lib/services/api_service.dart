import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';

enum BackendState { online, waking, offline }

class BackendException implements Exception {
  final String message;
  final BackendState state;
  BackendException(this.message, this.state);
  @override
  String toString() => message;
}

/// READ-ONLY API client. Never calls order/trade endpoints.
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://investiq-g92v.onrender.com',
  );

  static const _quickTimeout = Duration(seconds: 12);
  static const _coldStartTimeout = Duration(seconds: 70);

  Future<BackendState> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/')).timeout(_quickTimeout);
      return res.statusCode == 200 ? BackendState.online : BackendState.offline;
    } on TimeoutException {
      try {
        final res =
            await http.get(Uri.parse('$baseUrl/')).timeout(_coldStartTimeout);
        return res.statusCode == 200 ? BackendState.online : BackendState.offline;
      } catch (_) {
        return BackendState.offline;
      }
    } catch (_) {
      return BackendState.offline;
    }
  }

  Future<List<Recommendation>> getTopRecommendations({
    String timeframe = 'daily',
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/top?timeframe=$timeframe&limit=$limit',
    );
    try {
      final response = await http.get(uri).timeout(_coldStartTimeout);
      if (response.statusCode != 200) {
        throw BackendException(
          'Server error HTTP ${response.statusCode}.',
          BackendState.offline,
        );
      }
      final data = jsonDecode(response.body);
      final list = data['recommendations'] as List? ?? [];
      return list.map((e) => Recommendation.fromJson(e)).toList();
    } on TimeoutException {
      throw BackendException(
        'Server waking up (can take ~1 min on free Render).\nOpen $baseUrl in browser first, then Retry.',
        BackendState.waking,
      );
    } on SocketException {
      throw BackendException(
        'No network path to server.\n1) Open $baseUrl in Chrome\n2) Confirm JSON appears\n3) Tap Retry here',
        BackendState.offline,
      );
    } on HandshakeException {
      throw BackendException(
        'SSL/network blocked. Try mobile data or Wi‑Fi, then Retry.',
        BackendState.offline,
      );
    } on FormatException {
      throw BackendException(
        'Unexpected server response. Please try again.',
        BackendState.offline,
      );
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Connection failed: ${e.runtimeType}.\nTry opening $baseUrl in browser.',
        BackendState.offline,
      );
    }
  }

  Future<Recommendation> getSingleRecommendation({
    required String symbol,
    String timeframe = 'daily',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/${symbol.toUpperCase()}?timeframe=$timeframe',
    );
    try {
      final response = await http.get(uri).timeout(_coldStartTimeout);
      if (response.statusCode != 200) {
        throw BackendException(
          'No data for $symbol (HTTP ${response.statusCode}).',
          BackendState.offline,
        );
      }
      return Recommendation.fromJson(jsonDecode(response.body));
    } on TimeoutException {
      throw BackendException(
        'Server waking up. Open $baseUrl then Retry.',
        BackendState.waking,
      );
    } on SocketException {
      throw BackendException(
        'No network path. Open $baseUrl in browser, then Retry.',
        BackendState.offline,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getIndices() async {
    final uri = Uri.parse('$baseUrl/api/v1/indices');
    try {
      final response = await http.get(uri).timeout(_coldStartTimeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['indices'] ?? []);
    } catch (_) {
      return [];
    }
  }
}
