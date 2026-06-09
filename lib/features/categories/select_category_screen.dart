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

/// Recent + merged grid options for [type], resolved together so the screen can
/// show a recents chip row and the full grid from a single load.
typedef CategoryOptions = ({List<String> recent, List<String> grid});

/// Recents (from `getRecentCategories`) plus the merged grid: the user's saved
/// categories first, then the curated defaults — deduped by lowercased title,
/// with `Other` pushed to the end (mirrors RN `mergedCategories`).
final categoryOptionsProvider =
    FutureProvider.autoDispose.family<CategoryOptions, String>((ref, type) async {
  final repo = ref.read(categoriesRepositoryProvider);
  final recentsFuture = repo.getRecentCategories(type);
  final categoriesFuture = repo.getCategories(type);
  final recents = await recentsFuture;
  final categories = await categoriesFuture;

  final beTitles = categories.map((c) => c.title).toList();
  final beSeen = beTitles.map((t) => t.toLowerCase()).toSet();
  final fallback = kDefaultCategories[type] ?? const [];

  // BE entries win on conflict; defaults fill the gaps. Keep `Other` last.
  final ordered = <String>[
    ...beTitles,
    ...fallback.where((t) => !beSeen.contains(t.toLowerCase())),
  ];
  final seen = <String>{};
  final grid = <String>[];
  for (final title in ordered) {
    final label = title.trim();
    if (label.isEmpty) continue;
    if (seen.add(label.toLowerCase())) grid.add(label);
  }
  grid.sort((a, b) {
    final aOther = a.toLowerCase() == 'other';
    final bOther = b.toLowerCase() == 'other';
    if (aOther && !bOther) return 1;
    if (!aOther && bOther) return -1;
    return 0;
  });

  final recentSeen = <String>{};
  final recent = <String>[];
  for (final title in recents) {
    final label = title.trim();
    if (label.isEmpty) continue;
    if (recentSeen.add(label.toLowerCase())) recent.add(label);
  }

  return (recent: recent, grid: grid);
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
          ScreenHeader(
            title: _income
                ? 'Select Income Category'
                : 'Select Expense Category',
          ),
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
              data: (options) {
                final q = _query.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? options.grid
                    : options.grid
                        .where((c) => c.toLowerCase().contains(q))
                        .toList();
                // Recents are only shown when not actively searching.
                final recent = q.isEmpty ? options.recent : const <String>[];

                if (filtered.isEmpty && recent.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    title: 'No categories found',
                    message: 'Try a different search term.',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recent.isNotEmpty) ...[
                        Text('Recent',
                            style: AppText.label
                                .copyWith(color: context.colors.textSubtle)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final name in recent)
                              AppChip(
                                label: name,
                                icon: Icons.history,
                                onTap: () => context.pop(name),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Wrap(
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
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: c.border),
              ),
              alignment: Alignment.center,
              child: WealthifyIcon(spec.name, size: 36),
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
