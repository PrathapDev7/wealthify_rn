import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'app_links.dart';

/// Launcher quick actions (long-press on the app icon) + home-screen widget
/// tap routing. Safe to call on every platform; failures are swallowed so a
/// plugin hiccup can never break app startup.
Future<void> setupAppEntryPoints() async {
  const qa = QuickActions();
  try {
    await qa.setShortcutItems(const [
      ShortcutItem(
        type: AppLinks.addExpense,
        localizedTitle: 'Add Expense',
        localizedSubtitle: 'Log a purchase or bill',
        icon: 'ic_shortcut_expense',
      ),
      ShortcutItem(
        type: AppLinks.addIncome,
        localizedTitle: 'Add Income',
        localizedSubtitle: 'Record money received',
        icon: 'ic_shortcut_income',
      ),
      ShortcutItem(
        type: AppLinks.logCalories,
        localizedTitle: 'Log Calories',
        localizedSubtitle: 'Track what you ate',
        icon: 'ic_shortcut_meal',
      ),
      ShortcutItem(
        type: AppLinks.logWeight,
        localizedTitle: 'Log Weight',
        localizedSubtitle: "Log today's weight",
        icon: 'ic_shortcut_weight',
      ),
      ShortcutItem(
        type: AppLinks.openWorkout,
        localizedTitle: 'Open Workout',
        localizedSubtitle: 'Pick a routine and train',
        icon: 'ic_shortcut_workout',
      ),
    ]);
    await qa.initialize(
      (type) => AppLinks.stashRoute(AppLinks.routeForShortcut(type)),
    );
  } catch (_) {
    debugPrint('Quick actions unavailable');
  }

  try {
    if (!kIsWeb && Platform.isIOS) {
      await HomeWidget.setAppGroupId(AppLinks.appGroupId);
    }
    final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (initial != null) {
      AppLinks.stashRoute(AppLinks.routeForWidgetUri(initial));
    }
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) AppLinks.stashRoute(AppLinks.routeForWidgetUri(uri));
    });
  } catch (_) {
    debugPrint('Home widget links unavailable');
  }
}
