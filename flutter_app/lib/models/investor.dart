/// Disclosed ownership intelligence — quarterly shareholding, NOT live.
enum InvestorCategory { individual, institution, fii }

class InvestorHolding {
  final String symbol;
  final String name;
  final double weightPct;
  final double valueCr;
  final double? qoqChangePct; // percentage-point change in holding

  const InvestorHolding({
    required this.symbol,
    required this.name,
    required this.weightPct,
    required this.valueCr,
    this.qoqChangePct,
  });
}

class Investor {
  final String id;
  final String name;
  final InvestorCategory category;
  final double networthCr;
  final int holdingsCount;
  final String sectorFocus;
  final String style; // Concentrated | Diversified | Core-Satellite
  final double? qoqValueChangePct; // portfolio value QoQ %
  final String? topHoldingSymbol;
  final List<InvestorHolding> holdings;
  final String disclosurePeriod; // e.g. Q1 FY27
  final String disclosureDate; // e.g. 30 Jun 2026

  const Investor({
    required this.id,
    required this.name,
    required this.category,
    required this.networthCr,
    required this.holdingsCount,
    required this.sectorFocus,
    required this.style,
    this.qoqValueChangePct,
    this.topHoldingSymbol,
    this.holdings = const [],
    this.disclosurePeriod = 'Q1 FY27',
    this.disclosureDate = '30 Jun 2026',
  });

  bool get isConcentrated => holdingsCount <= 5 || style == 'Concentrated';
  bool get isIncreasing => (qoqValueChangePct ?? 0) > 0.5;
  bool get isDecreasing => (qoqValueChangePct ?? 0) < -0.5;
}
