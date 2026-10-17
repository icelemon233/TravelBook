import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cinna_travel_book/app/app_dependencies.dart';
import 'package:cinna_travel_book/app/book_shell.dart';
import 'package:cinna_travel_book/app/travel_app.dart';
import 'package:cinna_travel_book/features/books/data/asset_trip_repository.dart';
import 'package:cinna_travel_book/features/books/domain/travel_book.dart';
import 'package:cinna_travel_book/features/books/domain/trip_repository.dart';
import 'package:cinna_travel_book/features/books/presentation/book_view_model.dart';
import 'package:cinna_travel_book/features/budget/domain/budget_calculator.dart';
import 'package:cinna_travel_book/features/budget/presentation/budget_view_model.dart';
import 'package:cinna_travel_book/features/export/domain/travel_report.dart';
import 'package:cinna_travel_book/features/export/presentation/actions_view_model.dart';
import 'package:cinna_travel_book/features/map/domain/route_map.dart';
import 'package:cinna_travel_book/features/map/presentation/map_screen.dart';
import 'package:cinna_travel_book/features/map/presentation/map_view_model.dart';
import 'package:cinna_travel_book/features/preferences/data/local_preferences_repository.dart';
import 'package:cinna_travel_book/features/preferences/domain/backup_limits.dart';
import 'package:cinna_travel_book/features/preferences/domain/user_preferences.dart';

import 'platform_fakes.dart';
import 'support.dart';

class ReadFailureStore extends MemoryPreferencesStore {
  bool failReads = true;
  @override
  Future<String?> read() async {
    if (failReads) throw StateError('transient read failure');
    return super.read();
  }
}

class GatedTripRepository implements TripRepository {
  GatedTripRepository(this.delegate);
  final TripRepository delegate;
  Completer<MapDocument> gate = Completer<MapDocument>();
  final requested = Completer<void>();
  @override
  Future<List<BookSummary>> catalog() => delegate.catalog();
  @override
  Future<TravelBook> book(String id) => delegate.book(id);
  @override
  Future<MapDocument> map(String id) {
    if (!requested.isCompleted) requested.complete();
    return gate.future;
  }
}

class RecordingPdf extends FakePdfService {
  Uint8List? lastMapImage;
  @override
  Future<Uint8List> generate(TravelReport report, {Uint8List? mapImage}) {
    lastMapImage = mapImage;
    return super.generate(report, mapImage: mapImage);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final trips = AssetTripRepository(FileAssets());
  late List<TravelBook> books;
  setUpAll(() async {
    books = await loadBooks(trips);
    await trips.map('ganwan');
  });

  Future<LocalPreferencesRepository> preferences([
    MemoryPreferencesStore? store,
  ]) async {
    final prefs = LocalPreferencesRepository(
      store ?? MemoryPreferencesStore(),
      LegacyValues(),
    );
    await prefs.initialize(books);
    return prefs;
  }

  ActionsViewModel exports(
    LocalPreferencesRepository prefs,
    BookViewModel book,
    BudgetViewModel budget,
    FakeFileActions files,
    FakePdfService pdf, {
    MapViewModel? map,
  }) => ActionsViewModel(
    files: files,
    pdf: pdf,
    preferences: prefs,
    mapRenderer: FakeMapSnapshots(),
    bookId: book.book.id,
    readReport: () => TravelReport(
      book: book.book,
      variant: book.variant,
      budget: budget.estimate,
      preferences: prefs.snapshot.value.forBook(book.book.id),
    ),
    readMap: map?.snapshot,
  );

  test(
    'read failure preserves unread durable notes across edits and recovery',
    () async {
      final original = UserPreferences().update(
        'ganwan',
        BookPreferences(notes: {'out-1': '之前保存的备注'}),
      );
      final encoded = jsonEncode(original.toJson());
      final store = ReadFailureStore()..value = encoded;
      final prefs = await preferences(store);
      await prefs.updateBook('ganwan', (p) => p.withCheck('sleep', true));
      await prefs.flush();
      expect(prefs.snapshot.error, contains('暂停自动保存'));
      expect(prefs.snapshot.value.forBook('ganwan').checks['sleep'], isTrue);
      expect(store.value, encoded);
      expect(store.writes, isEmpty);
      expect(
        UserPreferences.import(prefs.snapshot.value.backup())
            .forBook('ganwan')
            .checks['sleep'],
        isTrue,
      );

      store.failReads = false;
      final restarted = await preferences(store);
      expect(
        restarted.snapshot.value.forBook('ganwan').notes['out-1'],
        '之前保存的备注',
      );
      await restarted.dispose();
      await prefs.importBackup(original.backup());
      await prefs.updateBook('ganwan', (p) => p.withCheck('charge', true));
      expect(prefs.snapshot.error, isNull);
      final durable = UserPreferences.fromJson(jsonDecode(store.value!));
      expect(durable.forBook('ganwan').notes['out-1'], '之前保存的备注');
      expect(durable.forBook('ganwan').checks['charge'], isTrue);
      await prefs.dispose();
    },
  );

  test('failed migration write can retry without blocking a successfully read dataset', () async {
    final store = MemoryPreferencesStore()..failWrites = true;
    final prefs = LocalPreferencesRepository(
      store,
      LegacyValues({
        'cinna-ganwan-v1': jsonEncode({
          'notes': {'out-1': '旧版备注'},
        }),
      }),
    );
    await prefs.initialize(books);
    expect(prefs.snapshot.error, isNotNull);
    store.failWrites = false;
    await prefs.updateBook('ganwan', (p) => p.withCheck('charge', true));
    expect(prefs.snapshot.error, isNull);
    final durable = UserPreferences.fromJson(jsonDecode(store.value!));
    expect(durable.forBook('ganwan').notes['out-1'], '旧版备注');
    expect(durable.forBook('ganwan').checks['charge'], isTrue);
    await prefs.dispose();
  });

  for (final draft in ['3', 'invalid']) {
    test(
      'same-variant import replaces the $draft budget draft in UI and PDF',
      () async {
        final prefs = await preferences();
        final book = BookViewModel(books.first, prefs);
        final budget = BudgetViewModel(book, prefs);
        final field = budget.fields.firstWhere((f) => f.id == 'people');
        await budget.edit(field, draft);
        final imported = UserPreferences().update(
          'ganwan',
          BookPreferences(variantId: book.variant.id, budget: {'people': 2}),
        );
        await prefs.importBackup(imported.backup());
        expect(budget.input(field), '2');
        expect(budget.values['people'], 2);
        final expected = const BudgetCalculator().estimate(
          book.book,
          book.variant,
          {...book.variant.budgetDefaults, 'people': 2},
        );
        final pdf = RecordingPdf();
        final actions = exports(prefs, book, budget, FakeFileActions(), pdf);
        await actions.exportPdf();
        expect(actions.error, isNull);
        expect(pdf.lastReport!.budget.total, expected.total);
        expect(pdf.lastReport!.preferences.budget['people'], 2);
        actions.dispose();
        budget.dispose();
        book.dispose();
        await prefs.dispose();
      },
    );
  }

  test('failed import preserves an unsaved invalid budget draft', () async {
    final store = MemoryPreferencesStore();
    final prefs = await preferences(store);
    final book = BookViewModel(books.first, prefs);
    final budget = BudgetViewModel(book, prefs);
    final field = budget.fields.firstWhere((f) => f.id == 'people');
    await budget.edit(field, 'invalid');
    store.failWrites = true;
    await expectLater(
      prefs.importBackup(UserPreferences().backup()),
      throwsException,
    );
    expect(budget.input(field), 'invalid');
    expect(budget.estimate.valid, isFalse);
    budget.dispose();
    book.dispose();
    await prefs.dispose();
  });

  test(
    'invalid numeric budget drafts never corrupt durable notes or backups',
    () async {
      final store = MemoryPreferencesStore();
      final prefs = await preferences(store);
      await prefs.updateBook('ganwan', (p) => p.withNote('out-1', '保留已有备注'));
      final book = BookViewModel(books.first, prefs);
      final budget = BudgetViewModel(book, prefs);
      final people = budget.fields.firstWhere((field) => field.id == 'people');
      for (final raw in ['0', '1.5', '10000000000']) {
        await budget.edit(people, raw);
        expect(budget.input(people), raw);
        expect(budget.error(people), isNotNull);
        expect(prefs.snapshot.value.forBook('ganwan').budget['people'], isNull);
        final restarted = await preferences(store);
        expect(restarted.snapshot.error, isNull);
        expect(
          restarted.snapshot.value.forBook('ganwan').notes['out-1'],
          '保留已有备注',
        );
        expect(
          UserPreferences.import(restarted.snapshot.value.backup())
              .forBook('ganwan')
              .budget['people'],
          isNull,
        );
        await restarted.dispose();
      }
      await budget.edit(people, '2');
      expect(budget.error(people), isNull);
      expect(prefs.snapshot.value.forBook('ganwan').budget['people'], 2);
      budget.dispose();
      book.dispose();
      await prefs.dispose();
    },
  );

  test(
    'PDF waits for an existing map load and includes the resulting map',
    () async {
      final prefs = await preferences();
      final book = BookViewModel(books.first, prefs);
      final budget = BudgetViewModel(book, prefs);
      final gated = GatedTripRepository(trips);
      final map = MapViewModel(book, prefs, gated);
      final loading = map.load();
      final pdf = RecordingPdf();
      final files = FakeFileActions();
      final actions = exports(prefs, book, budget, files, pdf, map: map);
      final export = actions.exportPdf();
      await Future<void>.delayed(Duration.zero);
      expect(pdf.lastReport, isNull);
      expect(files.saved, isEmpty);
      gated.gate.complete(await trips.map('ganwan'));
      await Future.wait([loading, export]);
      expect(actions.error, isNull);
      expect(pdf.lastMapImage, isNotNull);
      expect(files.saved.single.mime, 'application/pdf');
      actions.dispose();
      map.dispose();
      budget.dispose();
      book.dispose();
      await prefs.dispose();
    },
  );

  test(
    'map failure blocks an incomplete PDF and a subsequent retry succeeds',
    () async {
      final prefs = await preferences();
      final book = BookViewModel(books.first, prefs);
      final budget = BudgetViewModel(book, prefs);
      final gated = GatedTripRepository(trips);
      final map = MapViewModel(book, prefs, gated);
      final pdf = RecordingPdf();
      final files = FakeFileActions();
      final actions = exports(prefs, book, budget, files, pdf, map: map);
      final failed = actions.exportPdf();
      await gated.requested.future;
      gated.gate.completeError(StateError('resource unavailable'));
      await failed;
      expect(actions.error, contains('地图资源'));
      expect(pdf.lastReport, isNull);
      expect(files.saved, isEmpty);
      gated.gate = Completer<MapDocument>();
      final retry = actions.exportPdf();
      gated.gate.complete(await trips.map('ganwan'));
      await retry;
      expect(actions.error, isNull);
      expect(pdf.lastMapImage, isNotNull);
      actions.dispose();
      map.dispose();
      budget.dispose();
      book.dispose();
      await prefs.dispose();
    },
  );

  test(
    'a map export snapshots its selected day before asynchronous loading',
    () async {
      final prefs = await preferences();
      final book = BookViewModel(books.first, prefs);
      final gated = GatedTripRepository(trips);
      final map = MapViewModel(book, prefs, gated);
      map.selectDay('yaoli');
      final snapshot = map.snapshot();
      map.selectDay('out-1');
      gated.gate.complete(await trips.map('ganwan'));
      expect((await snapshot).routes.map((r) => r.dayId), ['yaoli']);
      map.dispose();
      book.dispose();
      await prefs.dispose();
    },
  );

  test(
    'maximum family-emoji notes roundtrip through export and the backup picker',
    () async {
      final note = List.filled(4000, '👨‍👩‍👧‍👦').join();
      var personal = UserPreferences();
      for (final book in books) {
        var saved = BookPreferences();
        for (final id
            in book.variants.expand((v) => v.days).map((d) => d.id).toSet()) {
          saved = saved.withNote(id, note);
        }
        personal = personal.update(book.id, saved);
      }
      final backup = personal.backup();
      expect(utf8.encode(backup).length, greaterThan(2 * 1024 * 1024));
      final prefs = await preferences();
      final files = FakeFileActions()..nextBackup = backup;
      final actions = ActionsViewModel(
        files: files,
        pdf: FakePdfService(),
        preferences: prefs,
        mapRenderer: FakeMapSnapshots(),
      );
      await actions.importBackup();
      expect(files.lastPickMaxBytes, BackupLimits.maxBytes);
      expect(actions.error, isNull);
      expect(prefs.snapshot.value.forBook('ganwan').notes['out-1'], note);
      await actions.exportBackup();
      final restored = UserPreferences.import(
        utf8.decode(files.saved.single.bytes),
      );
      expect(restored.toJson(), personal.toJson());
      actions.dispose();
      await prefs.dispose();
    },
  );

  test('oversized backups are rejected on both export and import', () {
    final note = List.filled(4000, '👨‍👩‍👧‍👦').join();
    final huge = UserPreferences().update(
      'ganwan',
      BookPreferences(
        notes: {for (var i = 0; i < 175; i++) 'synthetic-$i': note},
      ),
    );
    expect(() => huge.backup(), throwsFormatException);
    expect(
      () => UserPreferences.import(' '.padRight(BackupLimits.maxBytes + 1)),
      throwsFormatException,
    );
  });

  testWidgets(
    'map follows same-route day changes, all-days selection, and restored links',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await preferences();
      final dependencies = AppDependencies(
        trips: trips,
        preferences: prefs,
        files: FakeFileActions(),
        pdf: FakePdfService(),
        mapSnapshots: FakeMapSnapshots(),
        catalog: await trips.catalog(),
        books: books,
      );
      await tester.pumpWidget(
        TravelApp(
          dependencies: dependencies,
          initialLocation: '/book/ganwan/map?day=yaoli',
        ),
      );
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(MapScreen));
      final model = element.read<MapViewModel>();
      final router = GoRouter.of(tester.element(find.byType(BookShell)));
      expect(model.selectedDay, 'yaoli');
      router.go('/book/ganwan/map?day=out-1');
      await tester.pumpAndSettle();
      expect(model.selectedDay, 'out-1');
      await tester.tap(find.text('全部日期'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['day'],
        isNull,
      );
      expect(model.selectedDay, isNull);
      router.go('/book/ganwan/map?day=yaoli');
      await tester.pumpAndSettle();
      expect(model.selectedDay, 'yaoli');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await prefs.dispose();
    },
  );
}
