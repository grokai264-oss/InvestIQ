import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Superstar Investors — disclosure-based ownership intelligence.
/// Data is quarterly shareholding pattern, NOT live positions.
class SuperstarInvestorsScreen extends StatefulWidget {
  const SuperstarInvestorsScreen({super.key});
  @override
  State<SuperstarInvestorsScreen> createState() => _SuperstarInvestorsScreenState();
}

class _SuperstarInvestorsScreenState extends State<SuperstarInvestorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _individuals = [
    _Inv('Mukesh Ambani and Family', 360359.65, 2, 'Energy'),
    _Inv('Radhakishan Damani', 181388.25, 12, 'Consumer'),
    _Inv('Premji and Associates', 132137.87, 1, 'IT'),
  ];
  static const _institutions = [
    _Inv('President Of India', 4228487.39, 77, 'Public'),
    _Inv('TATA Sons', 1253237.54, 17, 'Conglomerate'),
    _Inv('SBI Group', 1223052.89, 274, 'Financials'),
  ];
  static const _fii = [
    _Inv('Government Of Singapore', 155627.73, 39, 'FII'),
    _Inv('Government Pension Fund Global', 148063, 100, 'FII'),
    _Inv('Vanguard Fund', 96905, 47, 'FII'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Superstar Investors', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Individuals'),
            Tab(text: 'Institutions'),
            Tab(text: 'FII'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest disclosed holdings',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Q1 FY27 · Jun 2026  ·  Source: company shareholding filings (not live)\n'
                  'Illustrative seed data until NSE XBRL / licensed feed is wired.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _list(_individuals),
                _list(_institutions),
                _list(_fii),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<_Inv> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final inv = items[i];
        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => _openDetail(inv),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _metric('Networth ₹ Cr', _fmt(inv.networthCr))),
                      Expanded(child: _metric('Holdings', '${inv.holdings}')),
                      Expanded(child: _metric('Sector focus', inv.sector)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metric(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$whole.${parts[1]}';
  }

  void _openDetail(_Inv inv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _InvestorDetailPage(inv: inv)),
    );
  }
}

class _Inv {
  final String name;
  final double networthCr;
  final int holdings;
  final String sector;
  const _Inv(this.name, this.networthCr, this.holdings, this.sector);
}

class _InvestorDetailPage extends StatelessWidget {
  final _Inv inv;
  const _InvestorDetailPage({required this.inv});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
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
                const Text(
                  'Disclosed listed holdings · Q1 FY27 · Jun 2026',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _tile('Networth', '₹ ${_fmt(inv.networthCr)} Cr')),
                    const SizedBox(width: 10),
                    Expanded(child: _tile('Companies', '${inv.holdings}')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('QUARTERLY CHANGE', style: AppTheme.sectionLabel),
          const SizedBox(height: 8),
          const Text(
            'QoQ position changes will appear here once the shareholding snapshot feed is connected.\n'
            'Source: company Regulation 31 / XBRL filings — not live broker data.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text('PORTFOLIO CONCENTRATION', style: AppTheme.sectionLabel),
          const SizedBox(height: 8),
          Text(
            inv.holdings <= 2
                ? 'Highly concentrated (${inv.holdings} listed names).'
                : 'Diversified across ${inv.holdings} disclosed holdings.',
            style: AppTheme.body,
          ),
        ],
      ),
    );
  }

  Widget _tile(String k, String v) {
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
          Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$whole.${parts[1]}';
  }
}
