import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cinna_travel_book/core/ui/page_components.dart';
import 'package:cinna_travel_book/app/app_dependencies.dart';
import 'package:cinna_travel_book/app/book_shell.dart';
import 'package:cinna_travel_book/app/travel_app.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/library/presentation/library_screen.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';

import 'platform_fakes.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = AssetTripRepository(FileAssets());
  late List<TravelBook> books;
  late List<BookSummary> catalog;
  setUpAll(() async {
    catalog = await repository.catalog();
    books = await loadBooks(repository);
    await repository.map('ganwan');
    await repository.map('tibet');
  });
  Future<AppDependencies> dependencies() async {
    final preferences = LocalPreferencesRepository(
      MemoryPreferencesStore(),
      LegacyValues(),
    );
    await preferences.initialize(books);
    return AppDependencies(
      trips: repository,
      preferences: preferences,
      files: FakeFileActions(),
      pdf: FakePdfService(),
      mapSnapshots: FakeMapSnapshots(),
      catalog: catalog,
      books: books,
    );
  }

  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  void viewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'library navigation, day notes, variant selection and budget reset preserve personal data',
    (tester) async {
      viewport(tester, const Size(1440, 1000));
      final d = await dependencies();
      await tester.pumpWidget(TravelApp(dependencies: d, initialLocation: '/'));
      await tester.pumpAndSettle();
      expect(find.text('把路书带上。'), findsOneWidget);
      await tester.tap(find.text('赣皖自驾'));
      await tester.pumpAndSettle();
      expect(find.byType(BookShell), findsOneWidget);
      await tester.tap(find.text('每日行程').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('江门 → 韶关').first);
      await tester.pumpAndSettle();
      final note = field('Day 1 个人备注');
      await tester.ensureVisible(note);
      await tester.enterText(note, '车宿许可已电话核对');
      await tester.pumpAndSettle();
      expect(
        d.preferences.snapshot.value.forBook('ganwan').notes['out-1'],
        '车宿许可已电话核对',
      );
      await tester.tap(find.text('16天 · 主方案').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('17天 · 多一天缓冲').last);
      await tester.pumpAndSettle();
      expect(d.preferences.snapshot.value.forBook('ganwan').variantId, '17');
      await tester.tap(find.text('旅行账本').first);
      await tester.pumpAndSettle();
      final people = field('出行人数');
      expect(find.text('恢复初始预算'), findsOneWidget);
      await tester.scrollUntilVisible(
        people,
        250,
        scrollable: find
            .descendant(
              of: find.byType(TravelPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(people, '3');
      await tester.pumpAndSettle();
      expect(
        d.preferences.snapshot.value.forBook('ganwan').budget['people'],
        3,
      );
      await tester.scrollUntilVisible(
        find.text('恢复初始预算'),
        -350,
        scrollable: find
            .descendant(
              of: find.byType(TravelPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('恢复初始预算'));
      await tester.pumpAndSettle();
      expect(d.preferences.snapshot.value.forBook('ganwan').budget, isEmpty);
      expect(
        d.preferences.snapshot.value.forBook('ganwan').notes['out-1'],
        '车宿许可已电话核对',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await d.preferences.dispose();
    },
  );
  testWidgets(
    'mobile navigation exposes all sections and checklist survives changing books',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final d = await dependencies();
      await tester.pumpWidget(
        TravelApp(dependencies: d, initialLocation: '/book/tibet/checklist'),
      );
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('task:id-card'));
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(
        d.preferences.snapshot.value.forBook('tibet').checks['id-card'],
        isTrue,
      );
      await tester.tap(find.text('更多').last);
      await tester.pumpAndSettle();
      expect(find.text('风险应对'), findsOneWidget);
      await tester.tap(find.text('风险应对'));
      await tester.pumpAndSettle();
      final search = field('搜索风险关键词');
      await tester.enterText(search, '航班');
      await tester.pumpAndSettle();
      expect(find.text('当前 1 项'), findsOneWidget);
      await tester.tap(find.text('重置筛选'));
      await tester.pumpAndSettle();
      expect(find.text('当前 14 项'), findsOneWidget);
      expect((tester.widget<TextField>(field('搜索风险关键词'))).controller?.text, '');
      final router = GoRouter.of(tester.element(find.byType(BookShell)));
      router.go('/book/ganwan/overview');
      await tester.pumpAndSettle();
      router.go('/book/tibet/checklist');
      await tester.pumpAndSettle();
      expect(
        d.preferences.snapshot.value.forBook('tibet').checks['id-card'],
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await d.preferences.dispose();
    },
  );
  testWidgets('all mobile feature pages remain usable with large system text', (
    tester,
  ) async {
    viewport(tester, const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final d = await dependencies();
    await tester.pumpWidget(TravelApp(dependencies: d, initialLocation: '/'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(LibraryScreen)));
    for (final book in books) {
      for (final section in book.sections) {
        router.go('/book/${book.id}/$section');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${book.id}/$section');
      }
    }
    router.go('/book/unknown/map');
    await tester.pumpAndSettle();
    expect(find.text('这页路书没有找到'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await d.preferences.dispose();
  });
  testWidgets('deep link day filters only the requested stable day', (
    tester,
  ) async {
    viewport(tester, const Size(1280, 900));
    final d = await dependencies();
    await tester.pumpWidget(
      TravelApp(
        dependencies: d,
        initialLocation: '/book/tibet/itinerary?day=10%2F1',
      ),
    );
    await tester.pumpAndSettle();
    expect(field('10/1 个人备注'), findsOneWidget);
    expect(field('9/29 个人备注'), findsNothing);
    expect(find.text('显示全部日期'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await d.preferences.dispose();
  });
}
