import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.yellow),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Analytical only • Never places buy/sell orders • You remain fully responsible',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
