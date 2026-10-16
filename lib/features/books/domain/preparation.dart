import '../../../core/json_values.dart';

class PreparationTask {
  const PreparationTask({
    required this.id,
    required this.title,
    required this.detail,
    required this.group,
  });
  factory PreparationTask.fromJson(Json json) => PreparationTask(
    id: json.text('id'),
    title: json.text('title'),
    detail: json.text('detail'),
    group: json.text('group'),
  );
  final String id, title, detail, group;
}

class TravelRisk {
  TravelRisk({
    required this.id,
    required this.scope,
    required this.title,
    required this.level,
    required this.reason,
    required this.action,
    required this.trigger,
    required this.category,
    required List<String> dates,
  }) : dates = List.unmodifiable(dates);
  factory TravelRisk.fromJson(Json json) => TravelRisk(
    id: json.text('id'),
    scope: json.text('scope'),
    title: json.text('title'),
    level: json.text('level'),
    reason: json.text('reason'),
    action: json.text('action'),
    trigger: json.text('trigger'),
    category: json.text('category'),
    dates: json.strings('dates'),
  );
  final String id, scope, title, level, reason, action, trigger, category;
  final List<String> dates;
}

class PermitStep {
  const PermitStep(this.date, this.title, this.description);
  factory PermitStep.fromJson(Json json) => PermitStep(
    json.text('date'),
    json.text('title'),
    json.text('description'),
  );
  final String date, title, description;
}
