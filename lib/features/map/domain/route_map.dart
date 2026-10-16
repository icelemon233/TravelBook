import '../../../core/json_values.dart';
import '../../books/domain/travel_book.dart';

class GeoPoint {
  const GeoPoint(this.longitude, this.latitude);
  factory GeoPoint.fromJson(Object? value) {
    final list = value! as List;
    final lon = (list[0] as num).toDouble(), lat = (list[1] as num).toDouble();
    if (!lon.isFinite || !lat.isFinite || lon.abs() > 180 || lat.abs() > 90) {
      throw const FormatException('Invalid geographic coordinate');
    }
    return GeoPoint(lon, lat);
  }
  final double longitude, latitude;
}

class MapPlace {
  const MapPlace(this.id, this.name, this.point);
  factory MapPlace.fromJson(String id, Json json) => MapPlace(
    id,
    json.text('name', id),
    GeoPoint.fromJson(json['coordinates']),
  );
  final String id, name;
  final GeoPoint point;
}

class MapRoad {
  MapRoad({
    required this.kind,
    required this.reference,
    required List<GeoPoint> points,
  }) : points = List.unmodifiable(points);
  factory MapRoad.fromJson(Json json) => MapRoad(
    kind: json.text('kind'),
    reference: json.text('ref'),
    points: json.array('coordinates').map(GeoPoint.fromJson).toList(),
  );
  final String kind, reference;
  final List<GeoPoint> points;
}

class MapPanel {
  const MapPanel(this.title, this.west, this.south, this.east, this.north);
  factory MapPanel.fromJson(Json json) {
    final b = json.array('bounds').cast<num>();
    return MapPanel(
      json.text('title'),
      b[0].toDouble(),
      b[1].toDouble(),
      b[2].toDouble(),
      b[3].toDouble(),
    );
  }
  final String title;
  final double west, south, east, north;
}

class MapLake {
  MapLake(List<List<List<GeoPoint>>> polygons)
    : polygons = List.unmodifiable(
        polygons.map(
          (p) => List<List<GeoPoint>>.unmodifiable(
            p.map(List<GeoPoint>.unmodifiable),
          ),
        ),
      );
  factory MapLake.fromJson(Json json) {
    final raw = json.array('coordinates');
    final polygons = json.text('type') == 'Polygon' ? [raw] : raw;
    return MapLake(
      polygons
          .map(
            (p) => (p! as List)
                .map((ring) => (ring! as List).map(GeoPoint.fromJson).toList())
                .toList(),
          )
          .toList(),
    );
  }
  final List<List<List<GeoPoint>>> polygons;
}

class MapDocument {
  MapDocument({
    required this.fetched,
    required List<MapRoad> roads,
    required Map<String, MapPlace> places,
    required Map<String, List<GeoPoint>> routes,
    required Map<String, String> aliases,
    required List<MapPanel> panels,
    required List<MapLake> lakes,
    List<MapPlace> roadLabels = const [],
  }) : roads = List.unmodifiable(roads),
       places = Map.unmodifiable(places),
       routes = Map.unmodifiable(
         routes.map((k, v) => MapEntry(k, List<GeoPoint>.unmodifiable(v))),
       ),
       aliases = Map.unmodifiable(aliases),
       panels = List.unmodifiable(panels),
       lakes = List.unmodifiable(lakes),
       roadLabels = List.unmodifiable(roadLabels);
  factory MapDocument.fromJson(Json json) => MapDocument(
    fetched: json.text('fetched'),
    roads: json.objects('roads').map(MapRoad.fromJson).toList(),
    places: json
        .object('points')
        .map((k, v) => MapEntry(k, MapPlace.fromJson(k, jsonObject(v)))),
    routes: json
        .object('routes')
        .map(
          (k, v) => MapEntry(
            k,
            jsonObject(v).array('coordinates').map(GeoPoint.fromJson).toList(),
          ),
        ),
    aliases: json.object('aliases').map((k, v) => MapEntry(k, v! as String)),
    panels: json.objects('panels').map(MapPanel.fromJson).toList(),
    lakes: json.objects('lakes').map(MapLake.fromJson).toList(),
    roadLabels: json
        .objects('roadLabels')
        .map((j) => MapPlace.fromJson(j.text('id'), j))
        .toList(),
  );
  final String fetched;
  final List<MapRoad> roads;
  final Map<String, MapPlace> places;
  final Map<String, List<GeoPoint>> routes;
  final Map<String, String> aliases;
  final List<MapPanel> panels;
  final List<MapLake> lakes;
  final List<MapPlace> roadLabels;
  String canonical(String name) => aliases[name] ?? name;
  List<GeoPoint>? road(String from, String to) {
    final a = canonical(from), b = canonical(to), forward = routes['$a|$b'];
    if (forward != null) return forward;
    return routes['$b|$a']?.reversed.toList(growable: false);
  }
}

class SelectedRoute {
  SelectedRoute({
    required this.dayId,
    required this.label,
    required this.color,
    required List<List<GeoPoint>> paths,
    required List<MapPlace> places,
    required List<String> gaps,
  }) : paths = List.unmodifiable(paths.map(List<GeoPoint>.unmodifiable)),
       places = List.unmodifiable(places),
       gaps = List.unmodifiable(gaps);
  final String dayId, label, color;
  final List<List<GeoPoint>> paths;
  final List<MapPlace> places;
  final List<String> gaps;
}

class MapProjection {
  const MapProjection();
  List<SelectedRoute> project(
    MapDocument map,
    TripVariant variant, {
    String? dayId,
  }) {
    final result = <SelectedRoute>[];
    for (final day in variant.days.where(
      (d) => dayId == null || d.id == dayId,
    )) {
      if (day.isPreparation) continue;
      if (variant.pending && !['9/28', '9/29'].contains(day.id)) continue;
      final groups = day.mapPaths.isNotEmpty ? day.mapPaths : [day.points];
      final paths = <List<GeoPoint>>[],
          places = <String, MapPlace>{},
          gaps = <String>[];
      for (final group in groups) {
        for (final name in group) {
          final p = map.places[map.canonical(name)];
          if (p != null) places[p.id] = p;
        }
        for (var i = 0; i < group.length - 1; i++) {
          if (map.canonical(group[i]) == map.canonical(group[i + 1])) continue;
          final road = map.road(group[i], group[i + 1]);
          if (road == null) {
            gaps.add('${group[i]} → ${group[i + 1]}');
          } else {
            paths.add(road);
          }
        }
      }
      result.add(
        SelectedRoute(
          dayId: day.id,
          label: day.label,
          color: day.color,
          paths: paths,
          places: places.values.toList(),
          gaps: gaps,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
