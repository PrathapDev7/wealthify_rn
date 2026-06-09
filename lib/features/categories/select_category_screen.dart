import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/repositories/categories_repository.dart';

/// Curated fallback suggestions, copied 1:1 from
/// `legacy_rn/src/utils/defaultCategories.ts`. Shown so the picker is never
/// empty and new users see useful options immediately; tapping one just returns
/// the label, it isn't auto-persisted.
const Map<String, List<String>> kDefaultCategories = {
  'expense': [
    'Groceries',
    'Food',
    'Travel',
    'Transport',
    'Fuel',
    'Rent',
    'Home',
    'Shopping',
    'Bills',
    'Electricity',
    'Gas',
    'Internet',
    'Mobile',
    'Healthcare',
    'Insurance',
    'Education',
    'Entertainment',
    'Gym',
    'Subscription',
    'Gifts',
    'Other',
  ],
  'income': [
    'Salary',
    'Bonus',
    'Freelance',
    'Business',
    'Commission',
    'Investment',
    'Rental Income',
    'Interest',
    'Refund',
    'Gift',
    'Other',
  ],
};

/// Merged category list for [type]: recents first, then the user's saved
/// categories, then the curated defaults — deduped by lowercased title,
/// preserving that order.
final categoryOptionsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, type) async {
  final repo = ref.read(categoriesRepositoryProvider);
  final recentsFuture = repo.getRecentCategories(type);
  final categoriesFuture = repo.getCategories(type);
  final recents = await recentsFuture;
  final categories = await categoriesFuture;

  final ordered = <String>[
    ...recents,
    ...categories.map((c) => c.title),
    ...(kDefaultCategories[type] ?? const []),
  ];

  final seen = <String>{};
  final deduped = <String>[];
  for (final title in ordered) {
    final label = title.trim();
    if (label.isEmpty) continue;
    if (seen.add(label.toLowerCase())) deduped.add(label);
  }
  return deduped;
});

class SelectCategoryScreen extends ConsumerStatefulWidget {
  const SelectCategoryScreen({super.key, required this.type});

  /// 'expense' | 'income'
  final String type;

  @override
  ConsumerState<SelectCategoryScreen> createState() =>
      _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends ConsumerState<SelectCategoryScreen> {
  final _search = TextEditingController();
  String _query = '';

  bool get _income => widget.type == 'income';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoryOptionsProvider(widget.type));

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Select Category'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppTextField(
              controller: _search,
              hint: _income
                  ? 'Search for income categories'
                  : 'Search for expense categories',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (_, _) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load categories',
              ),
              data: (categories) {
                final q = _query.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? categories
                    : categories
                        .where((c) => c.toLowerCase().contains(q))
                        .toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    title: 'No categories found',
                    message: 'Try a different search term.',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl5),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.lg,
                    children: [
                      for (final name in filtered)
                        _CategoryTile(
                          name: name,
                          income: _income,
                          onTap: () => context.pop(name),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.income,
    required this.onTap,
  });

  final String name;
  final bool income;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = resolveCategoryIcon(name, income: income, colors: c);
    // 4-up grid: full width minus the two run gaps, split four ways.
    final tileWidth =
        (MediaQuery.sizeOf(context).width - AppSpacing.xl * 2 - AppSpacing.md * 3) /
            4;

    return SizedBox(
      width: tileWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: tileWidth,
              height: tileWidth,
              decoration: BoxDecoration(
                color: spec.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: WealthifyIcon(spec.name, size: 28),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
