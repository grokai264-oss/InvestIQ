import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sector definition for market-cap map.
class SectorNode {
  final String id;
  final String name;
  final String short; // never wraps
  final double share; // 0..1
  final double changePct; // 1D performance (prototype or live)
  final List<String> topSymbols;
  final Color baseColor;

  const SectorNode({
    required this.id,
    required this.name,
    required this.short,
    required this.share,
    required this.changePct,
    required this.topSymbols,
    required this.baseColor,
  });

  /// Color encodes performance; area encodes share.
  Color get heatColor {
    if (changePct >= 1.0) return const Color(0xFF1B7A4E);
    if (changePct >= 0.3) return const Color(0xFF2A9B6A);
    if (changePct >= 0.0) return const Color(0xFF2A5A48);
    if (changePct >= -0.3) return const Color(0xFF4A3A3A);
    if (changePct >= -1.0) return const Color(0xFF7A3A3A);
    return const Color(0xFF9A2A2A);
  }
}

/// Structural NIFTY-oriented sector weights (honest placeholders until live m-cap).
const kMarketSectors = <SectorNode>[
  SectorNode(
    id: 'financials',
    name: 'Financials',
    short: 'Financials',
    share: 0.224,
    changePct: 0.7,
    topSymbols: ['HDFCBANK', 'ICICIBANK', 'SBIN', 'KOTAKBANK', 'AXISBANK'],
    baseColor: Color(0xFF3D5A80),
  ),
  SectorNode(
    id: 'it',
    name: 'Information Technology',
    short: 'IT',
    share: 0.181,
    changePct: 1.8,
    topSymbols: ['TCS', 'INFY', 'HCLTECH', 'TECHM', 'WIPRO'],
    baseColor: Color(0xFF2A6B5A),
  ),
  SectorNode(
    id: 'energy',
    name: 'Energy',
    short: 'Energy',
    share: 0.123,
    changePct: -0.4,
    topSymbols: ['RELIANCE', 'ONGC', 'BPCL', 'IOC', 'HPCL'],
    baseColor: Color(0xFF6B5A2A),
  ),
  SectorNode(
    id: 'fmcg',
    name: 'FMCG',
    short: 'FMCG',
    share: 0.092,
    changePct: 0.2,
    topSymbols: ['HINDUNILVR', 'ITC', 'NESTLEIND', 'BRITANNIA', 'DABUR'],
    baseColor: Color(0xFF5A3A6B),
  ),
  SectorNode(
    id: 'auto',
    name: 'Automobile',
    short: 'Auto',
    share: 0.082,
    changePct: 0.9,
    topSymbols: ['M&M', 'MARUTI', 'TATAMOTORS', 'BAJAJ-AUTO', 'EICHERMOT'],
    baseColor: Color(0xFF2A6B4A),
  ),
  SectorNode(
    id: 'pharma',
    name: 'Pharma',
    short: 'Pharma',
    share: 0.071,
    changePct: -0.2,
    topSymbols: ['SUNPHARMA', 'DRREDDY', 'CIPLA', 'DIVISLAB', 'LUPIN'],
    baseColor: Color(0xFF6B3A4A),
  ),
  SectorNode(
    id: 'metals',
    name: 'Metals',
    short: 'Metals',
    share: 0.061,
    changePct: -0.8,
    topSymbols: ['TATASTEEL', 'JSWSTEEL', 'HINDALCO', 'VEDL', 'COALINDIA'],
    baseColor: Color(0xFF5A5A5A),
  ),
  SectorNode(
    id: 'infra',
    name: 'Infrastructure',
    short: 'Infra',
    share: 0.052,
    changePct: 0.5,
    topSymbols: ['LT', 'ADANIPORTS', 'ULTRACEMCO', 'GRASIM', 'AMBUJACEM'],
    baseColor: Color(0xFF2A5A6B),
  ),
  SectorNode(
    id: 'defence',
    name: 'Defence',
    short: 'Defence',
    share: 0.042,
    changePct: 1.3,
    topSymbols: ['BEL', 'HAL', 'BHEL', 'BDL', 'MAZDOCK'],
    baseColor: Color(0xFF6B5A3A),
  ),
  SectorNode(
    id: 'others',
    name: 'Others',
    short: 'Others',
    share: 0.072,
    changePct: 0.1,
    topSymbols: ['BHARTIARTL', 'POWERGRID', 'NTPC', 'IRFC', 'PFC'],
    baseColor: Color(0xFF4A4A5A),
  ),
];

/// True area-proportional market map. Size = share, color = performance.
/// Labels never mid-word wrap — short names only inside tiles.
class SectorTreemap extends StatelessWidget {
  final List<SectorNode> sectors;
  final void Function(SectorNode sector) onTap;
  final double height;

  const SectorTreemap({
    super.key,
    this.sectors = kMarketSectors,
    required this.onTap,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final byId = {for (final s in sectors) s.id: s};
    SectorNode s(String id) => byId[id]!;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            flex: 40,
            child: Row(
              children: [
                Expanded(flex: 224, child: _tile(s('financials'))),
                const SizedBox(width: 2),
                Expanded(flex: 181, child: _tile(s('it'))),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 35,
            child: Row(
              children: [
                Expanded(flex: 123, child: _tile(s('energy'))),
                const SizedBox(width: 2),
                Expanded(flex: 92, child: _tile(s('fmcg'))),
                const SizedBox(width: 2),
                Expanded(flex: 82, child: _tile(s('auto'))),
                const SizedBox(width: 2),
                Expanded(flex: 71, child: _tile(s('pharma'))),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Expanded(flex: 61, child: _tile(s('metals'))),
                const SizedBox(width: 2),
                Expanded(flex: 52, child: _tile(s('infra'))),
                const SizedBox(width: 2),
                Expanded(flex: 42, child: _tile(s('defence'))),
                const SizedBox(width: 2),
                Expanded(flex: 72, child: _tile(s('others'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(SectorNode n) {
    final up = n.changePct >= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(n),
        child: Container(
          decoration: BoxDecoration(
            color: n.heatColor.withOpacity(0.85),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: n.heatColor.withOpacity(0.5), width: 0.5),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showPct = constraints.maxWidth > 48;
              final showChange = constraints.maxWidth > 64 && constraints.maxHeight > 42;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    n.short,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (showPct || showChange)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showPct)
                          Text(
                            '${(n.share * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        if (showChange)
                          Text(
                            '${up ? '+' : ''}${n.changePct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: up
                                  ? const Color(0xFFB8F0D0)
                                  : const Color(0xFFFFC0C0),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
