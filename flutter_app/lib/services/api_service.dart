import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';

/// READ-ONLY API client. Never calls order/trade endpoints.
class ApiService {
  // AFTER Render deploy, paste your URL here (no trailing slash):
  // Example: https://investiq-xxxx.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://YOUR-RENDER-SERVICE.onrender.com',
  );

  // For local testing only, temporarily use:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<Recommendation>> getTopRecommendations({
    String timeframe = 'daily',
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/top?timeframe=$timeframe&limit=$limit',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load recommendations (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final list = data['recommendations'] as List? ?? [];
    return list.map((e) => Recommendation.fromJson(e)).toList();
  }

  Future<Recommendation> getSingleRecommendation({
    required String symbol,
    String timeframe = 'daily',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/${symbol.toUpperCase()}?timeframe=$timeframe',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('No data for $symbol (${response.statusCode})');
    }

    return Recommendation.fromJson(jsonDecode(response.body));
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
