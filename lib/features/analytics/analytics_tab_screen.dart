import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../calories/calorie_history_screen.dart';
import 'analytics_screen.dart';

/// Body for the bottom-nav "Analytics" tab. Renders the Wealthify
/// [AnalyticsScreen] or the Healthify Statistics view depending on which
/// app is active, so both apps share the same tab slot.
class AnalyticsTabScreen extends ConsumerWidget {
  const AnalyticsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp = ref.watch(activeAppProvider);
    if (activeApp == ActiveApp.wealthify) return const AnalyticsScreen();

    return HealthifyTheme(
      child: Builder(
        builder: (context) {
          final c = context.colors;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.go(Routes.dashboard),
                    ),
                    Expanded(
                      child: Text(
                        'Statistics',
                        textAlign: TextAlign.center,
                        style: AppText.screenTitle.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Expanded(child: CalorieHistoryScreen(embedded: true)),
            ],
          );
        },
      ),
    );
  }
}
