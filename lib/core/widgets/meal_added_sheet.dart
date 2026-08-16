import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/calorie_entry.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'buttons.dart';

/// Success sheet shown after a meal is logged — lists the parsed items with
/// their nutrition breakdown. Shared between the full Calorie Tracker screen
/// and the shell's Quick Add "What Did You Eat?" flow so both end the same way.
class MealAddedSheet extends StatelessWidget {
  final List<MealItem> items;

  /// When set, the sheet shows this message instead of nutrition cards —
  /// used when every parsing model failed and the entry is still 'pending'.
  final String? pendingMessage;

  const MealAddedSheet({super.key, required this.items, this.pendingMessage});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isPending = pendingMessage != null;
    final totalCalories = items.fold<int>(0, (sum, m) => sum + m.calories);

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottom + AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                  child: Icon(
                    isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                    color: c.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isPending ? 'Meal saved' : 'Meal added', style: AppText.title.copyWith(color: c.text)),
                      Text(
                        isPending ? 'Nutrition info on its way' : '$totalCalories kcal logged',
                        style: AppText.bodySm.copyWith(color: c.textSubtle),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: c.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isPending)
              Text(pendingMessage!, style: AppText.bodyMedium.copyWith(color: c.textSubtle))
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                NutrientDetailCard(item: items[i]),
              ],
            const SizedBox(height: AppSpacing.xl),
            PillButton(label: 'Done', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }
}

class NutrientDetailCard extends StatelessWidget {
  final MealItem item;

  const NutrientDetailCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.foodName,
                        style: AppText.bodyMedium.copyWith(color: c.text, fontWeight: FontWeight.w700)),
                    if (item.portion != null && item.portion!.isNotEmpty)
                      Text(item.portion!, style: AppText.caption.copyWith(color: c.textSubtle)),
                  ],
                ),
              ),
              Text('${item.calories} kcal',
                  style: AppText.bodyMedium.copyWith(color: c.warning, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _NutrientPill(label: 'Protein', value: '${item.protein.round()}g', color: c.blue),
              _NutrientPill(label: 'Carbs', value: '${item.carbs.round()}g', color: c.accentDark),
              _NutrientPill(label: 'Fat', value: '${item.fat.round()}g', color: c.warning),
              _NutrientPill(label: 'Fiber', value: '${item.fiber.round()}g', color: c.cyan),
              _NutrientPill(label: 'Sugar', value: '${item.sugar.round()}g', color: c.pink),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrientPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration:
          BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text('$label: $value', style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
