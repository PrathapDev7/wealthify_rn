import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../calories/health_goals_screen.dart';
import 'transactions_screen.dart';

/// Body for the bottom-nav tab in slot 1. Wealthify shows [TransactionsScreen];
/// Healthify has no transaction ledger, so it shows [HealthGoalsScreen] instead.
class TransactionsTabScreen extends ConsumerWidget {
  const TransactionsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp = ref.watch(activeAppProvider);
    if (activeApp == ActiveApp.wealthify) return const TransactionsScreen();
    return const HealthifyTheme(child: HealthGoalsScreen());
  }
}
