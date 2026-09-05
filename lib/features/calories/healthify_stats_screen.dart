import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import 'calorie_history_screen.dart';

/// Healthify's Stats tab: a back button + title bar over
/// [CalorieHistoryScreen], on its own route ([Routes.healthifyStats]) rather
/// than shared with Wealthify's analytics tab.
class HealthifyStatsScreen extends StatelessWidget {
  const HealthifyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Row(
            children: [
              CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.go(Routes.healthifyHome),
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
  }
}
