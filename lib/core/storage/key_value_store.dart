import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key/value persistence (feature flags, onboarding state,
/// theme preference). For secrets use `SecureStorage` instead.
class KeyValueStore {
  KeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<KeyValueStore> create() async =>
      KeyValueStore(await SharedPreferences.getInstance());

  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}
