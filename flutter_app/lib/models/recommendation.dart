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
  final String dataSource;
  final String engineVersion;
  final Map<String, double> weights;
  final Map<String, double> contributions;
  final Map<String, dynamic> rawInputs;
  final String? _regimeOverride;

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
    this.dataSource = 'live',
    this.engineVersion = '2.0',
    Map<String, double>? weights,
    Map<String, double>? contributions,
    Map<String, dynamic>? rawInputs,
    String? regime,
  })  : weights = weights ?? const {},
        contributions = contributions ?? const {},
        rawInputs = rawInputs ?? const {},
        _regimeOverride = regime;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final factors = Map<String, double>.from(
      (json['factors'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
    );

    Map<String, double> parseDoubleMap(dynamic src) {
      if (src is! Map) return {};
      return Map<String, double>.from(
        src.map((k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0)),
      );
    }

    Map<String, dynamic> parseDynamicMap(dynamic src) {
      if (src is! Map) return {};
      return Map<String, dynamic>.from(
        src.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    // Prefer explicit payload; otherwise use sensible defaults from regime weights.
    var weights = parseDoubleMap(json['weights'] ?? json['factor_weights']);
    if (weights.isEmpty) {
      weights = Map<String, double>.from(_defaultWeightsFor(json['timeframe']?.toString() ?? 'daily'));
    }

    var contributions = parseDoubleMap(json['contributions'] ?? json['factor_contributions']);
    if (contributions.isEmpty && factors.isNotEmpty) {
      // Derive contribution ≈ score × weight when backend has not yet emitted it.
      contributions = {};
      for (final e in factors.entries) {
        final wKey = weightKeyMap[e.key] ?? e.key.replaceAll('score_', '');
        final w = weights[wKey] ?? weights[e.key] ?? 0.0;
        contributions[e.key] = e.value * w;
      }
    }

    return Recommendation(
      symbol: json['symbol'] ?? '',
      timeframe: json['timeframe'] ?? 'daily',
      action: json['action'] ?? 'HOLD',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      entryPrice: json['entry_price']?.toDouble(),
      stopLoss: json['stop_loss']?.toDouble(),
      targetPrice: json['target_price']?.toDouble(),
      finalScore: (json['final_score'] ?? 0).toDouble(),
      factors: factors,
      rationale: List<String>.from(json['rationale'] ?? []),
      disclaimer: json['disclaimer'] ??
          'This is an analytical signal only. It does not place any orders.',
      generatedAt: json['generated_at'] ?? '',
      dataSource: json['data_source']?.toString() ?? 'live',
      engineVersion: json['engine_version']?.toString() ?? '2.0',
      weights: weights,
      contributions: contributions,
      rawInputs: parseDynamicMap(json['raw_inputs'] ?? json['inputs'] ?? json['raw']),
      regime: json['regime']?.toString(),
    );
  }

  bool get isBuy => action == 'BUY' || action == 'STRONG BUY';
  bool get isSell => action == 'SELL';

  /// Parsed regime string (e.g. "low (India VIX 11.3)") or null.
  String? get regime {
    if (_regimeOverride != null && _regimeOverride!.isNotEmpty) return _regimeOverride;
    return regimeFromRationale;
  }

  String? get regimeFromRationale {
    for (final r in rationale) {
      final lower = r.toLowerCase();
      if (lower.startsWith('regime=')) {
        return r.substring(r.indexOf('=') + 1).trim();
      }
      if (lower.contains('regime')) return r;
    }
    return null;
  }

  static const factorLabels = {
    'score_rsi': 'RSI',
    'score_ema': 'Trend',
    'score_rvol': 'Volume',
    'score_macd': 'MACD',
    'score_vwap': 'VWAP',
    'score_momentum': 'Momentum',
    'score_low_vol': 'LowVol',
    'score_delivery': 'Delivery',
    'score_fii': 'FII (mkt)',
    'score_fii_market': 'FII (mkt)',
    'score_value': 'Value',
  };

  /// Preferred display / audit order for factors.
  static const List<String> auditOrder = [
    'score_rsi',
    'score_ema',
    'score_rvol',
    'score_macd',
    'score_vwap',
    'score_momentum',
    'score_low_vol',
    'score_delivery',
    'score_fii_market',
    'score_fii',
    'score_value',
  ];

  /// Map score_* keys → weight map keys used by regime_weights().
  static const Map<String, String> weightKeyMap = {
    'score_rsi': 'rsi',
    'score_ema': 'ema',
    'score_rvol': 'rvol',
    'score_macd': 'macd',
    'score_vwap': 'vwap',
    'score_momentum': 'momentum',
    'score_low_vol': 'low_vol',
    'score_delivery': 'delivery',
    'score_fii': 'fii',
    'score_fii_market': 'fii',
    'score_value': 'value',
  };

  /// Fallback weights when backend does not yet return them (matches daily mid-regime defaults).
  static Map<String, double> _defaultWeightsFor(String timeframe) {
    const daily = {
      'rsi': 0.18,
      'ema': 0.12,
      'rvol': 0.15,
      'macd': 0.08,
      'vwap': 0.15,
      'momentum': 0.12,
      'low_vol': 0.05,
      'delivery': 0.08,
      'fii': 0.05,
      'value': 0.02,
    };
    const monthly = {
      'rsi': 0.12,
      'ema': 0.15,
      'rvol': 0.10,
      'macd': 0.08,
      'vwap': 0.12,
      'momentum': 0.18,
      'low_vol': 0.08,
      'delivery': 0.08,
      'fii': 0.05,
      'value': 0.04,
    };
    const yearly = {
      'rsi': 0.08,
      'ema': 0.15,
      'rvol': 0.05,
      'macd': 0.07,
      'vwap': 0.10,
      'momentum': 0.20,
      'low_vol': 0.12,
      'delivery': 0.08,
      'fii': 0.05,
      'value': 0.10,
    };
    switch (timeframe.toLowerCase()) {
      case 'monthly':
        return monthly;
      case 'yearly':
        return yearly;
      default:
        return daily;
    }
  }
}
