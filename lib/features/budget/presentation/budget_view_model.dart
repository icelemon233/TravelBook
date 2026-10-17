import '../../books/domain/budget_field.dart';
import '../../books/book_feature_view_model.dart';
import '../budget_summary.dart';
import '../domain/budget_calculator.dart';
import '../domain/budget_labels.dart';

class BudgetViewModel extends BookFeatureViewModel implements BudgetSummary {
  BudgetViewModel(
    super.bookModel,
    super.preferences, {
    this.calculator = const BudgetCalculator(),
  }) : _replacementRevision = preferences.snapshot.replacementRevision;
  final BudgetCalculator calculator;
  int _replacementRevision;
  final _drafts = <String, String>{};
  List<BudgetField> get fields => calculator.activeFields(book, variant);
  List<String> get groups =>
      fields.map((f) => f.group).toSet().toList(growable: false);
  Map<String, double?> get values {
    final saved = preferences.snapshot.value.forBook(book.id);
    final result = {
      ...variant.budgetDefaults,
      ...saved.budget,
      ...?saved.variantBudgets[variant.budgetScopeId],
    };
    for (final e in _drafts.entries) {
      result[e.key] = e.value.trim().isEmpty
          ? null
          : double.tryParse(e.value) ?? double.nan;
    }
    return Map.unmodifiable(result);
  }

  @override
  BudgetEstimate get estimate => calculator.estimate(book, variant, values);
  @override
  ReturnComparison? get returnComparison =>
      calculator.compareReturns(book, variant, values);
  String input(BudgetField field) {
    if (_drafts.containsKey(field.id)) return _drafts[field.id]!;
    final v = values[field.id];
    return v == null
        ? ''
        : v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString();
  }

  String label(BudgetField field) => budgetFieldLabel(book, variant, field);
  String? error(BudgetField field) => estimate.errors[field.id];
  Future<void> edit(BudgetField field, String raw) async {
    _drafts[field.id] = raw;
    notifyListeners();
    final value = raw.trim().isEmpty ? null : double.tryParse(raw);
    if (raw.trim().isNotEmpty && (value == null || !value.isFinite)) return;
    if (error(field) != null) return;
    await preferences.updateBook(
      book.id,
      (p) => p.withBudget(
        field.id,
        value,
        variant: field.variantScoped ? variant.budgetScopeId : null,
      ),
    );
  }

  Future<void> reset() async {
    _drafts.clear();
    await preferences.updateBook(book.id, (p) => p.resetBudget());
  }

  @override
  void onPreferencesChanged() {
    final revision = preferences.snapshot.replacementRevision;
    if (revision != _replacementRevision) {
      _replacementRevision = revision;
      _drafts.clear();
    }
    super.onPreferencesChanged();
  }

  @override
  void onBookChanged() {
    _drafts.clear();
    super.onBookChanged();
  }
}
