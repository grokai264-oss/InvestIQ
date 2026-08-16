import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/profile_store.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController()..load(),
      child: const IntelligentStockApp(),
    ),
  );
}

/// Bridges ProfileStore theme preferences to MaterialApp.
class ThemeController extends ChangeNotifier {
  final _store = ProfileStore();
  String _themeId = 'midnight';
  String _accentId = 'teal';

  String get themeId => _themeId;
  String get accentId => _accentId;

  Future<void> load() async {
    _themeId = await _store.getThemeId();
    _accentId = await _store.getAccentId();
    notifyListeners();
  }

  Future<void> setThemeId(String id) async {
    _themeId = id;
    await _store.setThemeId(id);
    notifyListeners();
  }

  Future<void> setAccentId(String id) async {
    _accentId = id;
    await _store.setAccentId(id);
    notifyListeners();
  }

  ThemeData get themeData => AppTheme.themeFor(_themeId, accentId: _accentId);
}

class IntelligentStockApp extends StatelessWidget {
  const IntelligentStockApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, tc, _) {
        final isLight = tc.themeId == 'paper' || tc.themeId == 'light';
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        ));
        return MaterialApp(
          title: 'InvestIQ — Smarter Research. Better Decisions.',
          debugShowCheckedModeBanner: false,
          theme: tc.themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
