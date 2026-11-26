import 'package:shared_preferences/shared_preferences.dart';

/// Only an appearance string is stored; report drafts are unaffected.
abstract class AppearanceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalAppearanceStore implements AppearanceStore {
  LocalAppearanceStore({SharedPreferencesAsync? preferences})
    : _injected = preferences;
  final SharedPreferencesAsync? _injected;
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();
  static const key = 'streetmend.appearance';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}
