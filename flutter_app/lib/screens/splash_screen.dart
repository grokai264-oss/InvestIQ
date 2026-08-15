import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_store.dart';
import '../widgets/brand_mark.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

/// Cinematic but short launch: mark → wordmark → tagline → fade.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _mark;
  late final Animation<double> _word;
  late final Animation<double> _tag;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _mark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _word = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.28, 0.55, curve: Curves.easeOut),
    );
    _tag = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.48, 0.75, curve: Curves.easeOut),
    );
    _c.forward();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    final onboarded = await ProfileStore().isOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboarded ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _mark.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * _mark.value,
                    child: const BrandMark(size: 88),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: _word.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _word.value)),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                        children: [
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
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: _tag.value.clamp(0.0, 1.0),
                  child: const Text(
                    'Smarter Research. Better Decisions.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
