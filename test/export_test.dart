import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/budget/domain/budget_calculator.dart';
import 'package:cinna_travel_book/features/export/data/travel_pdf_service.dart';
import 'package:cinna_travel_book/features/export/domain/travel_report.dart';
import 'package:cinna_travel_book/features/map/domain/route_map.dart';
import 'package:cinna_travel_book/features/map/presentation/route_map_painter.dart';
import 'package:cinna_travel_book/features/preferences/domain/user_preferences.dart';

import 'support.dart';

class FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = AssetTripRepository(FileAssets()), bundle = FileBundle();
  final outputs = Directory('.local/export-check');
  setUpAll(() async {
    outputs.createSync(recursive: true);
    final loader = FontLoader('NotoSansSC')
      ..addFont(bundle.load('assets/fonts/NotoSansSC-Regular.ttf'));
    await loader.load();
  });
  test('actual cached roads produce a full resolution PNG with date and attribution', () async {
    final book = await repository.book('ganwan'),
        map = await repository.map('ganwan');
    final bytes = await const MapImageRenderer().render(
      map,
      const MapProjection().project(map, book.defaultVariant, dayId: 'yaoli'),
    );
    final codec = await ui.instantiateImageCodec(bytes),
        frame = await codec.getNextFrame();
    expect(frame.image.width, 1600);
    expect(frame.image.height, 1100);
    expect(bytes.length, greaterThan(10000));
    frame.image.dispose();
    codec.dispose();
    File('${outputs.path}/ganwan-map.png').writeAsBytesSync(bytes);
  });
  test(
    'actual Chinese PDF output handles long notes and uncertain permit budgets',
    () async {
      final pdf = BundledTravelPdfService(bundle);
      for (final id in ['ganwan', 'tibet']) {
        final book = await repository.book(id),
            variant = book.variant(id == 'tibet' ? 'C_a_A' : '16');
        final report = TravelReport(
          book: book,
          variant: variant,
          budget: const BudgetCalculator().estimate(
            book,
            variant,
            variant.budgetDefaults,
          ),
          preferences: BookPreferences(
            notes: {
              variant.days.first.id: List.filled(
                220,
                '导出验收备注，个人记录需要完整分页。',
              ).join(),
            },
            checks: {book.tasks.first.id: true},
          ),
        );
        final map = await repository.map(id),
            image = await const MapImageRenderer().render(
              map,
              const MapProjection().project(map, variant),
            );
        final bytes = await pdf.generate(report, mapImage: image);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        expect(bytes.length, greaterThan(15000));
        File('${outputs.path}/$id.pdf').writeAsBytesSync(bytes);
      }
    },
  );
}
