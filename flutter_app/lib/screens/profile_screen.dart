import 'package:flutter/material.dart';
import '../services/profile_store.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = ProfileStore();
  final _ctrl = TextEditingController();
  String? _name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await _store.getDisplayName();
    if (!mounted) return;
    setState(() { _name = n; _ctrl.text = n ?? ''; });
  }

  Future<void> _save() async {
    await _store.setDisplayName(_ctrl.text);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved on this device only')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('Profile', style: AppTheme.serifTitle.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            const Text('Local desk identity · never sent to servers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Display name', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: AppTheme.bg),
                  child: const Text('Save'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Safety', style: AppTheme.serifSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                const Text('• Analytical rankings only\n• No buy / sell / order APIs\n• Kotak credentials stay on server\n• Display name stays on phone', style: TextStyle(color: AppTheme.textSecondary, height: 1.55, fontSize: 13)),
                const SizedBox(height: 12),
                Text('API: ${ApiService.baseUrl}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
