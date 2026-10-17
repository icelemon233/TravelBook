import 'package:flutter/services.dart';

import '../core/platform/file_actions.dart';
import '../core/platform/platform_file_actions.dart';
import '../features/books/data/asset_trip_repository.dart';
import '../features/books/data/bundle_asset_reader.dart';
import '../features/books/domain/travel_book.dart';
import '../features/books/domain/trip_repository.dart';
import '../features/export/data/travel_pdf_service.dart';
import '../features/export/domain/travel_pdf_service.dart';
import '../features/map/domain/map_snapshot_service.dart';
import '../features/map/presentation/route_map_painter.dart';
import '../features/preferences/data/local_preferences_repository.dart';
import '../features/preferences/data/platform_preferences_store.dart';
import '../features/preferences/domain/preferences_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.trips,
    required this.preferences,
    required this.files,
    required this.pdf,
    required this.mapSnapshots,
    required List<BookSummary> catalog,
    required List<TravelBook> books,
  }) : catalog = List.unmodifiable(catalog),
       books = Map.unmodifiable({for (final book in books) book.id: book});
  final TripRepository trips;
  final PreferencesRepository preferences;
  final FileActions files;
  final TravelPdfService pdf;
  final MapSnapshotService mapSnapshots;
  final List<BookSummary> catalog;
  final Map<String, TravelBook> books;
  static Future<AppDependencies> load() async {
    final trips = AssetTripRepository(BundleAssetReader(rootBundle)),
        catalog = await trips.catalog();
    final books = await Future.wait(catalog.map((b) => trips.book(b.id)));
    final preferences = LocalPreferencesRepository(
      SharedPreferencesStore(),
      PlatformLegacyPreferencesReader(),
    );
    await preferences.initialize(books);
    return AppDependencies(
      trips: trips,
      preferences: preferences,
      files: PlatformFileActions(),
      pdf: BundledTravelPdfService(rootBundle),
      mapSnapshots: const MapImageRenderer(),
      catalog: catalog,
      books: books,
    );
  }
}
