import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// InvestIQ mark: ascending intelligence layers + IQ.
class BrandMark extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;

  const BrandMark({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A3A), Color(0xFF0D1A1A)],
            ),
            border: Border.all(color: AppTheme.accent.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.18),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _MarkPainter(),
            child: Center(
              child: size >= 56
                  ? null
                  : Text(
                      'IQ',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.32,
                      ),
                    ),
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.22),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
              ),
              children: const [
                TextSpan(text: 'Invest'),
                TextSpan(
                  text: 'IQ',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Smarter Research. Better Decisions.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3DDBB0);

    // Ascending arc (market movement)
    final path = Path();
    path.moveTo(size.width * 0.22, size.height * 0.68);
    path.quadraticBezierTo(
      size.width * 0.42,
      size.height * 0.55,
      size.width * 0.52,
      size.height * 0.42,
    );
    path.quadraticBezierTo(
      size.width * 0.62,
      size.height * 0.28,
      size.width * 0.78,
      size.height * 0.22,
    );
    canvas.drawPath(path, paint);

    // Layered bars (intelligence)
    final barPaint = Paint()..style = PaintingStyle.fill;
    final bars = [
      (0.28, 0.55, 0.12, 0.22),
      (0.42, 0.42, 0.12, 0.35),
      (0.56, 0.32, 0.12, 0.45),
    ];
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      barPaint.color = Color.lerp(
        const Color(0xFF2A9B7A),
        const Color(0xFF3DDBB0),
        i / 2,
      )!;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * b.$1,
          size.height * b.$2,
          size.width * b.$3,
          size.height * b.$4,
        ),
        Radius.circular(size.width * 0.03),
      );
      canvas.drawRRect(r, barPaint);
    }

    // Soft ring
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.38,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF3DDBB0).withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact app-bar / nav mark.
class BrandMarkMini extends StatelessWidget {
  final double size;
  const BrandMarkMini({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
        color: AppTheme.surfaceElevated,
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}
