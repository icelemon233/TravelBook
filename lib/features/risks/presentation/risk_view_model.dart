import 'package:flutter/foundation.dart';

import '../../books/domain/preparation.dart';

class RiskViewModel extends ChangeNotifier {
  RiskViewModel(List<TravelRisk> risks) : _all = List.unmodifiable(risks);
  final List<TravelRisk> _all;
  String date = '全部', level = '全部', category = '全部', query = '';
  bool highFirst = true;
  List<String> get dates => ['全部', ..._all.expand((r) => r.dates).toSet()];
  List<String> get categories => ['全部', ..._all.map((r) => r.category).toSet()];
  List<TravelRisk> get risks {
    final values = _all
        .where(
          (r) =>
              (date == '全部' || r.dates.contains(date)) &&
              (level == '全部' || r.level == level) &&
              (category == '全部' || r.category == category) &&
              '${r.id} ${r.title} ${r.reason} ${r.action} ${r.trigger}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    int rank(String level) => switch (level) {
      '高' => 3,
      '中' => 2,
      _ => 1,
    };
    values.sort((a, b) {
      final diff = rank(b.level) - rank(a.level);
      return diff == 0
          ? a.id.compareTo(b.id)
          : highFirst
          ? diff
          : -diff;
    });
    return List.unmodifiable(values);
  }

  void update({
    String? date,
    String? level,
    String? category,
    String? query,
    bool? highFirst,
  }) {
    this.date = date ?? this.date;
    this.level = level ?? this.level;
    this.category = category ?? this.category;
    this.query = query ?? this.query;
    this.highFirst = highFirst ?? this.highFirst;
    notifyListeners();
  }

  void reset() {
    date = '全部';
    level = '全部';
    category = '全部';
    query = '';
    highFirst = true;
    notifyListeners();
  }
}
