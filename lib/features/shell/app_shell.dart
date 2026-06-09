import 'package:flutter/material.dart';
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
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AddOption(
                icon: Icons.arrow_upward,
                color: c.negative,
                label: 'Add Expense',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('${Routes.addTransaction}?type=expense');
                },
              ),
              _AddOption(
                icon: Icons.arrow_downward,
                color: c.accentDark,
                label: 'Add Income',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('${Routes.addTransaction}?type=income');
                },
              ),
              _AddOption(
                icon: Icons.pie_chart_outline,
                color: c.primary,
                label: 'Set Budget',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(Routes.setBudget);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color)),
      title: Text(label, style: AppText.bodyMedium.copyWith(color: c.text)),
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
