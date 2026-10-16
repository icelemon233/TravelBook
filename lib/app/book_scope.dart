import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/attractions/presentation/attractions_view_model.dart';
import '../features/books/domain/travel_book.dart';
import '../features/books/presentation/book_view_model.dart';
import '../features/budget/presentation/budget_view_model.dart';
import '../features/energy/presentation/energy_view_model.dart';
import '../features/export/presentation/actions_view_model.dart';
import '../features/itinerary/presentation/itinerary_view_model.dart';
import '../features/map/presentation/map_view_model.dart';
import '../features/preparation/presentation/preparation_view_model.dart';
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
      ChangeNotifierProvider(
        create: (c) => ItineraryViewModel(
          c.read<BookViewModel>(),
          dependencies.preferences,
        ),
      ),
      ChangeNotifierProvider(
        create: (c) =>
            BudgetViewModel(c.read<BookViewModel>(), dependencies.preferences),
      ),
      ChangeNotifierProvider(
        create: (c) => PreparationViewModel(
          c.read<BookViewModel>(),
          dependencies.preferences,
        ),
      ),
      ChangeNotifierProvider(
        create: (c) => AttractionsViewModel(
          c.read<BookViewModel>(),
          dependencies.preferences,
        ),
      ),
      ChangeNotifierProvider(
        create: (c) =>
            EnergyViewModel(c.read<BookViewModel>(), dependencies.preferences),
      ),
      ChangeNotifierProvider(create: (_) => RiskViewModel(book.risks)),
      ChangeNotifierProvider(
        create: (c) => MapViewModel(
          c.read<BookViewModel>(),
          dependencies.preferences,
          dependencies.trips,
        ),
      ),
      ChangeNotifierProvider(
        create: (c) => ActionsViewModel(
          files: dependencies.files,
          pdf: dependencies.pdf,
          preferences: dependencies.preferences,
          mapRenderer: dependencies.mapSnapshots,
          book: c.read<BookViewModel>(),
          budget: c.read<BudgetViewModel>(),
          map: c.read<MapViewModel>(),
        ),
      ),
    ],
    child: child,
  );
}
