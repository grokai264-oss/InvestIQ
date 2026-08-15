import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/shimmer_loading.dart';
import 'stock_detail_screen.dart';

enum _ViewState { loading, error, empty, loaded }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  List<Recommendation> _recs = [];
  _ViewState _view = _ViewState.loading;
  BackendState? _backendState;
  String _errorMessage = '';
  String _timeframe = 'daily';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _view = _ViewState.loading;
    });
    try {
      final list = await _api.getTopRecommendations(timeframe: _timeframe);
      if (!mounted) return;
      setState(() {
        _recs = list;
        _backendState = BackendState.online;
        _view = list.isEmpty ? _ViewState.empty : _ViewState.loaded;
      });
    } on BackendException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _backendState = e.state;
        _view = _ViewState.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _backendState = BackendState.offline;
        _view = _ViewState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          backgroundColor: AppTheme.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              const DisclaimerBanner(),
              SliiverToBoxAdapter(child: _buildTimeframeChips()),
              if (_view == _ViewState.loading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverToBoxAdapter(child: ShimmerRecommendationList()),
                )
              else if (_view == _ViewState.error)
                SliverFillRemaining(hasScrollBody: false, child: _buildError())
              else if (_view == _ViewState.empty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliiverChildBuilderDelegate(
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: const Text(
              'IQ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
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
                _statusRow(),
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

  Widget _statusRow() {
    Color dotColor;
    String label;
    if (_backendState == BackendState.online) {
      dotColor = AppTheme.green;
      label = 'Live';
    } else if (_backendState == BackendState.waking) {
      dotColor = AppTheme.yellow;
      label = 'Waking up…';
    } else if (_backendState == BackendState.offline) {
      dotColor = AppTheme.red;
      label = 'Offline';
    } else {
      dotColor = AppTheme.textMuted;
      label = 'Checking…';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
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
    final waking = _backendState == BackendState.waking;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (waking ? AppTheme.yellow : AppTheme.red).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                waking ? Icons.hourglass_top_rounded : Icons.cloud_off_rounded,
                size: 28,
                color: waking ? AppTheme.yellow : AppTheme.red,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              waking ? 'Server is waking up' : 'Cannot reach backend',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Could not load recommendations. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.query_stats_rounded, size: 28, color: AppTheme.accent),
            ),
            const SizedBox(height: 18),
            const Text(
              'No recommendations yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'The backend is reachable but has nothing to show for this timeframe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
