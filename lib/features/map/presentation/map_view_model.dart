import 'dart:async';

import '../../books/domain/trip_repository.dart';
import '../../books/domain/travel_book.dart';
import '../../books/book_feature_view_model.dart';
import '../domain/map_snapshot_service.dart';
import '../domain/route_map.dart';

class MapViewModel extends BookFeatureViewModel {
  MapViewModel(super.bookModel, super.preferences, this.repository);
  final TripRepository repository;
  MapDocument? document;
  String? error, selectedDay;
  int? panel;
  bool loading = false, _disposed = false;
  Future<void>? _pendingLoad;
  (MapDocument?, String, String?)? _projectionKey;
  List<SelectedRoute> _routes = const [];
  List<SelectedRoute> get routes {
    final key = (document, variant.id, selectedDay);
    if (key != _projectionKey) {
      _projectionKey = key;
      _routes = document == null
          ? const []
          : const MapProjection().project(
              document!,
              variant,
              dayId: selectedDay,
            );
    }
    return _routes;
  }

  List<String> get gaps =>
      routes.expand((r) => r.gaps).toSet().toList(growable: false);
  Future<void> load() {
    if (_disposed || document != null) return Future.value();
    final pending = _pendingLoad;
    if (pending != null) return pending;
    loading = true;
    error = null;
    final work = Future<void>.microtask(_load);
    _pendingLoad = work;
    notifyListeners();
    return work;
  }

  Future<void> _load() async {
    try {
      final loaded = await repository.map(book.id);
      if (!_disposed) document = loaded;
    } catch (_) {
      if (!_disposed) error = '地图资源暂时无法读取，请重试。';
    }
    _pendingLoad = null;
    if (!_disposed) {
      loading = false;
      notifyListeners();
    }
  }

  Future<RouteMapSnapshot> snapshot({TripVariant? variant}) async {
    final selection = variant ?? this.variant;
    final day = variant == null ? selectedDay : null;
    final selectedPanel = variant == null ? panel : null;
    await load();
    final map = document;
    if (map == null) throw StateError(error ?? '地图尚未载入，请重试。');
    return RouteMapSnapshot(
      map,
      const MapProjection().project(map, selection, dayId: day),
      panel: selectedPanel,
    );
  }

  void selectDay(String? id) {
    selectedDay = variant.days.any((d) => d.id == id) ? id : null;
    notifyListeners();
  }

  void selectPanel(int? value) {
    panel = value;
    notifyListeners();
  }

  @override
  void onBookChanged() {
    if (!variant.days.any((d) => d.id == selectedDay)) selectedDay = null;
    super.onBookChanged();
  }

  @override
  void onPreferencesChanged() {} // A note or checklist change never reparses map geometry.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
