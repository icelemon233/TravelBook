import 'dart:typed_data';

import '../../books/domain/travel_book.dart';
import 'route_map.dart';

class RouteMapSnapshot {
  RouteMapSnapshot(this.document, List<SelectedRoute> routes, {this.panel})
    : routes = List.unmodifiable(routes);
  final MapDocument document;
  final List<SelectedRoute> routes;
  final int? panel;
}

typedef MapSnapshotReader = Future<RouteMapSnapshot> Function({
  TripVariant? variant,
});

abstract interface class MapSnapshotService {
  Future<Uint8List> render(
    MapDocument document,
    List<SelectedRoute> routes, {
    int? panel,
  });
}
