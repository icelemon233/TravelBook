import 'package:shared_preferences/shared_preferences.dart';

import '../domain/preferences_repository.dart';
import 'legacy_values.dart';

class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const key = 'cinna.travel.book.v1';
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class PlatformLegacyPreferencesReader implements LegacyPreferencesReader {
  @override
  Map<String, String?> read() => readLegacyValues();
}
