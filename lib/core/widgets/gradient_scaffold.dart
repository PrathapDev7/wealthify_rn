import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

/// Screen wrapper with the Wealthify lavender-wash gradient background +
/// safe area. Equivalent of the RN `ScreenContainer variant="wash"`.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
  });

  final Widget child;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.lavenderWashTop,
              c.lavenderWashTopSoft,
              c.lavenderWashMid,
              c.lavenderWashBottom,
            ],
          ),
        ),
        child: SafeArea(bottom: false, child: child),
      ),
    );
  }
}

/// Standard stack-screen header: back button + centered title + optional action.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack, this.action});

  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.screenTitle.copyWith(color: c.text),
            ),
          ),
          SizedBox(width: 40, child: action),
        ],
      ),
    );
  }
}
