import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';

/// READ-ONLY API client. Never calls order/trade endpoints.
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://investiq-g92v.onrender.com',
  );

  Future<List<Recommendation>> getTopRecommendations({
    String timeframe = 'daily',
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/top?timeframe=$timeframe&limit=$limit',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 45));

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
    final response = await http.get(uri).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('No data for $symbol (${response.statusCode})');
    }

    return Recommendation.fromJson(jsonDecode(response.body));
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 45));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
