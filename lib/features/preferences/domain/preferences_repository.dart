import '../../books/domain/travel_book.dart';
import 'user_preferences.dart';

class PreferencesSnapshot {
  const PreferencesSnapshot({
    required this.value,
    required this.saving,
    this.error,
    this.recoveryRaw,
  });
  final UserPreferences value;
  final bool saving;
  final String? error, recoveryRaw;
}

abstract interface class PreferencesRepository {
  PreferencesSnapshot get snapshot;
  Stream<PreferencesSnapshot> get changes;
  Future<void> initialize(List<TravelBook> books);
  Future<void> updateBook(
    String id,
    BookPreferences Function(BookPreferences) edit,
  );
  Future<void> importBackup(String source);
  Future<void> flush();
  Future<void> dispose();
}

abstract interface class PreferencesStore {
  Future<String?> read();
  Future<void> write(String value);
}

abstract interface class LegacyPreferencesReader {
  Map<String, String?> read();
}
