import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/preferences_repository.dart';
import '../preferences_status.dart';

class PreferencesStatusViewModel extends ChangeNotifier
    implements PreferencesStatus {
  PreferencesStatusViewModel(this.repository) {
    _subscription = repository.changes.listen((_) => notifyListeners());
  }
  final PreferencesRepository repository;
  late final StreamSubscription<PreferencesSnapshot> _subscription;
  @override
  PreferencesSnapshot get state => repository.snapshot;
  @override
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
