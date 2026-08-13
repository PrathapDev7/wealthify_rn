import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      extendBody: true,
      backgroundColor: c.background,
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
            stops: const [0.0, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(bottom: false, child: navigationShell),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [c.primaryGradientStart, c.primaryGradientEnd]),
          shape: BoxShape.circle,
          boxShadow: AppShadows.primaryGlow,
          border: Border.all(color: c.fabRing, width: 4),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => _showAddSheet(context),
        ),
      ),
      bottomNavigationBar: _NavBar(shell: navigationShell),
    );
  }

  void _showAddSheet(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: c.overlay,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
          boxShadow: AppShadows.xl,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Text('Quick Add',
                    style: AppText.title.copyWith(color: c.textStrong)),
                const SizedBox(height: AppSpacing.xxs),
                Text('What would you like to add?',
                    style: AppText.body.copyWith(color: c.textMuted)),
                const SizedBox(height: AppSpacing.xl),
                _QuickAddCard(
                  icon: Icons.arrow_upward_rounded,
                  color: c.negative,
                  label: 'Add Expense',
                  subtitle: 'Log a purchase or bill',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('${Routes.addTransaction}?type=expense');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickAddCard(
                  icon: Icons.arrow_downward_rounded,
                  color: c.primary,
                  label: 'Add Income',
                  subtitle: 'Record money you\'ve received',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('${Routes.addTransaction}?type=income');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickAddCard(
                  icon: Icons.pie_chart_rounded,
                  color: c.info,
                  label: 'Set Budget',
                  subtitle: 'Plan spending for a category',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(Routes.setBudget);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickAddCard(
                  icon: Icons.bookmark_rounded,
                  color: c.pink,
                  label: 'Add to Wishlist',
                  subtitle: 'Save something you want to buy',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(Routes.wishlist);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickAddCard(
                  icon: Icons.monitor_heart_rounded,
                  color: c.warning,
                  label: 'Log Calories',
                  subtitle: 'Track a meal or snack',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(Routes.calories);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            AppText.bodyStrong.copyWith(color: c.textStrong)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppText.bodySm.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSubtle, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics'),
    (Icons.person_outline, Icons.person, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BottomAppBar(
      color: c.surface,
      elevation: 0,
      height: 68,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i == 2) const SizedBox(width: 64), // gap for FAB
            Expanded(
              child: _NavItem(
                icon: _items[i].$1,
                activeIcon: _items[i].$2,
                label: _items[i].$3,
                selected: shell.currentIndex == i,
                onTap: () => shell.goBranch(i,
                    initialLocation: i == shell.currentIndex),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textSubtle;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.caption.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
