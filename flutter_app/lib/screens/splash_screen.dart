import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_store.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    final onboarded = await ProfileStore().isOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => onboarded ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(gradient: AppTheme.brandGradient, borderRadius: BorderRadius.circular(22), boxShadow: AppTheme.cardShadow),
            alignment: Alignment.center,
            child: const Text('IQ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
          ),
          const SizedBox(height: 22),
          Text('InvestIQ', style: AppTheme.serifTitle),
          const SizedBox(height: 8),
          const Text('Smart rankings. Zero auto-trading.', style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}
