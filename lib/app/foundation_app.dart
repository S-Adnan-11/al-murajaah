import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/audio/prototype_handler.dart';
import '../core/database/app_database.dart';
import '../core/database/foundation_repository.dart';
import '../core/theme/appearance_controller.dart';
import '../core/theme/appearance_screen.dart';
import '../core/theme/themed_app.dart';
import '../main.dart' show DiagnosticScreen;

/// One player and one logical database worker. Diagnostic JSON/audio stay in
/// their existing directory; there is no implicit migration of user audio data.
class FoundationDependencies {
  FoundationDependencies(this.database, this.repository, this.appearance);
  final AppDatabase database;
  final FoundationRepository repository;
  final AppearanceController appearance;
  static Future<FoundationDependencies> open() async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory(p.join(base.path, 'foundation'));
    await folder.create(recursive: true);
    final database = AppDatabase.file(File(p.join(folder.path, 'app.sqlite')));
    final repository = FoundationRepository(database);
    try {
      final stored = await repository.readTheme();
      debugPrint(
        'FOUNDATION_READY schema=${database.schemaVersion} theme=$stored',
      );
      return FoundationDependencies(
        database,
        repository,
        AppearanceController(
          initial: ThemeMode.values.byName(stored),
          persist: (mode) async {
            await repository.saveTheme(mode.name);
            debugPrint('FOUNDATION_THEME_SAVED theme=${mode.name}');
          },
        ),
      );
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<void> close() async {
    appearance.dispose();
    await database.close();
  }
}

final foundationRepositoryProvider = Provider<FoundationRepository>(
  (ref) => throw StateError('Foundation repository was not supplied'),
);
final appearanceProvider = Provider<AppearanceController>(
  (ref) => throw StateError('Appearance was not supplied'),
);
final audioHandlerProvider = Provider<PrototypeHandler>(
  (ref) => throw StateError('Existing audio handler was not supplied'),
);
final appRouterProvider = Provider<GoRouter>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => DiagnosticScreen(
          handler: handler,
          onAppearance: () => context.push('/appearance'),
        ),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearanceScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page unavailable')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to audio'),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class FoundationApp extends StatelessWidget {
  const FoundationApp({
    super.key,
    required this.handler,
    required this.dependencies,
  });
  final PrototypeHandler handler;
  final FoundationDependencies dependencies;
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      foundationRepositoryProvider.overrideWithValue(dependencies.repository),
      appearanceProvider.overrideWithValue(dependencies.appearance),
    ],
    child: const _FoundationView(),
  );
}

class _FoundationView extends ConsumerWidget {
  const _FoundationView();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ThemedApp.router(
    router: ref.watch(appRouterProvider),
    appearance: ref.watch(appearanceProvider),
  );
}
