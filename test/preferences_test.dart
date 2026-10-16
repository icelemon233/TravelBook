import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';
import 'package:cinna_travel_book/features/preferences/domain/user_preferences.dart';

import 'support.dart';

void main() {
  late List<TravelBook> books;
  setUpAll(() async {
    books = await loadBooks(AssetTripRepository(FileAssets()));
  });
  test('legacy web notes, energy, budgets and both checklist formats migrate without renumbering loss', () async {
    final legacy = LegacyValues({
      'cinna-ganwan-v1': jsonEncode({
        'length': 17,
        'notes': {'out-1': '已联系停车场'},
        'checks': {'charge': true},
        'inputs': {'people': 2, 'battery': '60'},
      }),
      'tibet-checklist': jsonEncode({'0': true, '4': true, '5': false}),
    });
    final store = MemoryPreferencesStore(),
        repo = LocalPreferencesRepository(store, legacy);
    await repo.initialize(books);
    final g = repo.snapshot.value.forBook('ganwan'),
        t = repo.snapshot.value.forBook('tibet');
    expect(g.variantId, '17');
    expect(g.notes['out-1'], '已联系停车场');
    expect(g.budget['people'], 2);
    expect(g.energy['battery'], '60');
    expect(t.checks['id-card'], isTrue);
    expect(t.checks['trip-orders'], isTrue);
    expect(legacy.values['cinna-ganwan-v1'], isNotNull);
    await repo.dispose();
  });
  test('rapid notes and checks persist together; budget reset preserves personal data and other trip', () async {
    final store = MemoryPreferencesStore(),
        repo = LocalPreferencesRepository(store, LegacyValues());
    await repo.initialize(books);
    final a = repo.updateBook('ganwan', (p) => p.withNote('yaoli', '自己的备注'));
    final b = repo.updateBook('ganwan', (p) => p.withCheck('sleep', true));
    final c = repo.updateBook('ganwan', (p) => p.withBudget('people', 3));
    await Future.wait([a, b, c]);
    await repo.updateBook('tibet', (p) => p.withCheck('id-card', true));
    await repo.updateBook('ganwan', (p) => p.resetBudget());
    final restarted = LocalPreferencesRepository(store, LegacyValues());
    await restarted.initialize(books);
    expect(restarted.snapshot.value.forBook('ganwan').notes['yaoli'], '自己的备注');
    expect(restarted.snapshot.value.forBook('ganwan').checks['sleep'], isTrue);
    expect(restarted.snapshot.value.forBook('ganwan').budget, isEmpty);
    expect(restarted.snapshot.value.forBook('tibet').checks['id-card'], isTrue);
    await repo.dispose();
    await restarted.dispose();
  });
  test('variant hotel edits remain attached to their original itinerary', () {
    final p = BookPreferences().withBudget('hotel0929', 777, variant: 'B_a_A');
    expect(p.variantBudgets['B_a_A']?['hotel0929'], 777);
    expect(p.variantBudgets['C_a_A'], isNull);
  });
  test('backup roundtrip succeeds; invalid imports and failed durable commits leave existing state intact', () async {
    final store = MemoryPreferencesStore(),
        repo = LocalPreferencesRepository(store, LegacyValues());
    await repo.initialize(books);
    await repo.updateBook('ganwan', (p) => p.withNote('north', '原记录'));
    final before = store.value;
    expect(
      () => UserPreferences.import('{"format":"other"}'),
      throwsFormatException,
    );
    await expectLater(
      repo.importBackup('{"format":"other"}'),
      throwsFormatException,
    );
    expect(store.value, before);
    final imported = UserPreferences().update(
      'ganwan',
      BookPreferences(notes: {'north': '导入记录'}),
    );
    store.failWrites = true;
    await expectLater(
      repo.importBackup(imported.backup()),
      throwsA(isA<Exception>()),
    );
    expect(repo.snapshot.value.forBook('ganwan').notes['north'], '原记录');
    store.failWrites = false;
    await repo.importBackup(imported.backup());
    expect(repo.snapshot.value.forBook('ganwan').notes['north'], '导入记录');
    await repo.dispose();
  });
  test('storage failures are visible and corrupt original content is preserved until explicit valid import', () async {
    final store = MemoryPreferencesStore()..value = '{broken';
    final repo = LocalPreferencesRepository(store, LegacyValues());
    await repo.initialize(books);
    expect(repo.snapshot.error, isNotNull);
    expect(repo.snapshot.recoveryRaw, '{broken');
    await repo.updateBook('ganwan', (p) => p.withNote('out-1', '会话内记录'));
    expect(store.value, '{broken');
    await repo.importBackup(UserPreferences().backup());
    expect(repo.snapshot.error, isNull);
    store.failWrites = true;
    await repo.updateBook('ganwan', (p) => p.withCheck('charge', true));
    expect(repo.snapshot.error, isNotNull);
    expect(repo.snapshot.value.forBook('ganwan').checks['charge'], isTrue);
    await repo.dispose();
  });
}
