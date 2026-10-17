import '../../books/domain/travel_day.dart';
import '../../books/book_feature_view_model.dart';

class ItineraryViewModel extends BookFeatureViewModel {
  ItineraryViewModel(super.bookModel, super.preferences);
  String _phase = '全部', _query = '';
  String? _selectedDay;
  final _expanded = <String>{};
  int _expansionRevision = 0;
  String get phase => _phase;
  String get query => _query;
  String? get selectedDay => _selectedDay;
  int get expansionRevision => _expansionRevision;
  List<String> get phases => [
    '全部',
    ...variant.days.map((d) => d.phase).toSet(),
  ];
  List<TravelDay> get days => variant.days
      .where(
        (d) =>
            (_phase == '全部' || d.phase == _phase) &&
            (_selectedDay == null || d.id == _selectedDay) &&
            '${d.title} ${d.detail} ${d.geography}'.toLowerCase().contains(
              _query.toLowerCase(),
            ),
      )
      .toList(growable: false);
  String note(String id) =>
      preferences.snapshot.value.forBook(book.id).notes[id] ?? '';
  bool isExpanded(String id) => _expanded.contains(id) || id == _selectedDay;
  void filterPhase(String value) {
    _phase = value;
    _selectedDay = null;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  void focusDay(String? value) {
    _selectedDay = variant.days.any((d) => d.id == value) ? value : null;
    _phase = '全部';
    _query = '';
    _expansionRevision++;
    notifyListeners();
  }

  void expand(String id, bool value) {
    value ? _expanded.add(id) : _expanded.remove(id);
  }

  void toggleAll() {
    if (days.every((d) => isExpanded(d.id))) {
      _expanded.clear();
      _selectedDay = null;
    } else {
      _expanded.addAll(days.map((d) => d.id));
    }
    _expansionRevision++;
    notifyListeners();
  }

  Future<void> saveNote(String id, String text) =>
      preferences.updateBook(book.id, (p) => p.withNote(id, text));
  @override
  void onBookChanged() {
    _expansionRevision++;
    if (_selectedDay != null &&
        !variant.days.any((d) => d.id == _selectedDay)) {
      _selectedDay = null;
    }
    if (!phases.contains(_phase)) _phase = '全部';
    super.onBookChanged();
  }
}
