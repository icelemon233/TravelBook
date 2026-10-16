import '../../../core/json_values.dart';

class BudgetField {
  const BudgetField({
    required this.id,
    required this.label,
    required this.unit,
    required this.group,
    required this.min,
    required this.max,
    required this.integer,
    required this.variantScoped,
    this.defaultValue,
  });
  factory BudgetField.fromJson(Json json) => BudgetField(
    id: json.text('id'),
    label: json.text('label'),
    unit: json.text('unit'),
    group: json.text('group'),
    min: json.number('min')?.toDouble() ?? 0,
    max: json.number('max')?.toDouble() ?? 1000000,
    integer: json.flag('integer'),
    variantScoped: json.flag('variantScoped'),
    defaultValue: json.number('defaultValue')?.toDouble(),
  );
  final String id, label, unit, group;
  final double min, max;
  final bool integer, variantScoped;
  final double? defaultValue;
  String? validate(double? value, {bool allowMissing = false}) {
    if (value == null) return allowMissing ? null : '请填写$label';
    if (!value.isFinite || value < min || value > max) {
      return '$label需在 $min–$max 之间';
    }
    if (integer && value != value.roundToDouble()) return '$label需为整数';
    return null;
  }
}
