import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../preferences/domain/preferences_repository.dart';
import '../domain/travel_book.dart';
import '../book_session.dart';

class BookViewModel extends ChangeNotifier implements BookSession {
  BookViewModel(this.book, this.preferences) {
    _variant = book.variant(
      preferences.snapshot.value.forBook(book.id).variantId,
    );
    _subscription = preferences.changes.listen((snapshot) {
      final next = book.variant(snapshot.value.forBook(book.id).variantId);
      if (next.id != _variant.id) {
        _variant = next;
        notifyListeners();
      }
    });
  }
  @override
  final TravelBook book;
  final PreferencesRepository preferences;
  late TripVariant _variant;
  late final StreamSubscription<PreferencesSnapshot> _subscription;
  @override
  TripVariant get variant => _variant;
  List<TripSelector> get selectors => book.selectors
      .where((selector) => selector.visibleFor(_variant))
      .toList(growable: false);
  String get selectionCaption => book.selectionTag.isEmpty
      ? _variant.label
      : '${book.selectionTag} · ${_variant.label}';
  Future<void> select(String key, String value) async {
    final next = book.select(_variant, key, value);
    await preferences.updateBook(
      book.id,
      (p) => p.copyWith(variantId: next.id),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
