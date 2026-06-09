import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key/value storage (mirrors the RN app's AsyncStorage flags).
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<Prefs> create() async =>
      Prefs(await SharedPreferences.getInstance());

  // Keys carried over from the RN app for continuity.
  static const kSeenWelcome = 'wealthify_seen_welcome';
  static const kTheme = 'wealthify_theme';
  static const kPreferences = 'wealthify_prefs';
  static const kAppLock = 'wealthify_app_lock';
  static const kNotifSettings = 'wealthify_notif';
  static const kAddMenuTourSeen = 'wealthify_add_menu_tour_seen_v2';

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
