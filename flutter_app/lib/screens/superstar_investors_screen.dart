import 'package:flutter/material.dart';
import '../data/superstar_seed.dart';
import '../models/investor.dart';
import '../theme/app_theme.dart';

/// Superstar Investors — disclosure-based ownership intelligence.
/// Quarterly shareholding pattern, NOT live positions / NOT Kotak.
class SuperstarInvestorsScreen extends StatefulWidget {
  const SuperstarInvestorsScreen({super.key});
  @override
  State<SuperstarInvestorsScreen> createState() =>
      _SuperstarInvestorsScreenState();
}

enum _Filter { all, topValue, mostHoldings, increasing, decreasing, concentrated }

class _SuperstarInvestorsScreenState extends State<SuperstarInvestorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _search.addListener(() => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  InvestorCategory get _cat {
    switch (_tabs.index) {
      case 1:
        return InvestorCategory.institution;
      case 2:
        return InvestorCategory.fii;
      default:
        return InvestorCategory.individual;
    }
  }

  List<Investor> get _visible {
    var list = SuperstarSeed.byCategory(_cat);
    if (_query.isNotEmpty) {
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(_query) ||
              e.sectorFocus.toLowerCase().contains(_query) ||
              (e.topHoldingSymbol ?? '').toLowerCase().contains(_query))
          .toList();
    }
    switch (_filter) {
      case _Filter.topValue:
        list = List.of(list)..sort((a, b) => b.networthCr.compareTo(a.networthCr));
        break;
      case _Filter.mostHoldings:
        list = List.of(list)..sort((a, b) => b.holdingsCount.compareTo(a.holdingsCount));
        break;
      case _Filter.increasing:
        list = list.where((e) => e.isIncreasing).toList()
          ..sort((a, b) =>
              (b.qoqValueChangePct ?? 0).compareTo(a.qoqValueChangePct ?? 0));
        break;
      case _Filter.decreasing:
        list = list.where((e) => e.isDecreasing).toList()
          ..sort((a, b) =>
              (a.qoqValueChangePct ?? 0).compareTo(b.qoqValueChangePct ?? 0));
        break;
      case _Filter.concentrated:
        list = list.where((e) => e.isConcentrated).toList();
        break;
      case _Filter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Superstar Investors',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Individuals (${SuperstarSeed.individuals.length})'),
            Tab(text: 'Institutions (${SuperstarSeed.institutions.length})'),
            Tab(text: 'FII (${SuperstarSeed.fii.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _disclosureBanner(),
          _searchBar(),
          _filterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: [
                Text('TOP INVESTORS', style: AppTheme.sectionLabel),
                const Spacer(),
                Text(
                  '${items.length} shown',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No investors match filters',
                        style: TextStyle(color: AppTheme.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _InvestorCard(
                      inv: items[i],
                      rank: i + 1,
                      onTap: () => _openDetail(items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _disclosureBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.yellow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Latest disclosed holdings',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${SuperstarSeed.period} · ${SuperstarSeed.asOf}\n'
            'Source: ${SuperstarSeed.source}\n'
            'Illustrative expanded seed until NSE XBRL / licensed feed is wired.',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search investor, sector, or ticker…',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.accentMuted),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final chips = <(_Filter, String)>[
      (_Filter.all, 'All'),
      (_Filter.topValue, 'Top value'),
      (_Filter.mostHoldings, 'Most holdings'),
      (_Filter.increasing, 'Increasing'),
      (_Filter.decreasing, 'Decreasing'),
      (_Filter.concentrated, 'Concentrated'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (f, label) = chips[i];
          final on = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: on ? AppTheme.accentSoft : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: on ? AppTheme.accent.withOpacity(0.45) : AppTheme.border),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(Investor inv) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _InvestorDetailPage(inv: inv)),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────

class _InvestorCard extends StatelessWidget {
  final Investor inv;
  final int rank;
  final VoidCallback onTap;
  const _InvestorCard({required this.inv, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final qoq = inv.qoqValueChangePct;
    final qoqColor = qoq == null
        ? AppTheme.textMuted
        : (qoq >= 0 ? AppTheme.green : AppTheme.red);
    final qoqLabel = qoq == null
        ? '—'
        : '${qoq >= 0 ? '↑' : '↓'} ${qoq.abs().toStringAsFixed(1)}% QoQ';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '${inv.sectorFocus} · ${inv.style}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metric('Value', _fmtCr(inv.networthCr)),
                  ),
                  Expanded(
                    child: _metric('Holdings', '${inv.holdingsCount}'),
                  ),
                  Expanded(
                    child: _metric(
                      'Top',
                      inv.topHoldingSymbol ?? '—',
                      valueColor: AppTheme.accent,
                    ),
                  ),
                  Expanded(
                    child: _metric('Change', qoqLabel, valueColor: qoqColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String k, String v, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10, letterSpacing: 0.3)),
        const SizedBox(height: 3),
        Text(
          v,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: valueColor ?? AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _fmtCr(double v) {
  if (v >= 100000) {
    return '₹${(v / 100000).toStringAsFixed(2)}L Cr';
  }
  if (v >= 1000) {
    return '₹${(v / 1000).toStringAsFixed(2)}K Cr';
  }
  final s = v.toStringAsFixed(0);
  final whole = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '₹$whole Cr';
}

// ─── Detail ───────────────────────────────────────────────────────

class _InvestorDetailPage extends StatelessWidget {
  final Investor inv;
  const _InvestorDetailPage({required this.inv});

  @override
  Widget build(BuildContext context) {
    final qoq = inv.qoqValueChangePct;
    final qoqColor = qoq == null
        ? AppTheme.textMuted
        : (qoq >= 0 ? AppTheme.green : AppTheme.red);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(inv.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.name, style: AppTheme.display.copyWith(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  'Disclosed · ${inv.disclosurePeriod} · ${inv.disclosureDate}',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${inv.sectorFocus} · ${inv.style}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _tile('Networth', _fmtCr(inv.networthCr))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _tile('Companies', '${inv.holdingsCount}')),
                  ],
                ),
                if (qoq != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          'QoQ value',
                          '${qoq >= 0 ? '+' : ''}${qoq.toStringAsFixed(1)}%',
                          valueColor: qoqColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tile(
                          'Concentration',
                          inv.isConcentrated ? 'HIGH' : 'MODERATE',
                          valueColor: inv.isConcentrated
                              ? AppTheme.yellow
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('PORTFOLIO ALLOCATION', style: AppTheme.sectionLabel),
          const SizedBox(height: 10),
          if (inv.holdings.isEmpty)
            const Text(
              'Detailed holdings appear when the shareholding snapshot feed is connected.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
            )
          else
            ...inv.holdings.map(_holdingBar),
          const SizedBox(height: 20),
          Text('QUARTERLY CHANGE', style: AppTheme.sectionLabel),
          const SizedBox(height: 8),
          if (inv.holdings.any((h) => h.qoqChangePct != null))
            ...inv.holdings.where((h) => h.qoqChangePct != null).map((h) {
              final c = h.qoqChangePct!;
              final col = c >= 0 ? AppTheme.green : AppTheme.red;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(h.symbol,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(h.name,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '${c >= 0 ? '↑' : '↓'} ${c.abs().toStringAsFixed(1)} pp',
                      style: TextStyle(
                          color: col,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
              );
            })
          else
            const Text(
              'QoQ position changes will appear once consecutive disclosure snapshots are available.\n'
              'Source: company Regulation 31 / XBRL filings — not live broker data.',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, height: 1.4),
            ),
          const SizedBox(height: 20),
          Text('PROVENANCE', style: AppTheme.sectionLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'This module uses disclosed ownership only. Live LTP, volume, and '
              'InvestIQ technical scores come from the market data path (Kotak / Yahoo) — '
              'never mixed into investor networth figures.',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _holdingBar(InvestorHolding h) {
    final w = (h.weightPct / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${h.symbol}  ·  ${h.name}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${h.weightPct.toStringAsFixed(1)}%',
                style: AppTheme.monoSmall.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: w,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtCr(h.valueCr),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _tile(String k, String v, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            v,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
