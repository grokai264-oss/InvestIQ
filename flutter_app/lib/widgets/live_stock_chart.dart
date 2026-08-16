import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Institutional-style research chart.
/// Keeps timestamps + OHLC; shows price axis, time axis, and rich tooltip.
class LiveStockChart extends StatefulWidget {
  final String symbol;
  final bool isLoading;
  final List<Map<String, dynamic>> candles;
  final String? note;
  final ValueChanged<String>? onTimeframeChanged;
  final String initialTimeframe;

  const LiveStockChart({
    super.key,
    required this.symbol,
    required this.isLoading,
    required this.candles,
    this.note,
    this.onTimeframeChanged,
    this.initialTimeframe = '1M',
  });

  @override
  State<LiveStockChart> createState() => _LiveStockChartState();
}

class _LiveStockChartState extends State<LiveStockChart> {
  late String selectedTimeframe;
  final List<String> timeframes = const ['1D', '1W', '1M', '3M', '1Y', '5Y'];

  @override
  void initState() {
    super.initState();
    selectedTimeframe = widget.initialTimeframe;
  }

  List<FlSpot> get _spots {
    final out = <FlSpot>[];
    for (var i = 0; i < widget.candles.length; i++) {
      final c = widget.candles[i]['c'];
      if (c is num) out.add(FlSpot(i.toDouble(), c.toDouble()));
    }
    return out;
  }

  DateTime? _tsAt(int i) {
    if (i < 0 || i >= widget.candles.length) return null;
    final t = widget.candles[i]['t'];
    if (t == null) return null;
    try {
      return DateTime.parse(t.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _xLabel(int i, int n) {
    final dt = _tsAt(i);
    if (dt == null) return '';
    if (selectedTimeframe == '1D') return DateFormat('HH:mm').format(dt);
    if (selectedTimeframe == '1W' || selectedTimeframe == '1M') {
      return DateFormat('dd MMM').format(dt);
    }
    if (selectedTimeframe == '3M' || selectedTimeframe == '1Y') {
      return DateFormat('MMM yy').format(dt);
    }
    return DateFormat('yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: AppTheme.surfaceElevated,
        highlightColor: AppTheme.surfaceHover,
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      );
    }

    final spots = _spots;
    final hasData = spots.length >= 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
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
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: _minY(spots),
                      maxY: _maxY(spots),
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _yInterval(spots),
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppTheme.border.withOpacity(0.45),
                          strokeWidth: 0.6,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            interval: _yInterval(spots),
                            getTitlesWidget: (value, meta) {
                              if (value == meta.min || value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  _priceLabel(value),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: _xInterval(spots.length),
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 || i >= spots.length) return const SizedBox.shrink();
                              final step = _xInterval(spots.length).round();
                              if (step > 0 && i % step != 0 && i != spots.length - 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _xLabel(i, spots.length),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppTheme.surfaceElevated,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          getTooltipItems: (touched) {
                            return touched.map((bar) {
                              final i = bar.x.round().clamp(0, widget.candles.length - 1);
                              final c = widget.candles[i];
                              final dt = _tsAt(i);
                              final dateStr = dt == null
                                  ? ''
                                  : (selectedTimeframe == '1D'
                                      ? DateFormat('dd MMM · HH:mm').format(dt)
                                      : DateFormat('dd MMM yyyy').format(dt));
                              final close = (c['c'] as num?)?.toDouble();
                              final open = (c['o'] as num?)?.toDouble();
                              final high = (c['h'] as num?)?.toDouble();
                              final low = (c['l'] as num?)?.toDouble();
                              final vol = c['v'];
                              final buf = StringBuffer();
                              if (dateStr.isNotEmpty) buf.writeln(dateStr);
                              if (close != null) buf.writeln('₹${close.toStringAsFixed(2)}');
                              if (open != null) buf.writeln('O ${open.toStringAsFixed(2)}');
                              if (high != null) buf.writeln('H ${high.toStringAsFixed(2)}');
                              if (low != null) buf.writeln('L ${low.toStringAsFixed(2)}');
                              if (vol != null) buf.write('Vol $vol');
                              return LineTooltipItem(
                                buf.toString().trim(),
                                const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.18,
                          color: AppTheme.accent,
                          barWidth: 2.0,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.accent.withOpacity(0.22),
                                AppTheme.accent.withOpacity(0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      widget.note ?? 'No history for this range yet.',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _minY(List<FlSpot> pts) {
    var mn = pts.first.y;
    for (final p in pts) {
      if (p.y < mn) mn = p.y;
    }
    final pad = (pts.map((e) => e.y).reduce((a, b) => a > b ? a : b) - mn).abs() * 0.08;
    return mn - (pad < 0.5 ? 0.5 : pad);
  }

  double _maxY(List<FlSpot> pts) {
    var mx = pts.first.y;
    for (final p in pts) {
      if (p.y > mx) mx = p.y;
    }
    final mn = pts.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final pad = (mx - mn).abs() * 0.08;
    return mx + (pad < 0.5 ? 0.5 : pad);
  }

  double _yInterval(List<FlSpot> pts) {
    final span = (_maxY(pts) - _minY(pts)).abs();
    if (span < 1e-6) return 1;
    final raw = span / 4;
    if (raw >= 100) return (raw / 50).ceil() * 50.0;
    if (raw >= 20) return (raw / 10).ceil() * 10.0;
    if (raw >= 5) return (raw / 5).ceil() * 5.0;
    if (raw >= 1) return raw.ceilToDouble();
    return (raw * 10).ceil() / 10.0;
  }

  double _xInterval(int n) {
    if (n <= 5) return 1;
    return (n / 4).floorToDouble().clamp(1, n.toDouble());
  }

  String _priceLabel(double v) {
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v >= 100) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
