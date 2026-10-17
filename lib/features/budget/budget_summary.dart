import 'package:flutter/foundation.dart';

import 'domain/budget_calculator.dart';

abstract interface class BudgetSummary implements Listenable {
  BudgetEstimate get estimate;
  ReturnComparison? get returnComparison;
}
