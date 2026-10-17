import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../books/reference_actions.dart';

/// UI commands; platform adapters and cross-feature composition remain private.
abstract class ExportActions extends ChangeNotifier
    implements ReferenceActions {
  bool get busy;
  String? get error;
  String? get message;
  void clearMessage();
  Future<void> exportBackup({Rect? origin});
  Future<void> exportRecovery({Rect? origin});
  Future<void> importBackup();
  Future<void> importText(String source);
  Future<void> exportMap({Rect? origin});
  Future<void> exportPdf({bool print = false, Rect? origin});
}
