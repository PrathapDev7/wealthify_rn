import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/recurring_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../features/account/account_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/session_controller.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/budgets/set_budget_screen.dart';
import '../../features/categories/edit_category_screen.dart';
import '../../features/categories/manage_categories_screen.dart';
import '../../features/categories/select_category_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/goals/goal_detail_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/preferences/preferences_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/recurring/edit_recurring_screen.dart';
import '../../features/recurring/recurring_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/security/security_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/transactions/add_transaction_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/wallets/edit_wallet_screen.dart';
import '../../features/wallets/select_provider_screen.dart';
import '../../features/wallets/wallets_screen.dart';
import '../providers.dart';
import '../storage/prefs.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;

      if (session.isLoading) return loc == Routes.splash ? null : Routes.splash;

      final user = session.asData?.value;
      final seenWelcome = ref.read(prefsProvider).getBool(Prefs.kSeenWelcome);
      final atEntry =
          loc == Routes.splash || loc == Routes.welcome || loc == Routes.auth;

      if (user != null) return atEntry ? Routes.dashboard : null;
      if (!seenWelcome) return loc == Routes.welcome ? null : Routes.welcome;
      return (loc == Routes.auth || loc == Routes.welcome) ? null : Routes.auth;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.auth, builder: (_, _) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.dashboard,
                builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.transactions,
                builder: (_, _) => const TransactionsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.analytics,
                builder: (_, _) => const AnalyticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: Routes.addTransaction,
        builder: (_, state) => AddTransactionScreen(
            type: state.uri.queryParameters['type'] ?? 'expense'),
      ),
      GoRoute(
        path: Routes.transactionDetail,
        builder: (_, state) =>
            TransactionDetailScreen(txn: state.extra as TransactionModel),
      ),
      GoRoute(
        path: Routes.selectCategory,
        builder: (_, state) => SelectCategoryScreen(
            type: state.uri.queryParameters['type'] ?? 'expense'),
      ),
      GoRoute(
        path: Routes.selectProvider,
        builder: (_, state) => SelectProviderScreen(
            type: state.uri.queryParameters['type'] ?? 'bank'),
      ),
      GoRoute(path: Routes.budgets, builder: (_, _) => const BudgetsScreen()),
      GoRoute(
        path: Routes.setBudget,
        builder: (_, state) =>
            SetBudgetScreen(category: state.uri.queryParameters['category']),
      ),
      GoRoute(path: Routes.wallets, builder: (_, _) => const WalletsScreen()),
      GoRoute(
        path: Routes.editWallet,
        builder: (_, state) =>
            EditWalletScreen(wallet: state.extra as WalletModel?),
      ),
      GoRoute(path: Routes.recurring, builder: (_, _) => const RecurringScreen()),
      GoRoute(
        path: Routes.editRecurring,
        builder: (_, state) =>
            EditRecurringScreen(rule: state.extra as RecurringModel?),
      ),
      GoRoute(path: Routes.goals, builder: (_, _) => const GoalsScreen()),
      GoRoute(
        path: Routes.goalDetail,
        builder: (_, state) => GoalDetailScreen(goal: state.extra as GoalModel?),
      ),
      GoRoute(path: Routes.insights, builder: (_, _) => const InsightsScreen()),
      GoRoute(
          path: Routes.manageCategories,
          builder: (_, _) => const ManageCategoriesScreen()),
      GoRoute(
        path: Routes.editCategory,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EditCategoryScreen(
            category: extra?['category'] as CategoryModel?,
            type: (extra?['type'] as String?) ?? 'expense',
          );
        },
      ),
      GoRoute(path: Routes.reports, builder: (_, _) => const ReportsScreen()),
      GoRoute(
          path: Routes.preferences,
          builder: (_, _) => const PreferencesScreen()),
      GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: Routes.security, builder: (_, _) => const SecurityScreen()),
      GoRoute(path: Routes.premium, builder: (_, _) => const PremiumScreen()),
    ],
  );
});
