import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.yellow.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.yellow),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Analytical only · Never places buy/sell orders · You remain fully responsible',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
