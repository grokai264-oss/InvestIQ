import 'package:shared_preferences/shared_preferences.dart';

/// On-device only. Never sent to backend or Kotak.
class ProfileStore {
  static const _nameKey = 'display_name';
  static const _onboardedKey = 'onboarded_v1';
  static const _watchKey = 'watchlist_symbols';

  Future<String?> getDisplayName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_nameKey);
  }

  Future<void> setDisplayName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_nameKey, name.trim());
    await p.setBool(_onboardedKey, true);
  }

  Future<bool> isOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_onboardedKey) ?? false;
  }

  Future<List<String>> getWatchlist() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_watchKey) ?? [];
  }

  Future<void> toggleWatch(String symbol) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_watchKey) ?? [];
    final s = symbol.toUpperCase();
    if (list.contains(s)) {
      list.remove(s);
    } else {
      list.add(s);
    }
    await p.setStringList(_watchKey, list);
  }

  Future<bool> isWatched(String symbol) async {
    final list = await getWatchlist();
    return list.contains(symbol.toUpperCase());
  }
}
