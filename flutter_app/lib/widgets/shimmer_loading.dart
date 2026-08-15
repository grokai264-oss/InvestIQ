import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerRecommendationList extends StatelessWidget {
  final int itemCount;
  const ShimmerRecommendationList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.card,
      highlightColor: AppTheme.cardBorder,
      period: const Duration(milliseconds: 1400),
      child: Column(
        children: List.generate(itemCount, (_) => _skeletonCard()),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _block(width: 72, height: 16),
              const Spacer(),
              _block(width: 64, height: 22, radius: 12),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(),
              const SizedBox(width: 24),
              _metric(),
              const SizedBox(width: 24),
              _metric(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(width: 40, height: 10),
          const SizedBox(height: 6),
          _block(width: 52, height: 14),
        ],
      );

  Widget _block({required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}


/// Backward-compatible alias used by Market / Dashboard screens.
class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  const ShimmerLoading({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) =>
      ShimmerRecommendationList(itemCount: itemCount);
}
