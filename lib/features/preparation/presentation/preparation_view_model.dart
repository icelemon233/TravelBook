import '../../books/domain/preparation.dart';
import '../../books/presentation/book_view_model.dart';

class PreparationViewModel extends BookFeatureViewModel {
  PreparationViewModel(super.bookModel, super.preferences);
  bool _onlyIncomplete = false;
  String _query = '';
  String? focusedTask;
  bool get onlyIncomplete => _onlyIncomplete;
  List<String> get groups =>
      book.tasks.map((t) => t.group).toSet().toList(growable: false);
  bool checked(String id) =>
      preferences.snapshot.value.forBook(book.id).checks[id] == true;
  int get completed => book.tasks.where((t) => checked(t.id)).length;
  int get total => book.tasks.length;
  List<PreparationTask> tasks(String group) => book.tasks
      .where(
        (t) =>
            t.group == group &&
            (!_onlyIncomplete || !checked(t.id)) &&
            '${t.title} ${t.detail}'.contains(_query),
      )
      .toList(growable: false);
  void filterIncomplete(bool value) {
    _onlyIncomplete = value;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> toggle(String id, bool value) =>
      preferences.updateBook(book.id, (p) => p.withCheck(id, value));
  String? jumpNext() {
    final next = book.tasks.where((t) => !checked(t.id)).firstOrNull;
    focusedTask = next?.id;
    _query = '';
    notifyListeners();
    return next?.group;
  }
}
