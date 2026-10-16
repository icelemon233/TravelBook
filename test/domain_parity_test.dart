import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cinna_travel_book/core/json_values.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/budget/domain/budget_calculator.dart';
import 'package:cinna_travel_book/features/energy/domain/energy_calculator.dart';
import 'package:cinna_travel_book/features/map/domain/route_map.dart';

import 'support.dart';

void main() {
  final repository = AssetTripRepository(FileAssets());
  const calculator = BudgetCalculator();
  late TravelBook ganwan, tibet;
  setUpAll(() async {
    ganwan = await repository.book('ganwan');
    tibet = await repository.book('tibet');
  });
  test(
    'both travel books preserve complete variant and preparation inventories',
    () {
      expect(ganwan.variants.length, 3);
      expect(tibet.variants.length, 30);
      expect(ganwan.attractions.expand((g) => g.spots).length, 12);
      expect(tibet.tasks.length, 48);
      expect(tibet.tasks.map((t) => t.id).toSet().length, 48);
      expect(tibet.risks.length, 14);
      for (final book in [ganwan, tibet]) {
        for (final photo in book.photos) {
          expect(File(photo.asset).existsSync(), isTrue, reason: photo.asset);
        }
      }
      expect(
        ganwan.variant('15').days.any((d) => d.id == 'taohuatan'),
        isFalse,
      );
      expect(ganwan.variant('17').days.any((d) => d.id == 'extra'), isTrue);
      expect(
        ganwan.defaultVariant.days.first.overnight.backup?.title,
        contains('维也纳'),
      );
    },
  );
  final cases = (jsonDecode(
    File('test/fixtures/legacy-budget-parity.json').readAsStringSync(),
  ) as List).map(jsonObject);
  for (final c in cases) {
    test(
      'legacy budget parity ${c.text('kind')} ${c.text('variant')} ${c.object('inputs')['people']}',
      () {
        final book = c.text('kind') == 'ganwan' ? ganwan : tibet,
            variant = book.variant(c.text('variant'));
        final input = c
                .object('inputs')
                .map((k, v) => MapEntry(k, (v as num?)?.toDouble())),
            expected = c.object('expected');
        final actual = calculator.estimate(book, variant, input);
        expect(actual.valid, isTrue);
        expect(
          actual.total,
          closeTo(expected.number('total')!.toDouble(), 1e-6),
        );
        expect(
          actual.reserve,
          closeTo(expected.number('reserve')!.toDouble(), 1e-6),
        );
        expect(
          actual.perPerson,
          closeTo(
            expected.number(book.isGanwan ? 'perPerson' : 'per')!.toDouble(),
            1e-6,
          ),
        );
        final items = book.isGanwan ? expected.object('items') : expected;
        for (final e in actual.items.entries) {
          expect(
            e.value,
            closeTo(items.number(e.key)!.toDouble(), 1e-6),
            reason: e.key,
          );
        }
        if (book.isGanwan) {
          expect(actual.routeKm, expected.number('routeKm'));
          expect(actual.hotelNights, expected.number('hotelNights'));
          final comparison = calculator.compareReturns(book, variant, input)!,
              diff = c.object('returnDifference');
          expect(
            comparison.delta,
            closeTo(diff.number('delta')!.toDouble(), 1e-6),
          );
          expect(comparison.dayDifference, diff.number('days'));
        } else {
          expect(actual.complete, isFalse);
          expect(actual.missing, contains('当前路线总里程（km，待核实）'));
        }
      },
    );
  }
  test('invalid budgets are rejected and reserve is included exactly once', () {
    final v = ganwan.defaultVariant, inputs = v.budgetDefaults;
    expect(
      calculator.estimate(ganwan, v, {...inputs, 'people': 1.5}).valid,
      isFalse,
    );
    expect(
      calculator.estimate(ganwan, v, {...inputs, 'loss': 100}).valid,
      isFalse,
    );
    final quote = calculator.estimate(ganwan, v, inputs);
    expect(quote.total, BudgetCalculator.money(quote.subtotal + quote.reserve));
  });
  test('17 day western loop moves the extra day; comparison ignores shared outbound toll assumptions', () {
    final v = ganwan.variant('17'),
        a = calculator.compareReturns(ganwan, v, v.budgetDefaults)!;
    final b = calculator.compareReturns(ganwan, v, {
      ...v.budgetDefaults,
      'tolls': 9000,
    })!;
    expect(a.options.last.days, 17);
    expect(a.options.last.movedExtra, isTrue);
    expect(a.delta, b.delta);
  });
  test('range and overnight calculations preserve unknown inputs', () {
    const c = EnergyCalculator();
    expect(c.range(range: 300, start: 90, reserve: 20, derate: 15), 178.5);
    expect(c.range(range: 300, start: 10, reserve: 20, derate: 15), isNull);
    expect(c.morning(battery: null, soc: 80, use: 6), isNull);
    expect(c.morning(battery: 60, soc: 80, use: 6), 70);
    expect(c.morning(battery: 60, soc: 10, use: 12), -10);
  });
  test('cached map geometry is real, reversible, and pending permit routes retain gaps', () async {
    final map = await repository.map('tibet'),
        forward = map.road('拉萨', '日喀则')!,
        reverse = map.road('日喀则', '拉萨')!;
    expect(forward.length, greaterThan(10));
    expect(reverse.first.longitude, forward.last.longitude);
    final pending = const MapProjection().project(map, tibet.variant('C_a_A'));
    expect(pending.map((r) => r.dayId), everyElement(isIn(['9/28', '9/29'])));
    final a = const MapProjection().project(map, tibet.variant('A_a_A'));
    expect(a.expand((r) => r.gaps), isNotEmpty);
    final g = await repository.map('ganwan');
    expect(g.roads.length, greaterThan(4000));
    expect(
      const MapProjection().project(
        g,
        ganwan.variant('15'),
        dayId: 'taohuatan',
      ),
      isEmpty,
    );
  });
}
