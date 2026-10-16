import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/page_components.dart';
import '../features/attractions/presentation/attractions_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/energy/presentation/energy_screen.dart';
import '../features/itinerary/presentation/itinerary_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/overview/presentation/overview_screen.dart';
import '../features/permits/presentation/permits_screen.dart';
import '../features/preparation/presentation/preparation_screen.dart';
import '../features/returns/presentation/returns_screen.dart';
import '../features/risks/presentation/risks_screen.dart';
import '../features/sources/presentation/sources_screen.dart';
import '../features/stays/presentation/stays_screen.dart';
import 'app_dependencies.dart';
import 'book_scope.dart';
import 'book_shell.dart';

GoRouter createRouter(
  AppDependencies dependencies, {
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/tibet', redirect: (_, _) => '/book/tibet/overview'),
    GoRoute(
      path: "/",
      builder: (_, _) => const LibraryScreen(),
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            final id = state.pathParameters['bookId'],
                book = dependencies.books[id];
            if (book == null) return const Scaffold(body: MissingPage());
            return BookScope(
              key: ValueKey(book.id),
              book: book,
              dependencies: dependencies,
              child: BookShell(
                section: state.pathParameters['section'] ?? 'overview',
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'book/:bookId/:section',
              builder: (context, state) {
                final section = state.pathParameters['section'],
                    book = dependencies.books[state.pathParameters['bookId']];
                if (book == null || !book.sections.contains(section)) {
                  return const MissingPage();
                }
                return switch (section) {
                  'overview' => const OverviewScreen(),
                  'itinerary' => ItineraryScreen(
                    initialDay: state.uri.queryParameters['day'],
                  ),
                  'map' => MapScreen(
                    initialDay: state.uri.queryParameters['day'],
                  ),
                  'attractions' => const AttractionsScreen(),
                  'stays' => const StaysScreen(),
                  'budget' => const BudgetScreen(),
                  'returns' => const ReturnsScreen(),
                  'energy' => const EnergyScreen(),
                  'checklist' => const PreparationScreen(),
                  'risks' => const RisksScreen(),
                  'permits' => const PermitsScreen(),
                  'sources' => const SourcesScreen(),
                  _ => const MissingPage(),
                };
              },
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (_, _) => const Scaffold(body: MissingPage()),
);

class MissingPage extends StatelessWidget {
  const MissingPage({super.key});
  @override
  Widget build(BuildContext context) => TravelPage(
    children: [
      const PageHeading(
        number: '404',
        title: '这页路书没有找到',
        description: '链接可能来自旧版本，返回目录选择一本路书继续。',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('返回路书目录'),
        ),
      ),
    ],
  );
}
