import 'dart:convert';

import '../../../core/json_values.dart';
import '../../map/domain/route_map.dart';
import '../domain/travel_book.dart';
import '../domain/trip_repository.dart';

class AssetTripRepository implements TripRepository {
  AssetTripRepository(this.assets);
  final AssetReader assets;
  List<BookSummary>? _catalog;
  final _books = <String, TravelBook>{}, _maps = <String, MapDocument>{};
  @override
  Future<List<BookSummary>> catalog() async {
    if (_catalog != null) return _catalog!;
    final json = jsonObject(
      jsonDecode(await assets.read('assets/data/catalog.json')),
    );
    if (json.number('schemaVersion') != 1) {
      throw const FormatException('Unsupported catalog version');
    }
    final books = json.objects('books').map(BookSummary.fromJson).toList();
    if (books.map((b) => b.id).toSet().length != books.length) {
      throw const FormatException('Duplicate book ID');
    }
    _catalog = List.unmodifiable(books);
    return _catalog!;
  }

  @override
  Future<TravelBook> book(String id) async {
    if (_books[id] != null) return _books[id]!;
    final summaries = await catalog(),
        summary = summaries.where((s) => s.id == id).firstOrNull;
    if (summary == null) throw ArgumentError.value(id, 'id', '未知路书');
    final value = TravelBook.fromJson(
      jsonObject(jsonDecode(await assets.read(summary.asset))),
    );
    if (value.id != id ||
        value.variants.isEmpty ||
        !value.variants.any((v) => v.id == value.defaultVariantId)) {
      throw const FormatException('Invalid travel book');
    }
    for (final variant in value.variants) {
      if (variant.days.map((d) => d.id).toSet().length != variant.days.length) {
        throw const FormatException('Duplicate stable day ID');
      }
    }
    _books[id] = value;
    return value;
  }

  @override
  Future<MapDocument> map(String id) async {
    if (_maps[id] != null) return _maps[id]!;
    final value = await book(id);
    final map = MapDocument.fromJson(
      jsonObject(jsonDecode(await assets.read(value.mapAsset))),
    );
    _maps[id] = map;
    return map;
  }
}
