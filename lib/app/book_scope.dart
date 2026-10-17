import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/attractions/presentation/attractions_view_model.dart';
import '../features/books/domain/travel_book.dart';
import '../features/books/book_session.dart';
import '../features/books/reference_actions.dart';
import '../features/books/presentation/book_view_model.dart';
import '../features/budget/budget_summary.dart';
import '../features/budget/presentation/budget_view_model.dart';
import '../features/energy/presentation/energy_view_model.dart';
import '../features/export/presentation/actions_view_model.dart';
import '../features/export/domain/travel_report.dart';
import '../features/export/export_actions.dart';
import '../features/itinerary/presentation/itinerary_view_model.dart';
import '../features/map/presentation/map_view_model.dart';
import '../features/preparation/presentation/preparation_view_model.dart';
import '../features/preparation/preparation_progress.dart';
import '../features/risks/presentation/risk_view_model.dart';
import 'app_dependencies.dart';

class BookScope extends StatelessWidget {
  const BookScope({
    super.key,
    required this.book,
    required this.dependencies,
    required this.child,
  });
  final TravelBook book;
  final AppDependencies dependencies;
  final Widget child;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => BookViewModel(book, dependencies.preferences),
      ),
      ListenableProvider<BookSession>(create: (c) => c.read<BookViewModel>()),
      ChangeNotifierProvider(
        create: (c) =>
            ItineraryViewModel(c.read<BookSession>(), dependencies.preferences),
      ),
      ChangeNotifierProvider(
        create: (c) =>
            BudgetViewModel(c.read<BookSession>(), dependencies.preferences),
      ),
      ListenableProvider<BudgetSummary>(
        create: (c) => c.read<BudgetViewModel>(),
      ),
      ChangeNotifierProvider(
        create: (c) => PreparationViewModel(
          c.read<BookSession>(),
          dependencies.preferences,
        ),
      ),
      ListenableProvider<PreparationProgress>(
        create: (c) => c.read<PreparationViewModel>(),
      ),
      ChangeNotifierProvider(
        create: (c) => AttractionsViewModel(
          c.read<BookSession>(),
          dependencies.preferences,
        ),
      ),
      ChangeNotifierProvider(
        create: (c) =>
            EnergyViewModel(c.read<BookSession>(), dependencies.preferences),
      ),
      ChangeNotifierProvider(create: (_) => RiskViewModel(book.risks)),
      ChangeNotifierProvider(
        create: (c) => MapViewModel(
          c.read<BookSession>(),
          dependencies.preferences,
          dependencies.trips,
        ),
      ),
      ChangeNotifierProvider<ExportActions>(
        create: (c) {
          final session = c.read<BookSession>();
          final budget = c.read<BudgetSummary>();
          final map = c.read<MapViewModel>();
          return ActionsViewModel(
            files: dependencies.files,
            pdf: dependencies.pdf,
            preferences: dependencies.preferences,
            mapRenderer: dependencies.mapSnapshots,
            bookId: book.id,
            readReport: () => TravelReport(
              book: session.book,
              variant: session.variant,
              budget: budget.estimate,
              preferences: dependencies.preferences.snapshot.value.forBook(
                book.id,
              ),
            ),
            readMap: map.snapshot,
          );
        },
      ),
      Provider<ReferenceActions>(create: (c) => c.read<ExportActions>()),
    ],
    child: child,
  );
}
