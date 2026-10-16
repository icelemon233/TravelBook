import 'dart:io';

import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/books/domain/trip_repository.dart';
import 'package:cinna_travel_book/features/preferences/domain/preferences_repository.dart';

class FileAssets implements AssetReader {
  @override
  Future<String> read(String path) => File(path).readAsString();
}

class MemoryPreferencesStore implements PreferencesStore {
  String? value;
  bool failWrites = false;
  final writes = <String>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String encoded) async {
    await Future<void>.delayed(Duration.zero);
    if (failWrites) throw const FileSystemException('injected storage failure');
    value = encoded;
    writes.add(encoded);
  }
}

class LegacyValues implements LegacyPreferencesReader {
  LegacyValues([this.values = const {}]);
  final Map<String, String?> values;
  @override
  Map<String, String?> read() => values;
}

Future<List<TravelBook>> loadBooks(AssetTripRepository repository) async =>
    Future.wait((await repository.catalog()).map((s) => repository.book(s.id)));
