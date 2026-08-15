import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/calorie_entry.dart';
import '../../data/models/wishlist_item_model.dart';
import '../../data/repositories/wishlist_repository.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onPressed: () => _showAddSheet(context, ref),
        ),
      ),
      bottomNavigationBar: _NavBar(shell: navigationShell),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final activeApp = ref.read(activeAppProvider);
    final isWealthify = activeApp == ActiveApp.wealthify;
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
                if (isWealthify) ...[
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
                ],
                _QuickAddCard(
                  icon: Icons.bookmark_rounded,
                  color: c.pink,
                  label: 'Add to Wishlist',
                  subtitle: 'Save something you want to buy',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _quickAddWishlistItem(context, ref);
                  },
                ),
                if (!isWealthify) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _QuickAddCard(
                    icon: Icons.restaurant_rounded,
                    color: c.warning,
                    label: 'What Did You Eat?',
                    subtitle: 'Track what you ate today',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _quickLogMeal(context, ref);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickAddCard(
                    icon: Icons.monitor_weight_rounded,
                    color: c.info,
                    label: 'Weight Today?',
                    subtitle: "Log today's weight",
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _quickLogWeight(context, ref);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickAddWishlistItem(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<WishlistItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(
        icon: Icons.bookmark_rounded,
        color: context.colors.pink,
        title: 'Add to Wishlist',
        subtitle: 'Save something you want to buy later',
        fieldLabel: 'Item name',
        fieldHint: 'What do you want to buy?',
        buttonLabel: 'Save item',
        emptyErrorText: 'Item name is required',
        onSubmit: (ctx, value) async {
          final item = WishlistItemModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: value,
            estimatedAmount: null,
            priority: 'Medium',
            category: 'Other',
            targetDate: null,
            notes: '',
            isPurchased: false,
            createdAt: DateTime.now(),
          );
          await ref.read(wishlistRepositoryProvider).saveItem(item);
          return item;
        },
      ),
    );
    if (result != null && context.mounted) {
      showAppSnack(context, 'Added to wishlist');
    }
  }

  Future<void> _quickLogMeal(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({List<MealItem> items, String? pendingMessage})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(
        icon: Icons.restaurant_rounded,
        color: context.colors.warning,
        title: 'What Did You Eat?',
        subtitle: 'Tell us what you had — we\'ll work out the rest',
        fieldHint: 'e.g. 100g peanuts, 2 eggs, 200g rice',
        maxLines: 2,
        buttonLabel: 'Save Meal',
        emptyErrorText: 'Please enter what you ate',
        loadingMessages: const [
          'Analyzing your food entry...',
          'Identifying ingredients...',
          'Calculating nutrition values...',
          'Almost done...',
        ],
        onSubmit: (ctx, value) async {
          final repo = ref.read(caloriesRepositoryProvider);
          final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final addRes = await repo.addCaloriesEntry(date: dateStr);
          final entryId = addRes['entryId'] as String?;
          if (entryId == null) {
            throw Exception('Could not start meal entry. Please try again.');
          }
          final processed = await repo.processFoodText(entryId, value);
          final items = (processed['addedItems'] as List?)
                  ?.map((m) => MealItem.fromJson(m as Map<String, dynamic>))
                  .toList() ??
              <MealItem>[];
          final pendingMessage = processed['status'] == 'pending'
              ? processed['message'] as String? ?? 'Nutrition data will be added shortly.'
              : null;
          return (items: items, pendingMessage: pendingMessage);
        },
      ),
    );
    if (result != null && (result.items.isNotEmpty || result.pendingMessage != null) && context.mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MealAddedSheet(items: result.items, pendingMessage: result.pendingMessage),
      );
    }
  }

  Future<void> _quickLogWeight(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(
        icon: Icons.monitor_weight_rounded,
        color: context.colors.info,
        title: 'Weight Today?',
        subtitle: "Log today's weight — logging again today just updates it",
        fieldLabel: 'Weight (kg)',
        fieldHint: 'e.g. 72.5',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        buttonLabel: 'Log weight',
        emptyErrorText: 'Enter a valid weight',
        onSubmit: (ctx, value) async {
          final weightKg = double.tryParse(value);
          if (weightKg == null || weightKg <= 0) {
            throw Exception('Enter a valid weight');
          }
          return ref.read(caloriesRepositoryProvider).addWeightEntry(weightKg: weightKg);
        },
      ),
    );
    if (result != null && context.mounted) {
      showAppSnack(context, 'Weight logged');
    }
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
