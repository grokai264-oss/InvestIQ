import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_store.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = TextEditingController();
  final _store = ProfileStore();
  bool _saving = false;

  Future<void> _continue() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await _store.setDisplayName(name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('IQ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
              ),
              const SizedBox(height: 28),
              Text('Welcome', style: AppTheme.serifTitle),
              const SizedBox(height: 8),
              const Text(
                'A private name for your desk — stored only on this device.\nNo login. No orders. Analysis only.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ctrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'How should we address you?',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g. Arjun',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                ),
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Enter desk', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(flex: 3),
              const Center(
                child: Text(
                  'Analytical only · Never places buy/sell orders',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
