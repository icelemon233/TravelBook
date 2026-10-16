import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';
import 'package:cinna_travel_book/features/preferences/domain/user_preferences.dart';

import 'support.dart';

class GatedPreferenceStore extends MemoryPreferencesStore {
  Completer<void>? barrier;
  @override
  Future<void> write(String encoded) async {
    final pending = barrier;
    if (pending != null) await pending.future;
    await super.write(encoded);
  }
}

void main() {
  test(
    'edits issued during durable import apply to the imported snapshot',
    () async {
      final books = await loadBooks(AssetTripRepository(FileAssets())),
          store = GatedPreferenceStore();
      final repo = LocalPreferencesRepository(store, LegacyValues());
      await repo.initialize(books);
      await repo.updateBook('ganwan', (p) => p.withNote('out-1', '旧内容'));
      store.barrier = Completer<void>();
      final imported = UserPreferences().update(
        'ganwan',
        BookPreferences(notes: {'out-1': '导入内容'}, checks: {'sleep': true}),
      );
      final import = repo.importBackup(imported.backup());
      await Future<void>.delayed(Duration.zero);
      final edit = repo.updateBook(
        'ganwan',
        (p) => p.withCheck('charge', true),
      );
      store.barrier!.complete();
      await Future.wait([import, edit]);
      final saved = repo.snapshot.value.forBook('ganwan');
      expect(saved.notes['out-1'], '导入内容');
      expect(saved.checks['sleep'], isTrue);
      expect(saved.checks['charge'], isTrue);
      final restarted = LocalPreferencesRepository(store, LegacyValues());
      await restarted.initialize(books);
      expect(
        restarted.snapshot.value.forBook('ganwan').checks['charge'],
        isTrue,
      );
      await repo.dispose();
      await restarted.dispose();
    },
  );
  test(
    '4000 user-perceived note characters roundtrip without splitting emoji',
    () {
      final note = List.filled(4000, '📍').join();
      final p = BookPreferences().withNote('out-1', note);
      final source = UserPreferences().update('ganwan', p).backup();
      expect(
        UserPreferences.import(source).forBook('ganwan').notes['out-1'],
        note,
      );
      expect(() => p.withNote('out-1', '${note}x'), throwsFormatException);
    },
  );
}
