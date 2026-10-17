import 'dart:async';

import 'package:flutter/foundation.dart';

import '../preferences/domain/preferences_repository.dart';
import 'book_session.dart';
import 'domain/travel_book.dart';

abstract class BookFeatureViewModel extends ChangeNotifier {
  BookFeatureViewModel(this.bookModel, this.preferences) {
    bookModel.addListener(onBookChanged);
    _subscription = preferences.changes.listen((_) => onPreferencesChanged());
  }
  final BookSession bookModel;
  final PreferencesRepository preferences;
  late final StreamSubscription<PreferencesSnapshot> _subscription;
  TravelBook get book => bookModel.book;
  TripVariant get variant => bookModel.variant;
  void onBookChanged() => notifyListeners();
  void onPreferencesChanged() => notifyListeners();
  @override
  void dispose() {
    bookModel.removeListener(onBookChanged);
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
