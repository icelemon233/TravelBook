import 'dart:typed_data';
import 'dart:ui';

import 'package:cinna_travel_book/core/platform/file_actions.dart';
import 'package:cinna_travel_book/features/export/domain/travel_pdf_service.dart';
import 'package:cinna_travel_book/features/export/domain/travel_report.dart';
import 'package:cinna_travel_book/features/map/domain/map_snapshot_service.dart';
import 'package:cinna_travel_book/features/map/domain/route_map.dart';

class FakeFileActions implements FileActions {
  String? nextBackup;
  int? lastPickMaxBytes;
  final saved = <({String name, String mime, Uint8List bytes})>[];
  final opened = <Uri>[];
  @override
  Future<void> openLink(Uri uri) async {
    opened.add(uri);
  }

  @override
  Future<String?> pickBackup({required int maxBytes}) async {
    lastPickMaxBytes = maxBytes;
    return nextBackup;
  }

  @override
  Future<void> printPdf(Uint8List bytes, String name) async {
    saved.add((name: name, mime: 'print', bytes: bytes));
  }

  @override
  Future<void> save(
    Uint8List bytes,
    String name,
    String mime, {
    Rect? origin,
  }) async {
    saved.add((name: name, mime: mime, bytes: bytes));
  }
}

class FakePdfService implements TravelPdfService {
  TravelReport? lastReport;
  @override
  Future<Uint8List> generate(TravelReport report, {Uint8List? mapImage}) async {
    lastReport = report;
    return Uint8List.fromList('%PDF-test-double'.codeUnits);
  }
}

class FakeMapSnapshots implements MapSnapshotService {
  @override
  Future<Uint8List> render(
    MapDocument document,
    List<SelectedRoute> routes, {
    int? panel,
  }) async => Uint8List.fromList([137, 80, 78, 71]);
}
