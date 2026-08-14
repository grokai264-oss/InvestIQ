class Recommendation {
  final String symbol;
  final String timeframe;
  final String action;
  final double confidenceScore;
  final double? entryPrice;
  final double? stopLoss;
  final double? targetPrice;
  final double finalScore;
  final Map<String, double> factors;
  final List<String> rationale;
  final String disclaimer;
  final String generatedAt;

  Recommendation({
    required this.symbol,
    required this.timeframe,
    required this.action,
    required this.confidenceScore,
    this.entryPrice,
    this.stopLoss,
    this.targetPrice,
    required this.finalScore,
    required this.factors,
    required this.rationale,
    required this.disclaimer,
    required this.generatedAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      symbol: json['symbol'] ?? '',
      timeframe: json['timeframe'] ?? 'daily',
      action: json['action'] ?? 'HOLD',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      entryPrice: json['entry_price']?.toDouble(),
      stopLoss: json['stop_loss']?.toDouble(),
      targetPrice: json['target_price']?.toDouble(),
      finalScore: (json['final_score'] ?? 0).toDouble(),
      factors: Map<String, double>.from(
        (json['factors'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      rationale: List<String>.from(json['rationale'] ?? []),
      disclaimer: json['disclaimer'] ??
          'This is an analytical signal only. It does not place any orders.',
      generatedAt: json['generated_at'] ?? '',
    );
  }

  bool get isBuy => action == 'BUY' || action == 'STRONG BUY';
  bool get isSell => action == 'SELL';
}
