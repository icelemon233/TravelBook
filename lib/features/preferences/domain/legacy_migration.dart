import 'dart:convert';

import '../../../core/json_values.dart';
import '../../books/domain/travel_book.dart';
import 'user_preferences.dart';

class LegacyMigration {
  const LegacyMigration();
  UserPreferences migrate(Map<String, String?> raw, List<TravelBook> books) {
    final result = <String, BookPreferences>{};
    final ganwan = raw['cinna-ganwan-v1'];
    if (ganwan != null) {
      final old = jsonObject(jsonDecode(ganwan)),
          book = books.firstWhere((b) => b.id == 'ganwan');
      final validDayIds = book.variants
          .expand((v) => v.days)
          .map((d) => d.id)
          .toSet();
      final notes = <String, String>{};
      for (final e in old.object('notes').entries) {
        if (validDayIds.contains(e.key) && e.value is String) {
          notes[e.key] = (e.value! as String).substring(
            0,
            (e.value! as String).length.clamp(0, 4000),
          );
        }
      }
      final checks = old.object('checks').map((k, v) => MapEntry(k, v == true));
      final values = old.object('inputs'),
          budget = <String, double?>{},
          energy = <String, String>{};
      for (final field in book.budgetFields) {
        final v = values[field.id];
        final n = v is num
            ? v.toDouble()
            : v is String
            ? double.tryParse(v)
            : null;
        if (n != null && field.validate(n) == null) budget[field.id] = n;
      }
      for (final id in [
        'range',
        'start-soc',
        'reserve-soc',
        'derate',
        'battery',
        'bed-soc',
        'night-use',
      ]) {
        if (values[id] is String) energy[id] = values[id]! as String;
      }
      final length = old['length'].toString();
      result['ganwan'] = BookPreferences(
        variantId: ['15', '16', '17'].contains(length) ? length : '16',
        notes: notes,
        checks: checks,
        budget: budget,
        energy: energy,
      );
    }
    final current = raw['tibet-checklist-personal-v2'],
        legacy = raw['tibet-checklist'];
    if (current != null || legacy != null) {
      final book = books.firstWhere((b) => b.id == 'tibet'),
          checks = <String, bool>{};
      if (current != null) {
        for (final e in jsonObject(jsonDecode(current)).entries) {
          if (book.tasks.any((t) => t.id == e.key)) {
            checks[e.key] = e.value == true;
          }
        }
      } else if (legacy != null) {
        final value = jsonDecode(legacy);
        for (final e in book.legacyTaskIds.indexed) {
          final id = e.$2;
          if (id == null) continue;
          final checked = value is List
              ? (e.$1 < value.length && value[e.$1] == true)
              : value is Map
              ? value[e.$1.toString()] == true
              : false;
          checks[id] = (checks[id] ?? false) || checked;
        }
      }
      result['tibet'] = BookPreferences(checks: checks);
    }
    return UserPreferences(books: result);
  }
}
