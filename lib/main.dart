import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/travel_app.dart';
import 'core/ui/travel_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dependencies = await AppDependencies.load();
    runApp(TravelApp(dependencies: dependencies));
  } catch (_) {
    runApp(const _StartupFailure());
  }
}

class _StartupFailure extends StatelessWidget {
  const _StartupFailure();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TravelTheme.light,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined, size: 48),
                const SizedBox(height: 20),
                const Text('路书暂时未能载入'),
                const SizedBox(height: 10),
                const Text('请重试。个人备注和清单仍保留在本地。'),
                const SizedBox(height: 20),
                FilledButton(onPressed: main, child: const Text('重新载入')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
