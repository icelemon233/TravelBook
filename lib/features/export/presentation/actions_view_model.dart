import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/platform/file_actions.dart';
import '../../books/domain/reference.dart';
import '../../books/presentation/book_view_model.dart';
import '../../budget/domain/budget_calculator.dart';
import '../../budget/presentation/budget_view_model.dart';
import '../../map/domain/route_map.dart';
import '../../map/presentation/map_view_model.dart';
import '../../map/domain/map_snapshot_service.dart';
import '../../preferences/domain/preferences_repository.dart';
import '../domain/travel_pdf_service.dart';
import '../domain/travel_report.dart';

class ActionsViewModel extends ChangeNotifier {
  ActionsViewModel({
    required this.files,
    required this.pdf,
    required this.preferences,
    required this.mapRenderer,
    this.book,
    this.budget,
    this.map,
  });
  final FileActions files;
  final TravelPdfService pdf;
  final PreferencesRepository preferences;
  final MapSnapshotService mapRenderer;
  final BookViewModel? book;
  final BudgetViewModel? budget;
  final MapViewModel? map;
  bool busy = false, _disposed = false;
  String? error, message;
  String _name(String extension) =>
      'cinna-${book?.book.id ?? 'travel-book'}-${DateTime.now().toIso8601String().substring(0, 10)}.$extension';
  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (busy) return;
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      await action();
      if (success != null) message = success;
    } catch (e) {
      error = e is FormatException
          ? e.message.toString()
          : e is StateError
          ? e.message.toString()
          : '操作未完成，请重试。';
    }
    if (!_disposed) {
      busy = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    error = null;
    message = null;
    notifyListeners();
  }

  Future<void> open(Reference reference) => _run(() async {
    final uri = reference.safeUri;
    if (uri == null) throw const FormatException('链接地址不受支持');
    await files.openLink(uri);
  });
  Future<void> exportBackup({Rect? origin}) => _run(() async {
    await preferences.flush();
    await files.save(
      Uint8List.fromList(utf8.encode(preferences.snapshot.value.backup())),
      _name('json'),
      'application/json',
      origin: origin,
    );
  }, success: '备份已交给系统保存／分享。');
  Future<void> exportRecovery({Rect? origin}) => _run(() async {
    final raw = preferences.snapshot.recoveryRaw;
    if (raw == null) return;
    await files.save(
      Uint8List.fromList(utf8.encode(raw)),
      'cinna-recovery-original.txt',
      'text/plain',
      origin: origin,
    );
  });
  Future<void> importBackup() => _run(() async {
    final source = await files.pickBackup();
    if (source != null) {
      await preferences.importBackup(source);
      message = '已导入备份。';
    }
  });
  Future<void> importText(String source) =>
      _run(() => preferences.importBackup(source), success: '已导入备份。');
  Future<void> exportMap({Rect? origin}) => _run(() async {
    final model = map;
    if (model == null) throw StateError('请先打开路书地图');
    await model.load();
    if (model.document == null) throw StateError(model.error ?? '地图尚未载入');
    final bytes = await mapRenderer.render(
      model.document!,
      model.routes,
      panel: model.panel,
    );
    await files.save(bytes, _name('png'), 'image/png', origin: origin);
  }, success: '当前筛选地图已交给系统保存／分享。');
  Future<void> exportPdf({bool print = false, Rect? origin}) => _run(() async {
    final model = book;
    if (model == null) throw StateError('请先打开一本路书');
    await preferences.flush();
    final personal = preferences.snapshot.value.forBook(model.book.id),
        variant = model.variant;
    final values = {
      ...variant.budgetDefaults,
      ...personal.budget,
      ...?personal.variantBudgets[variant.budgetScopeId],
    };
    final quote =
        budget?.estimate ??
        const BudgetCalculator().estimate(model.book, variant, values);
    if (!quote.valid) throw StateError('预算参数有待修正，请先检查旅行账本，再导出路书。');
    final report = TravelReport(
      book: model.book,
      variant: variant,
      budget: quote,
      preferences: personal,
    );
    Uint8List? mapImage;
    final mapModel = map;
    if (mapModel != null) {
      await mapModel.load();
      if (mapModel.document != null) {
        mapImage = await mapRenderer.render(
          mapModel.document!,
          const MapProjection().project(mapModel.document!, variant),
        );
      }
    }
    final bytes = await pdf.generate(report, mapImage: mapImage);
    if (print) {
      await files.printPdf(bytes, _name('pdf'));
    } else {
      await files.save(bytes, _name('pdf'), 'application/pdf', origin: origin);
    }
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
