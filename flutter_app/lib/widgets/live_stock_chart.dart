import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Interactive price chart skeleton for stock research.
/// Data can come from API history when available; otherwise shows empty state.
class LiveStockChart extends StatefulWidget {
  final String symbol;
  final bool isLoading;
  final List<FlSpot> pricePoints;
  final String? note;
  final ValueChanged<String>? onTimeframeChanged;

  const LiveStockChart({
    super.key,
    required this.symbol,
    required this.isLoading,
    required this.pricePoints,
    this.note,
    this.onTimeframeChanged,
  });

  @override
  State<LiveStockChart> createState() => _LiveStockChartState();
}

class _LiveStockChartState extends State<LiveStockChart> {
  String selectedTimeframe = '1M';
  final List<String> timeframes = const ['1D', '1W', '1M', '3M', '1Y', '5Y'];

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: AppTheme.surfaceElevated,
        highlightColor: AppTheme.surfaceHover,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: timeframes.map((tf) {
              final isSelected = selectedTimeframe == tf;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedTimeframe = tf);
                    widget.onTimeframeChanged?.call(tf);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent.withOpacity(0.5) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: widget.pricePoints.length < 2
                ? Center(
                    child: Text(
                      widget.note ??
                          'Historical series loads when the data layer is online.\nLive LTP still updates from quotes.',
                      textAlign: TextAlign.center,
                      style: AppTheme.caption,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _niceInterval(widget.pricePoints),
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppTheme.borderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots
                              .map(
                                (s) => LineTooltipItem(
                                  '₹${s.y.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: widget.pricePoints,
                          isCurved: true,
                          color: AppTheme.green,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.green.withOpacity(0.22),
                                AppTheme.green.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (widget.note != null && widget.pricePoints.length >= 2) ...[
            const SizedBox(height: 4),
            Text(widget.note!, style: AppTheme.caption),
          ],
        ],
      ),
    );
  }

  double _niceInterval(List<FlSpot> pts) {
    if (pts.isEmpty) return 1;
    double mn = pts.first.y, mx = pts.first.y;
    for (final p in pts) {
      if (p.y < mn) mn = p.y;
      if (p.y > mx) mx = p.y;
    }
    final span = (mx - mn).abs();
    if (span < 1e-6) return 1;
    return span / 3;
  }
}
