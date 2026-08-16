import 'package:shared_preferences/shared_preferences.dart';

/// On-device preferences. Never sent to backend or Kotak.
class ProfileStore {
  static const _nameKey = 'display_name';
  static const _onboardedKey = 'onboarded_v1';
  static const _watchKey = 'watchlist_symbols';
  static const _themeKey = 'theme_id';
  static const _accentKey = 'accent_id';
  static const _densityKey = 'density_id';
  static const _motionKey = 'motion_id';
  static const _soundKey = 'sound_on';
  static const _horizonKey = 'default_horizon';

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

  Future<String> getThemeId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_themeKey) ?? 'midnight';
  }

  Future<void> setThemeId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeKey, id);
  }

  Future<String> getAccentId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_accentKey) ?? 'teal';
  }

  Future<void> setAccentId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_accentKey, id);
  }

  Future<String> getDensityId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_densityKey) ?? 'comfortable';
  }

  Future<void> setDensityId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_densityKey, id);
  }

  Future<String> getMotionId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_motionKey) ?? 'full';
  }

  Future<void> setMotionId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_motionKey, id);
  }

  Future<bool> getSoundOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_soundKey) ?? false;
  }

  Future<void> setSoundOn(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_soundKey, on);
  }

  Future<String> getHorizon() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_horizonKey) ?? 'daily';
  }

  Future<void> setHorizon(String h) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_horizonKey, h);
  }
}
