import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../dashboard/app_home_switcher.dart';
import 'fitness_home_screen.dart';

/// Fitness's Home tab: the app switcher and the fitness hero share one
/// coloured panel, the same shape Healthify's Home tab uses, with the rest of
/// the page scrolling on the plain background below it.
class FitnessHomeTabScreen extends StatelessWidget {
  const FitnessHomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FitnessTheme(
      child: FitnessHomeScreen(
        heroWrapper: (ctx, hero) => heroBackdrop(
          ctx,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The switcher itself stays on the app-neutral default theme
              // even though it sits inside FitnessTheme, so its pill
              // background doesn't pick up Fitness's palette.
              Theme(
                data: isDark ? AppTheme.dark() : AppTheme.light(),
                child: const AppHomeSwitcher(),
              ),
              hero,
            ],
          ),
        ),
      ),
    );
  }
}
