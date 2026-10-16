import '../../books/domain/budget_field.dart';
import '../../books/domain/return_option.dart';
import '../../books/domain/travel_book.dart';
import 'budget_labels.dart';

class BudgetEstimate {
  BudgetEstimate({
    required Map<String, double> items,
    required this.subtotal,
    required this.reserve,
    required this.total,
    required this.perPerson,
    required List<String> missing,
    required Map<String, String> errors,
    this.days = 0,
    this.hotelNights = 0,
    this.carNights = 0,
    this.routeKm = 0,
    this.budgetKm = 0,
    this.driveKwh = 0,
    this.nightKwh = 0,
    this.purchasedKwh = 0,
  }) : items = Map.unmodifiable(items),
       missing = List.unmodifiable(missing),
       errors = Map.unmodifiable(errors);
  factory BudgetEstimate.invalid(Map<String, String> errors) => BudgetEstimate(
    items: const {},
    subtotal: 0,
    reserve: 0,
    total: 0,
    perPerson: 0,
    missing: const [],
    errors: errors,
  );
  final Map<String, double> items;
  final Map<String, String> errors;
  final List<String> missing;
  final double subtotal,
      reserve,
      total,
      perPerson,
      routeKm,
      budgetKm,
      driveKwh,
      nightKwh,
      purchasedKwh;
  final int days, hotelNights, carNights;
  bool get valid => errors.isEmpty;
  bool get complete => valid && missing.isEmpty;
}

class ReturnPlanEstimate {
  ReturnPlanEstimate({
    required this.option,
    required List<ReturnLeg> legs,
    required this.days,
    required this.firstDay,
    required this.km,
    required this.minutes,
    required this.tolls,
    required this.hotelNights,
    required this.carNights,
    required this.movedExtra,
  }) : legs = List.unmodifiable(legs);
  final ReturnOption option;
  final List<ReturnLeg> legs;
  final int days, firstDay, minutes, hotelNights, carNights;
  final double km, tolls;
  final bool movedExtra;
}

class ReturnComparison {
  ReturnComparison({
    required List<ReturnPlanEstimate> options,
    required this.delta,
    required this.dayDifference,
    required this.hotelDifference,
    required this.carDifference,
  }) : options = List.unmodifiable(options);
  final List<ReturnPlanEstimate> options;
  final double? delta;
  final int dayDifference, hotelDifference, carDifference;
}

class _CostDay {
  const _CostDay(this.km, this.mode);
  final double? km;
  final String mode;
}

class BudgetCalculator {
  const BudgetCalculator();
  static double money(double value) =>
      ((value + 2.220446049250313e-16) * 100).round() / 100;
  List<BudgetField> activeFields(TravelBook book, TripVariant variant) => book
      .budgetFields
      .where(
        (f) =>
            book.isGanwan ||
            f.id !=
                (variant.selectors['overnight'] == 'A'
                    ? 'hotel1003B'
                    : 'hotel1003A'),
      )
      .toList(growable: false);
  BudgetEstimate estimate(
    TravelBook book,
    TripVariant variant,
    Map<String, double?> inputs,
  ) {
    final errors = <String, String>{}, missing = <String>[];
    for (final field in activeFields(book, variant)) {
      final value = inputs[field.id];
      final allowMissing =
          !book.isGanwan &&
          (field.id.startsWith('hotel') || field.id == 'routeKm');
      final error = field.validate(value, allowMissing: allowMissing);
      if (error != null) errors[field.id] = error;
      if (value == null && allowMissing) {
        missing.add(budgetFieldLabel(book, variant, field));
      }
    }
    if (errors.isNotEmpty) return BudgetEstimate.invalid(errors);
    if (book.isGanwan) {
      return _ganwan(
        variant.days.map((d) => _CostDay(d.km, d.overnight.mode)).toList(),
        inputs,
      );
    }
    double n(String key) => inputs[key] ?? 0;
    final plan = variant.selectors['overnight'] ?? 'A';
    final hotels =
        n('rooms') *
            [
              'hotel0928',
              'hotel0929',
              'hotel0930',
              'hotel1001',
              'hotel1002',
              plan == 'A' ? 'hotel1003A' : 'hotel1003B',
            ].fold<double>(0, (sum, key) => sum + n(key)) +
        n('hotel1004');
    final items = {
      'car': n('cars') * n('days') * n('carDay'),
      'fuel': n('routeKm') * n('cars') * n('fuelUse') / 100 * n('fuelPrice'),
      'hotels': hotels,
      'meals': n('people') * n('mealDays') * n('meals'),
      'tickets': n('people') * n('ticketPerson') + n('extraTicket'),
      'insurance': n('people') * n('insurancePrice'),
      'supplies': 2500.0,
      'camera': n('pocket4p'),
    };
    final base = items.values.fold<double>(0, (a, b) => a + b),
        reserve = (base * n('reserve') / 100).roundToDouble();
    return BudgetEstimate(
      items: items,
      subtotal: base,
      reserve: reserve,
      total: base + reserve,
      perPerson: (base + reserve) / n('people'),
      missing: missing,
      errors: const {},
      days: variant.travelDayCount,
    );
  }

  BudgetEstimate _ganwan(List<_CostDay> days, Map<String, double?> v) {
    if (days.any((d) => d.km == null)) {
      return BudgetEstimate.invalid({'route': '驾驶核对数据不完整'});
    }
    double n(String key) => v[key] ?? 0;
    final hotelNights = days.where((d) => d.mode == 'hotel').length,
        carNights = days.where((d) => d.mode == 'car').length;
    final routeKm =
        (days.fold<double>(0, (s, d) => s + d.km!) * 10).round() / 10;
    final budgetKm = routeKm * (1 + n('detour') / 100),
        driveKwh = budgetKm * n('consumption') / 100,
        nightKwh = carNights * n('night-kwh');
    final purchasedKwh = (driveKwh + nightKwh) / (1 - n('loss') / 100);
    final items = {
      'hotel': money(hotelNights * n('rooms') * n('hotel-budget')),
      'food': money(days.length * n('people') * n('food')),
      'charging': money(purchasedKwh * n('electricity')),
      'tolls': money(n('tolls')),
      'tickets': money(n('tickets') * n('people')),
      'parking': money((hotelNights + carNights) * n('parking')),
      'other': money(n('other')),
    };
    final subtotal = money(items.values.fold<double>(0, (a, b) => a + b)),
        reserve = money(subtotal * n('contingency') / 100),
        total = money(subtotal + reserve);
    return BudgetEstimate(
      items: items,
      subtotal: subtotal,
      reserve: reserve,
      total: total,
      perPerson: money(total / n('people')),
      missing: const [],
      errors: const {},
      days: days.length,
      hotelNights: hotelNights,
      carNights: carNights,
      routeKm: routeKm,
      budgetKm: budgetKm,
      driveKwh: driveKwh,
      nightKwh: nightKwh,
      purchasedKwh: purchasedKwh,
    );
  }

  ReturnComparison? compareReturns(
    TravelBook book,
    TripVariant variant,
    Map<String, double?> inputs,
  ) {
    final data = book.returnOptions;
    if (data == null) return null;
    final summaries = <ReturnPlanEstimate>[], estimates = <BudgetEstimate>[];
    for (final option in data.options) {
      final prefix = variant.days
          .where(
            (d) => d.phase != '返程' && (option.id != 'loop' || d.id != 'extra'),
          )
          .toList();
      final legs = data.legsFor(option),
          tolls = legs.fold<double>(0, (s, l) => s + l.tolls);
      final days = [
        ...prefix.map((d) => _CostDay(d.km, d.overnight.mode)),
        ...legs.indexed.map((e) => _CostDay(e.$2.km, option.nightModes[e.$1])),
      ];
      summaries.add(
        ReturnPlanEstimate(
          option: option,
          legs: legs,
          days: days.length,
          firstDay: prefix.length + 1,
          km: (legs.fold<double>(0, (s, l) => s + l.km) * 10).round() / 10,
          minutes: legs.fold<int>(0, (s, l) => s + l.minutes),
          tolls: tolls,
          hotelNights: days.where((d) => d.mode == 'hotel').length,
          carNights: days.where((d) => d.mode == 'car').length,
          movedExtra:
              option.id == 'loop' && variant.days.any((d) => d.id == 'extra'),
        ),
      );
      estimates.add(
        estimate(book, variant, inputs).valid
            ? _ganwan(days, {...inputs, 'tolls': tolls})
            : BudgetEstimate.invalid({'budget': '请先填写有效预算'}),
      );
    }
    return ReturnComparison(
      options: summaries,
      delta: estimates.every((e) => e.valid)
          ? money(estimates[1].total - estimates[0].total)
          : null,
      dayDifference: summaries[1].days - summaries[0].days,
      hotelDifference: summaries[1].hotelNights - summaries[0].hotelNights,
      carDifference: summaries[1].carNights - summaries[0].carNights,
    );
  }
}
