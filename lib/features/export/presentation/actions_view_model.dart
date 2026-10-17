import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/platform/file_actions.dart';
import '../../books/domain/reference.dart';
import '../../map/domain/map_snapshot_service.dart';
import '../../preferences/domain/backup_limits.dart';
import '../../preferences/domain/preferences_repository.dart';
import '../domain/travel_pdf_service.dart';
import '../domain/travel_report.dart';
import '../export_actions.dart';

class ActionsViewModel extends ExportActions {
  ActionsViewModel({
    required this.files,
    required this.pdf,
    required this.preferences,
    required this.mapRenderer,
    this.bookId,
    this.readReport,
    this.readMap,
  });
  final FileActions files;
  final TravelPdfService pdf;
  final PreferencesRepository preferences;
  final MapSnapshotService mapRenderer;
  final String? bookId;
  final ReportSnapshotReader? readReport;
  final MapSnapshotReader? readMap;
  @override
  bool busy = false;
  bool _disposed = false;
  @override
  String? error;
  @override
  String? message;
  String _name(String extension) =>
      'cinna-${bookId ?? 'travel-book'}-${DateTime.now().toIso8601String().substring(0, 10)}.$extension';
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

  @override
  void clearMessage() {
    error = null;
    message = null;
    notifyListeners();
  }

  @override
  Future<void> open(Reference reference) => _run(() async {
    final uri = reference.safeUri;
    if (uri == null) throw const FormatException('链接地址不受支持');
    await files.openLink(uri);
  });
  @override
  Future<void> exportBackup({Rect? origin}) => _run(() async {
    await preferences.flush();
    await files.save(
      Uint8List.fromList(utf8.encode(preferences.snapshot.value.backup())),
      _name('json'),
      'application/json',
      origin: origin,
    );
  }, success: '备份已交给系统保存／分享。');
  @override
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
  @override
  Future<void> importBackup() => _run(() async {
    final source = await files.pickBackup(maxBytes: BackupLimits.maxBytes);
    if (source != null) {
      await preferences.importBackup(source);
      message = '已导入备份。';
    }
  });
  @override
  Future<void> importText(String source) =>
      _run(() => preferences.importBackup(source), success: '已导入备份。');
  @override
  Future<void> exportMap({Rect? origin}) => _run(() async {
    final reader = readMap;
    if (reader == null) throw StateError('请先打开路书地图');
    final snapshot = await reader();
    final bytes = await mapRenderer.render(
      snapshot.document,
      snapshot.routes,
      panel: snapshot.panel,
    );
    await files.save(bytes, _name('png'), 'image/png', origin: origin);
  }, success: '当前筛选地图已交给系统保存／分享。');
  @override
  Future<void> exportPdf({bool print = false, Rect? origin}) => _run(() async {
    final reader = readReport;
    if (reader == null) throw StateError('请先打开一本路书');
    await preferences.flush();
    final report = reader();
    if (!report.budget.valid) {
      throw StateError('预算参数有待修正，请先检查旅行账本，再导出路书。');
    }
    Uint8List? mapImage;
    final mapReader = readMap;
    if (mapReader != null) {
      final snapshot = await mapReader(variant: report.variant);
      mapImage = await mapRenderer.render(snapshot.document, snapshot.routes);
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
