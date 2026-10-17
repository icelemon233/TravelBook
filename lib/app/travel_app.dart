import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/export/presentation/actions_view_model.dart';
import '../features/export/export_actions.dart';
import '../features/books/reference_actions.dart';
import '../features/library/presentation/library_view_model.dart';
import '../features/preferences/presentation/preferences_status_view_model.dart';
import '../features/preferences/preferences_status.dart';
import 'app_dependencies.dart';
import 'app_router.dart';
import '../core/ui/travel_theme.dart';

class TravelApp extends StatefulWidget {
  const TravelApp({
    super.key,
    required this.dependencies,
    this.initialLocation,
  });
  final AppDependencies dependencies;
  final String? initialLocation;
  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter(
    widget.dependencies,
    initialLocation: widget.initialLocation,
  );
  SemanticsHandle? _semantics;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) _semantics = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.dependencies.preferences.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _semantics?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: widget.dependencies),
      ChangeNotifierProvider(
        create: (_) => LibraryViewModel(widget.dependencies.catalog),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            PreferencesStatusViewModel(widget.dependencies.preferences),
      ),
      ListenableProvider<PreferencesStatus>(
        create: (c) => c.read<PreferencesStatusViewModel>(),
      ),
      ChangeNotifierProvider<ExportActions>(
        create: (_) => ActionsViewModel(
          files: widget.dependencies.files,
          pdf: widget.dependencies.pdf,
          preferences: widget.dependencies.preferences,
          mapRenderer: widget.dependencies.mapSnapshots,
        ),
      ),
      Provider<ReferenceActions>(create: (c) => c.read<ExportActions>()),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cinna Travel Book',
      theme: TravelTheme.light,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    ),
  );
}
