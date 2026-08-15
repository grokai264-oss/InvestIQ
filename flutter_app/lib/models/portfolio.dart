class Holding {
  final String symbol;
  final double quantity;
  final double avgPrice;
  final double ltp;
  final double pnl;
  final double pnlPct;

  Holding({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    required this.ltp,
    required this.pnl,
    required this.pnlPct,
  });

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
        symbol: j['symbol']?.toString() ?? '',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        avgPrice: (j['avg_price'] as num?)?.toDouble() ?? 0,
        ltp: (j['ltp'] as num?)?.toDouble() ?? 0,
        pnl: (j['pnl'] as num?)?.toDouble() ?? 0,
        pnlPct: (j['pnl_pct'] as num?)?.toDouble() ?? 0,
      );
}

class PortfolioSummary {
  final bool linked;
  final String message;
  final double totalValue;
  final double totalPnl;
  final double totalPnlPct;
  final List<Holding> holdings;

  PortfolioSummary({
    required this.linked,
    required this.message,
    required this.totalValue,
    required this.totalPnl,
    required this.totalPnlPct,
    required this.holdings,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> j) => PortfolioSummary(
        linked: j['linked'] == true,
        message: j['message']?.toString() ?? '',
        totalValue: (j['total_value'] as num?)?.toDouble() ?? 0,
        totalPnl: (j['total_pnl'] as num?)?.toDouble() ?? 0,
        totalPnlPct: (j['total_pnl_pct'] as num?)?.toDouble() ?? 0,
        holdings: (j['holdings'] as List? ?? [])
            .map((e) => Holding.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
