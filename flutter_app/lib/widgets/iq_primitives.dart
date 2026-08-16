import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

String humanizeTimestamp(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 45) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
    if (diff.inHours < 24 && dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return 'Updated $h:$m $ampm';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} · $h:$m $ampm';
  } catch (_) {
    return raw.length > 19 ? raw.substring(0, 19) : raw;
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
    final human = humanizeTimestamp(updatedAt);
    if (human.isNotEmpty) parts.add(human);
    if (note != null && note!.isNotEmpty) parts.add(note!);
    return Text(parts.join('  ·  '), style: AppTheme.caption);
  }
}

class ResearchBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const ResearchBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('›', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          if (items[i].onTap != null)
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
            )
          else
            Text(
              items[i].label,
              style: TextStyle(
                color: i == items.length - 1 ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: i == items.length - 1 ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
        ],
      ],
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
  const SetupChip({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final label = AppTheme.setupLabel(score);
    final color = AppTheme.setupColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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
    return SizedBox(width: width, height: height, child: CustomPaint(painter: _SparkPainter(values: values, color: color)));
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
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
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: AppTheme.borderSubtle, color: c.withOpacity(0.85)))),
          if (showValue) ...[
            const SizedBox(width: 10),
            SizedBox(width: 32, child: Text(value > 1.0 ? value.round().toString() : (v * 100).round().toString(), textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
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
              SizedBox(width: 88, height: 88, child: CircularProgressIndicator(value: t, strokeWidth: 7, backgroundColor: AppTheme.borderSubtle, color: setupColor, strokeCap: StrokeCap.round)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(score.toStringAsFixed(1), style: AppTheme.mono.copyWith(fontSize: 20)),
                Text('/ 100', style: AppTheme.caption),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('InvestIQ Score', style: AppTheme.sectionLabel),
          const SizedBox(height: 6),
          SetupChip(score: score),
          if (confidence != null) ...[
            const SizedBox(height: 8),
            Text('Signal strength ${(confidence! * 100).round()}% · not calibrated hit-rate', style: AppTheme.caption),
          ],
        ])),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.textMuted, size: 28),
        const SizedBox(height: 12),
        Text(title, style: AppTheme.title),
        const SizedBox(height: 6),
        Text(body, style: AppTheme.body),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          TextButton(onPressed: onAction, style: TextButton.styleFrom(foregroundColor: AppTheme.accent), child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}

class ExpandableAuditRow extends StatefulWidget {
  final String label;
  final double score;
  final double weight;
  final double contribution;
  final Map<String, dynamic> rawInputs;
  final String? regimeNote;
  const ExpandableAuditRow({super.key, required this.label, required this.score, required this.weight, required this.contribution, this.rawInputs = const {}, this.regimeNote});

  @override
  State<ExpandableAuditRow> createState() => _ExpandableAuditRowState();
}

class _ExpandableAuditRowState extends State<ExpandableAuditRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final up = widget.contribution >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Row(children: [
                  Icon(_open ? Icons.expand_more : Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Flexible(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                ])),
                Expanded(child: Text(widget.score.toStringAsFixed(1), textAlign: TextAlign.right, style: AppTheme.monoSmall)),
                Expanded(child: Text('${(widget.weight * 100).toStringAsFixed(0)}%', textAlign: TextAlign.right, style: AppTheme.monoSmall)),
                Expanded(child: Text('${up ? '+' : ''}${widget.contribution.toStringAsFixed(1)}', textAlign: TextAlign.right, style: AppTheme.monoSmall.copyWith(color: up ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12, left: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label.toUpperCase(), style: AppTheme.sectionLabel),
                const SizedBox(height: 8),
                _kv('Contribution', '${up ? '+' : ''}${widget.contribution.toStringAsFixed(2)} points'),
                _kv('Weight', '${(widget.weight * 100).toStringAsFixed(1)}%'),
                _kv('Raw score', widget.score.toStringAsFixed(2)),
                if (widget.regimeNote != null && widget.regimeNote!.isNotEmpty) _kv('Regime', widget.regimeNote!),
                if (widget.rawInputs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('INPUTS', style: AppTheme.caption),
                  const SizedBox(height: 6),
                  ...widget.rawInputs.entries.take(6).map((e) {
                    final v = e.value;
                    String display;
                    if (v is int) {
                      display = v.toString();
                    } else if (v is num) {
                      display = v.toStringAsFixed(2);
                    } else {
                      display = v.toString();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Expanded(child: Text(e.key.replaceAll('_', ' '), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                        Text(display, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ]),
                    );
                  }),
                ],
                const SizedBox(height: 6),
                Text('${widget.score.toStringAsFixed(1)} × ${(widget.weight * 100).toStringAsFixed(0)}% ≈ ${widget.contribution.toStringAsFixed(2)}', style: AppTheme.caption),
              ],
            ),
          ),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppTheme.standard,
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 100, child: Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
    ]),
  );
}
