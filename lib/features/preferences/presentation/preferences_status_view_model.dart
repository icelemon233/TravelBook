import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/preferences_repository.dart';

class PreferencesStatusViewModel extends ChangeNotifier {
  PreferencesStatusViewModel(this.repository) {
    _subscription = repository.changes.listen((_) => notifyListeners());
  }
  final PreferencesRepository repository;
  late final StreamSubscription<PreferencesSnapshot> _subscription;
  PreferencesSnapshot get state => repository.snapshot;
  String get label => state.error != null
      ? '保存需处理'
      : state.saving
      ? '正在保存…'
      : '已保存到本设备';
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
