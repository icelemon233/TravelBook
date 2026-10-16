import 'dart:typed_data';

import 'route_map.dart';

abstract interface class MapSnapshotService {
  Future<Uint8List> render(
    MapDocument document,
    List<SelectedRoute> routes, {
    int? panel,
  });
}
