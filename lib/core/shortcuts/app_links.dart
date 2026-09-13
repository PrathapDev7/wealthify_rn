import 'package:flutter/foundation.dart';

import '../router/routes.dart';

/// Unified deep-link stash for entries that originate outside the widget tree:
/// launcher quick actions (long-press) and home-screen widget taps.
///
/// Both arrive as "open this route" requests that may land before the router
/// exists (cold start) or before the user is signed in. Handlers stash the
/// target here; the router redirect (cold start / post-login) and
/// [AppLinkListener] (warm) consume it exactly once.
abstract class AppLinks {
  // Quick-action types (must match the ShortcutItems registered at setup).
  static const addExpense = 'add-expense';
  static const addIncome = 'add-income';
  static const logCalories = 'log-calories';
  static const logWeight = 'log-weight';
  static const openWorkout = 'open-workout';

  /// App Group shared by the app and the iOS WidgetKit extension.
  static const appGroupId = 'group.com.invent.wealthify';

  static final ValueNotifier<String?> pendingRoute = ValueNotifier(null);

  static String? routeForShortcut(String type) => switch (type) {
        addExpense => '${Routes.addTransaction}?type=expense',
        addIncome => '${Routes.addTransaction}?type=income',
        logCalories => Routes.calories,
        logWeight => Routes.logWeight,
        openWorkout => Routes.fitnessWorkout,
        _ => null,
      };

  /// Widget taps arrive as `align://<screen>?homeWidget=<screen>` URIs. The
  /// `homeWidget` query item is required: on iOS the plugin only forwards
  /// URLs carrying it, and on Android it keeps the launch intent distinct
  /// from any future scamper of plain custom-scheme links.
  static String widgetUri(String screen) =>
      'align://$screen?homeWidget=$screen';

  static String? routeForWidgetUri(Uri uri) {
    final screen = uri.queryParameters['homeWidget'] ?? uri.host;
    return switch (screen) {
      'balance' => Routes.dashboard,
      'budgets' => Routes.budgets,
      'calories' => Routes.calories,
      'fitness' => Routes.fitnessHome,
      'log-weight' => Routes.logWeight,
      _ => null,
    };
  }

  static void stashRoute(String? route) {
    if (route != null) pendingRoute.value = route;
  }

  static String? consumeRoute() {
    final route = pendingRoute.value;
    pendingRoute.value = null;
    return route;
  }
}
