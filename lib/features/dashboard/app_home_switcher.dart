import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_switcher.dart';

/// Where the switcher sends you when you pick a different app — each app now
/// has its own Home branch/route, rather than one screen swapped in place by
/// a runtime condition.
String homeRouteFor(ActiveApp app) => switch (app) {
  ActiveApp.wealthify => Routes.dashboard,
  ActiveApp.healthify => Routes.healthifyHome,
  ActiveApp.fitness => Routes.fitnessHome,
};

/// The Wealthify/Healthify/Fitness switcher, pinned above each app's Home
/// tab. Picking a different app flips [activeAppProvider] and navigates to
/// that app's Home branch.
class AppHomeSwitcher extends ConsumerWidget {
  const AppHomeSwitcher({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp = ref.watch(activeAppProvider);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
      child: AppSwitcher(
        active: activeApp,
        onChanged: (app) {
          ref.read(activeAppProvider.notifier).set(app);
          if (app != activeApp) context.go(homeRouteFor(app));
        },
      ),
    );
  }
}

/// Wraps [content] with a gradient backdrop (the active app's own palette)
/// that bleeds up behind the status bar and peeks a little past [content]'s
/// own bottom edge. Sized purely off [content]'s natural height via
/// top/bottom-relative Positioned — no guessed fixed height needed. Shared by
/// the Wealthify and Healthify Home screens, whose hero cards both sit on
/// this backdrop.
Widget heroBackdrop(BuildContext context, Widget content) {
  final c = context.colors;
  final topInset = MediaQuery.of(context).padding.top;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        top: -topInset,
        left: 0,
        right: 0,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.primary, c.primaryDark, c.primaryDarker],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadius.xl2),
              bottomRight: Radius.circular(AppRadius.xl2),
            ),
          ),
        ),
      ),
      content,
    ],
  );
}
