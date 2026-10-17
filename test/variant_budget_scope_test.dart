import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/presentation/book_view_model.dart';
import 'package:cinna_travel_book/features/budget/presentation/budget_view_model.dart';
import 'package:cinna_travel_book/features/export/presentation/actions_view_model.dart';
import 'package:cinna_travel_book/features/export/domain/travel_report.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';

import 'platform_fakes.dart';
import 'support.dart';

void main() {
  test('unchanged southern itinerary retains edited hotel price across an irrelevant northern branch', () async {
    final repository = AssetTripRepository(FileAssets()),
        books = await loadBooks(repository);
    final preferences = LocalPreferencesRepository(
      MemoryPreferencesStore(),
      LegacyValues(),
    );
    await preferences.initialize(books);
    final model = BookViewModel(books.last, preferences),
        budget = BudgetViewModel(model, preferences);
    await model.select('scenario', 'A');
    final field = budget.fields.firstWhere((f) => f.id == 'hotel0929');
    await budget.edit(field, '999');
    await model.select('scenario', 'B');
    await model.select('branch', 'b');
    await model.select('scenario', 'A');
    expect(budget.values['hotel0929'], 999);
    expect(model.selectors.any((s) => s.id == 'branch'), isFalse);
    expect(model.variant.budgetWarnings, isNotEmpty);
    budget.dispose();
    model.dispose();
    await preferences.dispose();
  });
  test(
    'invalid budget drafts cannot export an older valid budget silently',
    () async {
      final repository = AssetTripRepository(FileAssets()),
          books = await loadBooks(repository);
      final preferences = LocalPreferencesRepository(
        MemoryPreferencesStore(),
        LegacyValues(),
      );
      await preferences.initialize(books);
      final model = BookViewModel(books.first, preferences),
          budget = BudgetViewModel(model, preferences),
          files = FakeFileActions(),
          pdf = FakePdfService();
      await budget.edit(
        budget.fields.firstWhere((f) => f.id == 'people'),
        'abc',
      );
      final actions = ActionsViewModel(
        files: files,
        pdf: pdf,
        preferences: preferences,
        mapRenderer: FakeMapSnapshots(),
        bookId: model.book.id,
        readReport: () => TravelReport(
          book: model.book,
          variant: model.variant,
          budget: budget.estimate,
          preferences: preferences.snapshot.value.forBook(model.book.id),
        ),
      );
      await actions.exportPdf();
      expect(actions.error, contains('预算参数'));
      expect(pdf.lastReport, isNull);
      expect(files.saved, isEmpty);
      actions.dispose();
      budget.dispose();
      model.dispose();
      await preferences.dispose();
    },
  );
}
