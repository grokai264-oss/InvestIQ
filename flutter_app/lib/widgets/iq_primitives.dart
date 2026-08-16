import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared visual primitives for InvestIQ 2.0 — Visual Intelligence.

enum DataFreshness { live, delayed, cached }

class FreshnessPill extends StatelessWidget {
  final DataFreshness state;
  final String? label;
  const FreshnessPill({super.key, required this.state, this.label});

  @override
  Widget build(BuildContext context) {
    late Color c;
    late String text;
    switch (state) {
      case DataFreshness.live:
        c = AppTheme.green;
        text = label ?? 'LIVE';
        break;
      case DataFreshness.delayed:
        c = AppTheme.yellow;
        text = label ?? 'DELAYED';
        break;
      case DataFreshness.cached:
        c = AppTheme.textMuted;
        text = label ?? 'CACHED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class ProvenanceLine extends StatelessWidget {
  final String source;
  final String? updatedAt;
  final String? note;
  const ProvenanceLine({super.key, required this.source, this.updatedAt, this.note});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[source];
    if (updatedAt != null && updatedAt!.isNotEmpty) parts.add(updatedAt!);
    if (note != null && note!.isNotEmpty) parts.add(note!);
    return Text(parts.join('  ·  '), style: AppTheme.caption);
  }
}

class ResearchBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const ResearchBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('›', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
            GestureDetector(
              onTap: items[i].onTap,
              child: Text(
                items[i].label,
                style: TextStyle(
                  color: i == items.length - 1 ? AppTheme.textPrimary : AppTheme.accent,
                  fontSize: 12,
                  fontWeight: i == items.length - 1 ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  const BreadcrumbItem(this.label, {this.onTap});
}

class SetupChip extends StatelessWidget {
  final double score;
  final bool compact;
  const SetupChip({super.key, required this.score, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.setupColor(score);
    final label = AppTheme.setupLabel(score);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(compact ? 4 : 12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: compact ? 10 : 11, fontWeight: FontWeight.w700)),
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double width;
  const Sparkline({super.key, required this.values, this.color = AppTheme.accent, this.height = 28, this.width = 64});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);
    return SizedBox(
      width: width, height: height,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

class FactorBar extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool showValue;
  const FactorBar({super.key, required this.label, required this.value, this.color, this.showValue = true});

  @override
  Widget build(BuildContext context) {
    final v = value > 1.0 ? (value / 100).clamp(0.0, 1.0) : value.clamp(0.0, 1.0);
    final c = color ?? AppTheme.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v, minHeight: 6,
                backgroundColor: AppTheme.borderSubtle,
                color: c.withOpacity(0.85),
              ),
            ),
          ),
          if (showValue) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 32,
              child: Text(
                value > 1.0 ? value.round().toString() : (v * 100).round().toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ScoreAnatomy extends StatelessWidget {
  final double score;
  final String setup;
  final Color setupColor;
  final double? confidence;
  const ScoreAnatomy({super.key, required this.score, required this.setup, required this.setupColor, this.confidence});

  @override
  Widget build(BuildContext context) {
    final t = (score / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 88, height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88, height: 88,
                child: CircularProgressIndicator(
                  value: t, strokeWidth: 7,
                  backgroundColor: AppTheme.borderSubtle,
                  color: setupColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(score.toStringAsFixed(1), style: AppTheme.mono.copyWith(fontSize: 20)),
                  Text('/ 100', style: AppTheme.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('InvestIQ Score', style: AppTheme.sectionLabel),
              const SizedBox(height: 6),
              SetupChip(score: score),
              if (confidence != null) ...[
                const SizedBox(height: 8),
                Text('${(confidence! * 100).round()}% confidence', style: AppTheme.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SoftStatus extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  const SoftStatus({super.key, required this.title, required this.body, this.actionLabel, this.onAction, this.icon = Icons.cloud_off_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 28),
          const SizedBox(height: 12),
          Text(title, style: AppTheme.title),
          const SizedBox(height: 6),
          Text(body, style: AppTheme.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
