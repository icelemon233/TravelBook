import 'package:flutter/foundation.dart';

import 'domain/preferences_repository.dart';

abstract interface class PreferencesStatus implements Listenable {
  PreferencesSnapshot get state;
  String get label;
}
