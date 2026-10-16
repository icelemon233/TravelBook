import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/app/app_dependencies.dart';
import 'package:cinna_travel_book/app/travel_app.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/library/presentation/library_screen.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';

import 'platform_fakes.dart';
import 'support.dart';

void main() {
  final trips = AssetTripRepository(FileAssets());
  late List<BookSummary> catalog;
  late List<TravelBook> books;
  setUpAll(() async {
    catalog = await trips.catalog();
    books = await loadBooks(trips);
  });
  testWidgets('system back returns from a book to the library', (tester) async {
    final preferences = LocalPreferencesRepository(
      MemoryPreferencesStore(),
      LegacyValues(),
    );
    await preferences.initialize(books);
    final dependencies = AppDependencies(
      trips: trips,
      preferences: preferences,
      files: FakeFileActions(),
      pdf: FakePdfService(),
      mapSnapshots: FakeMapSnapshots(),
      catalog: catalog,
      books: books,
    );
    await tester.pumpWidget(
      TravelApp(
        dependencies: dependencies,
        initialLocation: '/book/ganwan/overview',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await preferences.dispose();
  });
}
