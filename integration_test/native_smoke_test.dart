import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cinna_travel_book/app/app_dependencies.dart';
import 'package:cinna_travel_book/app/travel_app.dart';
import 'package:cinna_travel_book/features/map/domain/route_map.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native startup, actual preference storage and map renderer', (
    tester,
  ) async {
    final app = await AppDependencies.load();
    expect(
      app.preferences.snapshot.error,
      isNull,
      reason: 'Platform preference plugin must initialize successfully.',
    );
    final original = app.preferences.snapshot.value.backup();
    AppDependencies? reloaded;
    try {
      await tester.pumpWidget(
        TravelApp(
          dependencies: app,
          initialLocation: '/book/ganwan/itinerary?day=out-1',
        ),
      );
      await tester.pumpAndSettle();
      final note = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Day 1 个人备注',
      );
      await tester.ensureVisible(note);
      await tester.enterText(note, 'CI 原生存储验收备注');
      await tester.pumpAndSettle();
      await app.preferences.updateBook(
        'ganwan',
        (p) => p.withCheck('charge', true),
      );
      await app.preferences.flush();
      expect(app.preferences.snapshot.error, isNull);
      reloaded = await AppDependencies.load();
      expect(
        reloaded.preferences.snapshot.value.forBook('ganwan').notes['out-1'],
        'CI 原生存储验收备注',
      );
      expect(
        reloaded.preferences.snapshot.value.forBook('ganwan').checks['charge'],
        isTrue,
      );
      final document = await app.trips.map('ganwan'),
          variant = app.books['ganwan']!.defaultVariant;
      final png = await app.mapSnapshots.render(
        document,
        const MapProjection().project(document, variant, dayId: 'out-1'),
      );
      expect(png.length, greaterThan(10000));
      expect(png.take(4), [137, 80, 78, 71]);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await app.preferences.importBackup(original);
      await reloaded?.preferences.dispose();
      await app.preferences.dispose();
    }
  }, skip: !const bool.fromEnvironment('NATIVE_TEST_DISPOSABLE'));
}
