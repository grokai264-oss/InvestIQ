import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/profile_store.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = ProfileStore();
  final _ctrl = TextEditingController();
  String? _name;
  String _horizon = 'daily';
  int _watchCount = 0;
  String _themeId = 'midnight';
  String _accentId = 'teal';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await _store.getDisplayName();
    final w = await _store.getWatchlist();
    final h = await _store.getHorizon();
    final t = await _store.getThemeId();
    final a = await _store.getAccentId();
    if (!mounted) return;
    setState(() {
      _name = n;
      _ctrl.text = n ?? '';
      _watchCount = w.length;
      _horizon = h;
      _themeId = t;
      _accentId = a;
    });
  }

  Future<void> _save() async {
    await _store.setDisplayName(_ctrl.text.trim());
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved on this device only')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = (_name == null || _name!.isEmpty) ? 'Researcher' : _name!;
    final initial = display.isNotEmpty ? display[0].toUpperCase() : 'R';
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(display, style: AppTheme.title.copyWith(fontSize: 20)),
                      const SizedBox(height: 2),
                      const Text(
                        'Investor · Researcher',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const BrandMarkMini(size: 32),
              ],
            ),
            const SizedBox(height: 28),
            Text('YOUR RESEARCH', style: AppTheme.sectionLabel),
            const SizedBox(height: 12),
            _statRow([
              _stat('Watchlist', '$_watchCount'),
              _stat('Universe', '~120 liquid'),
              _stat('Horizon', _horizon),
            ]),
            const SizedBox(height: 28),
            Text('APPEARANCE', style: AppTheme.sectionLabel),
            const SizedBox(height: 10),
            const Text('Theme', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Midnight', _themeId == 'midnight', () async {
                  await tc.setThemeId('midnight');
                  setState(() => _themeId = 'midnight');
                }),
                _chip('Paper', _themeId == 'paper', () async {
                  await tc.setThemeId('paper');
                  setState(() => _themeId = 'paper');
                }),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Accent', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in ['teal', 'blue', 'violet', 'emerald', 'amber'])
                  _chip(id[0].toUpperCase() + id.substring(1), _accentId == id, () async {
                    await tc.setAccentId(id);
                    setState(() => _accentId = id);
                  }),
              ],
            ),
            const SizedBox(height: 28),
            Text('PREFERENCES', style: AppTheme.sectionLabel),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Display name',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                child: const Text('Save on this device'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Default horizon', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: ['daily', 'monthly', 'yearly'].map((h) {
                final on = _horizon == h;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _horizon = h);
                      await _store.setHorizon(h);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? AppTheme.accentSoft : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: on ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        h[0].toUpperCase() + h.substring(1),
                        style: TextStyle(
                          color: on ? AppTheme.accent : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text('DATA & METHODOLOGY', style: AppTheme.sectionLabel),
            const SizedBox(height: 8),
            _linkRow('Market universe', 'Liquid core (~120) · full NSE search catalog'),
            _linkRow('Scoring model', 'Continuous factors + VIX regime weights'),
            _linkRow('FII / DII', 'Market-wide only — never stock-specific'),
            _linkRow('Confidence', 'Score-distance (not calibrated hit-rate)'),
            _linkRow('Market-cap map', 'Structural shares · live free-float next'),
            _linkRow('Quotes', 'Near-live poll (cache ~20s) · WebSocket next'),
            const SizedBox(height: 28),
            Text('PRIVACY & SAFETY', style: AppTheme.sectionLabel),
            const SizedBox(height: 8),
            _bullet('Analytical rankings only — no buy / sell / order APIs'),
            _bullet('Kotak credentials stay on the server (env only)'),
            _bullet('Display name & watchlist stay on this phone'),
            _bullet('100% read-only product surface'),
            _bullet('Single-user private research until auth is added'),
            const SizedBox(height: 28),
            Text('CONNECTION', style: AppTheme.sectionLabel),
            const SizedBox(height: 8),
            Text(
              ApiService.baseUrl,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.code_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'InvestIQ Core Architecture',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Built by Ashish Sarswat',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const BrandMark(size: 40, showWordmark: true, showTagline: true),
            const SizedBox(height: 12),
            const Text(
              'InvestIQ 2.1 · Engine 2.1 · Read-only',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Markets are noisy. Insights are rare.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppTheme.accentSoft : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _statRow(List<Widget> kids) {
    return Row(
      children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0) Container(width: 1, height: 36, color: AppTheme.borderSubtle),
          Expanded(child: kids[i]),
        ],
      ],
    );
  }

  Widget _stat(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _linkRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          Expanded(child: Text(t, style: AppTheme.body)),
        ],
      ),
    );
  }
}
