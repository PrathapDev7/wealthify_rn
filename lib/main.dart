import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/local_notifications.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock_gate.dart';
import 'core/shortcuts/app_link_listener.dart';
import 'core/shortcuts/quick_actions_setup.dart';
import 'core/storage/prefs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await Prefs.create();
  // Register the notification plugin early so the iOS foreground-presentation
  // flags are in place before any show()/schedule() call. Non-blocking: the
  // wrapper swallows errors on platforms without notifications (e.g. web).
  unawaited(LocalNotifications.instance.init());
  // Launcher quick actions + widget-tap routing. Never blocks startup.
  unawaited(setupAppEntryPoints());
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const AlignApp(),
    ),
  );
}

class AlignApp extends ConsumerWidget {
  const AlignApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Align',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      routerConfig: router,
      builder: (context, child) => AppLinkListener(
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
