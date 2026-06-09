/// All app route paths (mirrors the expo-router file routes).
abstract class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const auth = '/auth';

  // Tab shell
  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const analytics = '/analytics';
  static const account = '/account';

  // Stack
  static const addTransaction = '/add-transaction';
  static const transactionDetail = '/transaction-detail';
  static const selectCategory = '/select-category';
  static const selectProvider = '/select-provider';
  static const budgets = '/budgets';
  static const setBudget = '/set-budget';
  static const wallets = '/wallets';
  static const editWallet = '/edit-wallet';
  static const recurring = '/recurring';
  static const editRecurring = '/edit-recurring';
  static const goals = '/goals';
  static const goalDetail = '/goal-detail';
  static const insights = '/insights';
  static const manageCategories = '/manage-categories';
  static const editCategory = '/edit-category';
  static const reports = '/reports';
  static const preferences = '/preferences';
  static const notifications = '/notifications';
  static const security = '/security';
  static const premium = '/premium';
}
