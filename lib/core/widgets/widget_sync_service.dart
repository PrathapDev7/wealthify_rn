import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../data/models/budget_model.dart';
import '../../data/models/calorie_entry.dart';
import '../../data/models/stats_model.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../features/preferences/preferences_controller.dart';
import '../providers.dart';
import '../utils/currency.dart';

/// Keys mirrored by the native widgets (Android RemoteViews / iOS WidgetKit).
abstract class WidgetKeys {
  static const balanceText = 'align_balance_text';
  static const balanceSub = 'align_balance_sub';
  static const spentText = 'align_spent_text';
  static const spentOf = 'align_spent_of';
  static const spentProgress = 'align_spent_progress';
  static const budgetRows = 'align_budget_rows';

  static const calConsumed = 'align_cal_consumed';
  static const calTarget = 'align_cal_target';
  static const calLeft = 'align_cal_left';
  static const calProgress = 'align_cal_progress';
  static const calProtein = 'align_cal_protein';
  static const calProteinTarget = 'align_cal_protein_target';
  static const calCarbs = 'align_cal_carbs';
  static const calCarbsTarget = 'align_cal_carbs_target';
  static const calFat = 'align_cal_fat';
  static const calFatTarget = 'align_cal_fat_target';

  static const fitWorkouts = 'align_fit_workouts';
  static const fitMinutes = 'align_fit_minutes';
  static const fitSets = 'align_fit_sets';
  static const fitVolume = 'align_fit_volume';
  static const fitTodayLabel = 'align_fit_today_label';

  static const androidBalance = 'com.invent.wealthify.AlignBalanceWidget';
  static const androidBudget = 'com.invent.wealthify.AlignBudgetWidget';
  static const androidCalories = 'com.invent.wealthify.AlignCaloriesWidget';
  static const androidFitness = 'com.invent.wealthify.AlignFitnessWidget';

  static const iosKind = 'AlignWidgets';

  static const iosKinds = [
    'AlignBalance',
    'AlignBudgets',
    'AlignCalories',
    'AlignFitness',
  ];
}

/// Pushes snapshot data to the native home-screen widgets.
///
/// Two entry styles: `save*` writes data the screens already loaded (no extra
/// API calls); `syncAll` refetches everything itself for launch-time and
/// mutation-driven refreshes. All best-effort — failures never throw.
class WidgetSyncService {
  WidgetSyncService(this._ref);
  final Ref _ref;

  static bool _running = false;

  Future<void> syncAll({bool update = true}) async {
    if (_running) return;
    _running = true;
    try {
      await Future.wait([
        _fetchBalance(),
        _fetchCalories(),
        _fetchFitness(),
      ], eagerError: false);
      if (update) await requestUpdates();
    } catch (_) {
      debugPrint('Widget sync failed');
    } finally {
      _running = false;
    }
  }

  Future<void> saveBalance(
    StatsModel stats,
    BudgetModel budget,
    String Function(num? value) money,
  ) async {
    try {
      final balance = stats.balance;
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.balanceText,
        _fmt(balance, money),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.balanceSub,
        balance >= 0
            ? 'Under budget by ${money(balance)}'
            : 'Over budget by ${money(balance.abs())}',
      );
      final overall = budget.overall ?? 0;
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.spentText,
        money(stats.totalExpenses),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.spentOf,
        money(overall),
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.spentProgress,
        overall <= 0
            ? 0
            : ((stats.totalExpenses / overall).toDouble().clamp(0.0, 1.0) * 100)
                .round(),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.budgetRows,
        _budgetRowsCsv(stats, budget),
      );
      await requestUpdates();
    } catch (_) {
      debugPrint('Balance widget save failed');
    }
  }

  Future<void> saveCalories(DailyTotals t) async {
    try {
      final target = t.calorieTarget ?? 0;
      await HomeWidget.saveWidgetData<int>(WidgetKeys.calConsumed, t.calories);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.calTarget, target);
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.calLeft,
        target == 0 ? 0 : target - t.calories,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.calProgress,
        target <= 0 ? 0 : ((t.calories / target).clamp(0.0, 1.0) * 100).round(),
      );
      await _saveMacro(
        WidgetKeys.calProtein,
        WidgetKeys.calProteinTarget,
        t.protein,
        t.proteinTarget,
      );
      await _saveMacro(
        WidgetKeys.calCarbs,
        WidgetKeys.calCarbsTarget,
        t.carbs,
        t.carbTarget,
      );
      await _saveMacro(
        WidgetKeys.calFat,
        WidgetKeys.calFatTarget,
        t.fat,
        t.fatTarget,
      );
      await requestUpdates();
    } catch (_) {
      debugPrint('Calories widget save failed');
    }
  }

  Future<void> saveFitness(WorkoutStats stats) async {
    try {
      final totals = stats.totals;
      final exercises = stats.sessions.fold<int>(
        0,
        (sum, s) => sum + s.exerciseCount,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.fitWorkouts,
        totals.workouts,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.fitMinutes,
        totals.durationSec ~/ 60,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.fitSets,
        totals.completedSets,
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.fitVolume,
        '${totals.volume.round()} kg',
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.fitTodayLabel,
        stats.sessions.isEmpty
            ? 'No workouts yet today'
            : '$exercises exercises today',
      );
      await requestUpdates();
    } catch (_) {
      debugPrint('Fitness widget save failed');
    }
  }

  Future<void> requestUpdates() async {
    for (final name in [
      WidgetKeys.androidBalance,
      WidgetKeys.androidBudget,
      WidgetKeys.androidCalories,
      WidgetKeys.androidFitness,
    ]) {
      try {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      } catch (_) {}
    }
    try {
      await HomeWidget.updateWidget(iOSName: WidgetKeys.iosKind);
    } catch (_) {}
    for (final kind in WidgetKeys.iosKinds) {
      try {
        await HomeWidget.updateWidget(iOSName: kind);
      } catch (_) {}
    }
  }

  Future<void> _fetchBalance() async {
    try {
      final stats = await _ref.read(transactionsRepositoryProvider).getStats();
      final budget = await _ref.read(budgetsRepositoryProvider).getBudgets();
      await saveBalance(stats, budget, _money);
    } catch (_) {
      debugPrint('Balance widget sync failed');
    }
  }

  Future<void> _fetchCalories() async {
    try {
      final res = await _ref
          .read(caloriesRepositoryProvider)
          .getDailyCalories(
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          );
      final totals = Map<String, dynamic>.from(
        res['dailyTotals'] as Map? ?? {},
      );
      final targets = res['dailyTargets'] as Map?;
      if (targets != null) totals.addAll(Map<String, dynamic>.from(targets));
      await saveCalories(DailyTotals.fromJson(totals));
    } catch (_) {
      debugPrint('Calories widget sync failed');
    }
  }

  Future<void> _fetchFitness() async {
    try {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      final stats = await _ref.read(workoutRepositoryProvider).workoutStats(
            from: day,
            to: day.add(const Duration(days: 1)),
          );
      await saveFitness(stats);
    } catch (_) {
      debugPrint('Fitness widget sync failed');
    }
  }

  String Function(num? value) get _money {
    try {
      return _ref.read(preferencesProvider.notifier).money;
    } catch (_) {
      return (v) => formatCurrency(v);
    }
  }

  static String _fmt(num value, String Function(num? v) money) =>
      '${value < 0 ? '-' : ''}${money(value.abs())}';

  static String _budgetRowsCsv(StatsModel stats, BudgetModel budget) {
    final spent = <String, num>{};
    for (final t in stats.allData) {
      if (t.isIncome) continue;
      spent[t.category] = (spent[t.category] ?? 0) + t.amount;
    }
    final keys = budget.budgets.keys.where((k) => k != 'Overall').toList()
      ..sort((a, b) {
        double ratio(String k) {
          final limit = budget.budgets[k] ?? 0;
          if (limit == 0) return 0;
          return ((spent[k] ?? 0) / limit).toDouble();
        }

        return ratio(b).compareTo(ratio(a));
      });
    return keys
        .take(3)
        .map((k) => '$k|${spent[k] ?? 0}|${budget.budgets[k] ?? 0}')
        .join(';');
  }

  static Future<void> _saveMacro(
    String valueKey,
    String targetKey,
    double value,
    int? target,
  ) async {
    await HomeWidget.saveWidgetData<int>(valueKey, value.round());
    await HomeWidget.saveWidgetData<int>(targetKey, target ?? 0);
  }
}

final widgetSyncProvider = Provider<WidgetSyncService>(
  (ref) => WidgetSyncService(ref),
);
