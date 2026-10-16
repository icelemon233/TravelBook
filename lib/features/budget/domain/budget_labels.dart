import '../../books/domain/budget_field.dart';
import '../../books/domain/travel_book.dart';

String budgetFieldLabel(
  TravelBook book,
  TripVariant variant,
  BudgetField field,
) {
  if (!book.isGanwan &&
      field.id.startsWith('hotel') &&
      field.id != 'hotel1004') {
    final suffix = field.id.substring(5),
        date =
            '${int.parse(suffix.substring(0, 2))}/${int.parse(suffix.substring(2, 4))}';
    final day = variant.days.where((d) => d.id == date).firstOrNull;
    if (day != null) return '$date ${day.overnight.title} / 间';
  }
  return field.label;
}
