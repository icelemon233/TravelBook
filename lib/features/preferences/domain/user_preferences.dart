import 'dart:convert';

import 'package:characters/characters.dart';

import '../../../core/json_values.dart';
import 'backup_limits.dart';

class BookPreferences {
  BookPreferences({
    this.variantId,
    Map<String, String> notes = const {},
    Map<String, bool> checks = const {},
    Map<String, double?> budget = const {},
    Map<String, Map<String, double?>> variantBudgets = const {},
    Map<String, String> energy = const {},
  }) : notes = Map.unmodifiable(notes),
       checks = Map.unmodifiable(checks),
       budget = Map.unmodifiable(budget),
       variantBudgets = Map.unmodifiable(
         variantBudgets.map(
           (k, v) => MapEntry(k, Map<String, double?>.unmodifiable(v)),
         ),
       ),
       energy = Map.unmodifiable(energy);
  factory BookPreferences.fromJson(Json json) {
    String checkedText(Object? value, int limit) {
      if (value is! String || value.characters.length > limit) {
        throw const FormatException('Invalid saved text');
      }
      return value;
    }

    Map<String, double?> amounts(Json values) => values.map((k, v) {
      if (v != null && (v is! num || !v.isFinite || v.abs() > 1e9)) {
        throw const FormatException('Invalid saved amount');
      }
      return MapEntry(k, (v as num?)?.toDouble());
    });
    final notes = json.object('notes'), checks = json.object('checks');
    if (notes.length > 500 || checks.length > 500) {
      throw const FormatException('Too many saved entries');
    }
    if (checks.values.any((v) => v is! bool)) {
      throw const FormatException('Invalid checklist value');
    }
    return BookPreferences(
      variantId: json['variantId'] == null
          ? null
          : checkedText(json['variantId'], 100),
      notes: notes.map((k, v) => MapEntry(k, checkedText(v, 4000))),
      checks: checks.map((k, v) => MapEntry(k, v! as bool)),
      budget: amounts(json.object('budget')),
      variantBudgets: json
          .object('variantBudgets')
          .map((k, v) => MapEntry(k, amounts(jsonObject(v)))),
      energy: json
          .object('energy')
          .map((k, v) => MapEntry(k, checkedText(v, 64))),
    );
  }
  final String? variantId;
  final Map<String, String> notes, energy;
  final Map<String, bool> checks;
  final Map<String, double?> budget;
  final Map<String, Map<String, double?>> variantBudgets;
  BookPreferences copyWith({
    String? variantId,
    Map<String, String>? notes,
    Map<String, bool>? checks,
    Map<String, double?>? budget,
    Map<String, Map<String, double?>>? variantBudgets,
    Map<String, String>? energy,
  }) => BookPreferences(
    variantId: variantId ?? this.variantId,
    notes: notes ?? this.notes,
    checks: checks ?? this.checks,
    budget: budget ?? this.budget,
    variantBudgets: variantBudgets ?? this.variantBudgets,
    energy: energy ?? this.energy,
  );
  BookPreferences withNote(String id, String value) {
    if (value.characters.length > 4000) {
      throw const FormatException('备注最多4000字');
    }
    return copyWith(notes: {...notes, id: value});
  }

  BookPreferences withCheck(String id, bool value) =>
      copyWith(checks: {...checks, id: value});
  BookPreferences withBudget(String id, double? value, {String? variant}) =>
      variant == null
      ? copyWith(budget: {...budget, id: value})
      : copyWith(
          variantBudgets: {
            ...variantBudgets,
            variant: {...?variantBudgets[variant], id: value},
          },
        );
  BookPreferences resetBudget() =>
      copyWith(budget: const {}, variantBudgets: const {});
  Json toJson() => {
    'variantId': variantId,
    'notes': notes,
    'checks': checks,
    'budget': budget,
    'variantBudgets': variantBudgets,
    'energy': energy,
  };
}

class UserPreferences {
  UserPreferences({Map<String, BookPreferences> books = const {}})
    : books = Map.unmodifiable(books);
  factory UserPreferences.fromJson(Json json) {
    if (json.number('schemaVersion') != 1) {
      throw const FormatException('备份版本不受支持');
    }
    final books = json.object('books');
    if (books.length > 50) throw const FormatException('Too many travel books');
    return UserPreferences(
      books: books.map(
        (k, v) => MapEntry(k, BookPreferences.fromJson(jsonObject(v))),
      ),
    );
  }
  final Map<String, BookPreferences> books;
  BookPreferences forBook(String id) => books[id] ?? BookPreferences();
  UserPreferences update(String id, BookPreferences preferences) =>
      UserPreferences(books: {...books, id: preferences});
  Json toJson() => {
    'schemaVersion': 1,
    'books': books.map((k, v) => MapEntry(k, v.toJson())),
  };
  String backup() {
    final source = const JsonEncoder.withIndent('  ').convert({
      'format': 'cinna-travel-book',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': toJson(),
    });
    if (utf8.encode(source).length > BackupLimits.maxBytes) {
      throw const FormatException(BackupLimits.exceededMessage);
    }
    return source;
  }

  static UserPreferences import(String source) {
    if (utf8.encode(source).length > BackupLimits.maxBytes) {
      throw const FormatException(BackupLimits.exceededMessage);
    }
    final Json json;
    try {
      json = jsonObject(jsonDecode(source));
    } catch (_) {
      throw const FormatException('无法读取备份内容，请选择完整的备份文件。');
    }
    if (json.text('format') != 'cinna-travel-book' ||
        json.number('version') != 1) {
      throw const FormatException('请选择 TravelBook 备份文件');
    }
    try {
      return UserPreferences.fromJson(json.object('data'));
    } catch (_) {
      throw const FormatException('备份中的记录格式无效，原有资料未被替换。');
    }
  }
}
