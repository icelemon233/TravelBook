import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/reference.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/books/presentation/book_view_model.dart';
import 'package:cinna_travel_book/features/budget/presentation/budget_view_model.dart';
import 'package:cinna_travel_book/features/export/presentation/actions_view_model.dart';
import 'package:cinna_travel_book/features/map/presentation/map_view_model.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';
import 'package:cinna_travel_book/features/preferences/domain/user_preferences.dart';
import 'package:cinna_travel_book/features/risks/presentation/risk_view_model.dart';

import 'platform_fakes.dart';
import 'support.dart';

void main() {
  final repository = AssetTripRepository(FileAssets());
  late List<TravelBook> books;
  setUpAll(() async {
    books = await loadBooks(repository);
  });
  test('variant changes refresh budget and invalidate removed map day without losing notes', () async {
    final preferences = LocalPreferencesRepository(
      MemoryPreferencesStore(),
      LegacyValues(),
    );
    await preferences.initialize(books);
    final model = BookViewModel(books.first, preferences),
        budget = BudgetViewModel(model, preferences),
        map = MapViewModel(model, preferences, repository);
    await map.load();
    map.selectDay('taohuatan');
    final cache = map.routes;
    expect(identical(cache, map.routes), isTrue);
    await preferences.updateBook('ganwan', (p) => p.withNote('out-1', '测试备注'));
    expect(identical(cache, map.routes), isTrue);
    await model.select('length', '15');
    expect(map.selectedDay, isNull);
    expect(budget.estimate.days, 15);
    expect(preferences.snapshot.value.forBook('ganwan').notes['out-1'], '测试备注');
    budget.dispose();
    map.dispose();
    model.dispose();
    await preferences.dispose();
  });
  test('risk filters compose and reset together', () {
    final model = RiskViewModel(books.last.risks);
    model.update(date: '10/4', category: '航班衔接', level: '高', query: '航班');
    expect(model.risks, isNotEmpty);
    expect(model.risks.every((r) => r.dates.contains('10/4')), isTrue);
    model.reset();
    expect(model.risks.length, 14);
    model.dispose();
  });
  test('platform actions reject unsafe links, handle import cancellation, and export current state', () async {
    final preferences = LocalPreferencesRepository(
      MemoryPreferencesStore(),
      LegacyValues(),
    );
    await preferences.initialize(books);
    final files = FakeFileActions(),
        actions = ActionsViewModel(
          files: files,
          pdf: FakePdfService(),
          preferences: preferences,
          mapRenderer: FakeMapSnapshots(),
        );
    await actions.open(
      const Reference(title: 'bad', url: 'javascript:alert(1)'),
    );
    expect(actions.error, isNotNull);
    expect(files.opened, isEmpty);
    actions.clearMessage();
    await actions.importBackup();
    expect(actions.message, isNull);
    expect(actions.error, isNull);
    await preferences.updateBook('ganwan', (p) => p.withNote('out-1', '导出内容'));
    await actions.exportBackup();
    expect(
      String.fromCharCodes(files.saved.last.bytes),
      contains('cinna-travel-book'),
    );
    files.nextBackup = UserPreferences()
        .update('tibet', BookPreferences(checks: {'id-card': true}))
        .backup();
    await actions.importBackup();
    expect(actions.message, '已导入备份。');
    expect(
      preferences.snapshot.value.forBook('tibet').checks['id-card'],
      isTrue,
    );
    actions.dispose();
    await preferences.dispose();
  });
}
