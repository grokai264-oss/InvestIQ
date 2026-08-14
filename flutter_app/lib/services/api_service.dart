import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation.dart';

/// READ-ONLY API client.
/// This service NEVER calls any order / trade / buy / sell endpoints.
class ApiService {
  // Change this to your backend IP when testing on a real device
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → host
  // static const String baseUrl = 'http://127.0.0.1:8000'; // iOS simulator / desktop

  Future<List<Recommendation>> getTopRecommendations({
    String timeframe = 'daily',
    int limit = 10,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/recommendations/top?timeframe=$timeframe&limit=$limit',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

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
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('No data for $symbol (${response.statusCode})');
    }

    return Recommendation.fromJson(jsonDecode(response.body));
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
