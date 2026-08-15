import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IndicesStrip extends StatelessWidget {
  final List<Map<String, dynamic>> indices;
  const IndicesStrip({super.key, required this.indices});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final x = indices[i];
          final ch = (x['change_pct'] as num?)?.toDouble() ?? 0;
          final up = ch >= 0;
          return Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.cardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${x['name']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const Spacer(),
              Text('${x['last']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${up ? '+' : ''}${ch.toStringAsFixed(2)}%', style: TextStyle(color: up ? AppTheme.green : AppTheme.red, fontSize: 11)),
            ]),
          );
        },
      ),
    );
  }
}
