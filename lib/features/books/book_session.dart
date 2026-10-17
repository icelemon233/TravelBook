import 'package:flutter/foundation.dart';

import 'domain/travel_book.dart';

/// Read-only book selection shared by features within one open travel book.
abstract interface class BookSession implements Listenable {
  TravelBook get book;
  TripVariant get variant;
}
