import '../../books/domain/trip_repository.dart';
import '../../books/presentation/book_view_model.dart';
import '../domain/route_map.dart';

class MapViewModel extends BookFeatureViewModel {
  MapViewModel(super.bookModel, super.preferences, this.repository);
  final TripRepository repository;
  MapDocument? document;
  String? error, selectedDay;
  int? panel;
  bool loading = false, _disposed = false;
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
  Future<void> load() async {
    if (loading || document != null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await repository.map(book.id);
      if (!_disposed) document = loaded;
    } catch (_) {
      if (!_disposed) error = '地图资源暂时无法读取，请重试。';
    }
    if (!_disposed) {
      loading = false;
      notifyListeners();
    }
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
