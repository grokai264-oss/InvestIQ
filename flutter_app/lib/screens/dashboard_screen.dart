import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/disclaimer_banner.dart';
import 'stock_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  List<Recommendation> _recs = [];
  bool _loading = true;
  String? _error;
  String _timeframe = 'daily';
  bool _backendOnline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final online = await _api.healthCheck();
      final list = await _api.getTopRecommendations(timeframe: _timeframe);
      if (mounted) {
        setState(() {
          _backendOnline = online;
          _recs = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _backendOnline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SpouseToBoxAdapter(child: _buildHeader()),
              const DisclaimerBanner(),
              SliverToBoxAdapter(child: _buildTimeframeChips()),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildError())
              else if (_recs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No recommendations yet.\nStart the Python backend first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SpiverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rec = _recs[index];
                        return RecommendationCard(
                          rec: rec,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockDetailScreen(symbol: rec.symbol),
                            ),
                          ),
                        ).animate().fadeIn(delay: (40 * index).ms).slideY(begin: 0.08);
                      },
                      childCount: _recs.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'InvestIQ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _backendOnline ? AppTheme.green : AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _backendOnline ? 'Backend online' : 'Backend offline',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['daily', 'monthly', 'yearly'].map((tf) {
          final selected = _timeframe == tf;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tf[0].toUpperCase() + tf.substring(1)),
              selected: selected,
              onSelected: (_) {
                setState(() => _timeframe = tf);
                _load();
              },
              selectedColor: AppTheme.accent.withOpacity(0.25),
              labelStyle: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: AppTheme.card,
              side: BorderSide(
                color: selected ? AppTheme.accent : AppTheme.cardBorder,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Cannot reach backend',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the Python API first:\n'
              'cd backend && uvicorn api.main:app --reload --port 8000',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
