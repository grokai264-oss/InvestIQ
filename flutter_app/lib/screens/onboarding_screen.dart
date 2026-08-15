import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_store.dart';
import '../widgets/brand_mark.dart';
import 'main_shell.dart';

/// First-launch product story → workspace setup.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  final _store = ProfileStore();
  int _i = 0;
  bool _saving = false;

  static const _pages = [
    _ObPage(
      title: 'See the whole market',
      body: 'Explore India from sector → company → factor. NIFTY 500 structure, live pulse, research map.',
      icon: Icons.public,
    ),
    _ObPage(
      title: 'Go deeper',
      body: 'Financials → HDFC Bank → momentum → valuation → risk. Drill without losing context.',
      icon: Icons.layers_outlined,
    ),
    _ObPage(
      title: 'Know the why',
      body: 'Every InvestIQ score decomposes into factors, weights, and raw inputs. Transparent scoring. Real data. No hype.',
      icon: Icons.analytics_outlined,
    ),
    _ObPage(
      title: 'Your research workspace',
      body: 'NIFTY 500 · Daily horizon · Read-only portfolio. Analytical only — never places orders.',
      icon: Icons.workspace_premium_outlined,
    ),
  ];

  Future<void> _finish() async {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    setState(() => _saving = true);
    await _store.setDisplayName(n);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  void _next() {
    if (_i < _pages.length) {
      _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isName = _i == _pages.length;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const BrandMarkMini(size: 28),
                  const Spacer(),
                  if (!isName)
                    TextButton(
                      onPressed: () {
                        _page.jumpToPage(_pages.length);
                      },
                      child: const Text('Skip', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (v) => setState(() => _i = v),
                children: [
                  for (final p in _pages) _storyPage(p),
                  _namePage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length + 1, (i) {
                      final on = i == _i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: on ? AppTheme.accent : AppTheme.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isName
                          ? (_saving ? null : _finish)
                          : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isName
                            ? (_saving ? 'Setting up…' : 'Get Started')
                            : (_i == _pages.length - 1 ? 'Continue' : 'Next'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyPage(_ObPage p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Icon(p.icon, color: AppTheme.accent, size: 30),
          ),
          const SizedBox(height: 28),
          Text(p.title, style: AppTheme.display.copyWith(fontSize: 28)),
          const SizedBox(height: 12),
          Text(p.body, style: AppTheme.body.copyWith(fontSize: 15, height: 1.5)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _namePage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          const BrandMark(size: 56, showWordmark: true),
          const SizedBox(height: 28),
          Text('Welcome', style: AppTheme.display.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            'A private name for your desk — stored only on this device.\nNo login. No orders. Analysis only.',
            style: AppTheme.body.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent, width: 1.2),
              ),
            ),
            onSubmitted: (_) => _finish(),
          ),
          const SizedBox(height: 16),
          const Text(
            'NIFTY 500  ·  Daily  ·  Read-only portfolio',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ObPage {
  final String title;
  final String body;
  final IconData icon;
  const _ObPage({required this.title, required this.body, required this.icon});
}
