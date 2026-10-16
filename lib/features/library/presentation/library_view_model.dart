import 'package:flutter/foundation.dart';

import '../../books/domain/travel_book.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(List<BookSummary> books) : _books = List.unmodifiable(books);
  final List<BookSummary> _books;
  String _query = '';
  List<BookSummary> get books => _books
      .where(
        (b) => '${b.title} ${b.subtitle} ${b.description}'
            .toLowerCase()
            .contains(_query.toLowerCase()),
      )
      .toList(growable: false);
  void search(String value) {
    _query = value;
    notifyListeners();
  }
}
