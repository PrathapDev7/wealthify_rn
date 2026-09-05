import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../calories/calorie_screen.dart';
import 'app_home_switcher.dart';

/// Healthify's Home tab: the app switcher pinned above the calorie tracker's
/// hero, both re-themed and rendered on Healthify's own route
/// ([Routes.healthifyHome]) rather than shared with Wealthify's dashboard.
class HealthifyHomeScreen extends StatelessWidget {
  const HealthifyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: HealthifyTheme(
            child: CalorieScreen(
              embedded: true,
              heroWrapper: (ctx, hero) => heroBackdrop(
                ctx,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The switcher itself stays on the app-neutral default
                    // theme even though it sits inside HealthifyTheme, so its
                    // pill background doesn't pick up Healthify's palette.
                    Theme(
                      data: isDark ? AppTheme.dark() : AppTheme.light(),
                      child: const AppHomeSwitcher(),
                    ),
                    hero,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
