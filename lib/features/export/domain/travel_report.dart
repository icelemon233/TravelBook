import '../../books/domain/travel_book.dart';
import '../../budget/domain/budget_calculator.dart';
import '../../preferences/domain/user_preferences.dart';

typedef ReportSnapshotReader = TravelReport Function();

class TravelReport {
  const TravelReport({
    required this.book,
    required this.variant,
    required this.budget,
    required this.preferences,
  });
  final TravelBook book;
  final TripVariant variant;
  final BudgetEstimate budget;
  final BookPreferences preferences;
}
