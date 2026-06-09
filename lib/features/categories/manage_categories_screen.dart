import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';

/// Categories for the active type ('expense' | 'income').
final categoriesByTypeProvider =
    FutureProvider.autoDispose.family<List<CategoryModel>, String>((ref, type) {
  return ref.read(categoriesRepositoryProvider).getCategories(type);
});

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoriesByTypeProvider(_type));

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Manage Categories'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: AppChip(
                    label: 'Expense',
                    icon: Icons.arrow_upward,
                    selected: _type == 'expense',
                    onTap: () => setState(() => _type = 'expense'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppChip(
                    label: 'Income',
                    icon: Icons.arrow_downward,
                    selected: _type == 'income',
                    onTap: () => setState(() => _type = 'income'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () =>
                      ref.invalidate(categoriesByTypeProvider(_type)),
                ),
              ),
              data: (categories) => RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(categoriesByTypeProvider(_type).future),
                child: categories.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                        children: [
                          const SizedBox(height: AppSpacing.xl4),
                          EmptyState(
                            icon: Icons.sell_outlined,
                            title: 'No $_type categories yet',
                            message:
                                'Add a custom category with its own icon and color to organize your ${_type}s.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _addButton(context),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                        children: [
                          for (final category in categories) ...[
                            _CategoryRow(
                              category: category,
                              type: _type,
                              onTap: () => _openEdit(category),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          _addButton(context),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context) => PillButton(
        label: 'Add category',
        leading: Icon(Icons.add,
            size: 18, color: context.colors.textOnPrimary),
        onPressed: () => _openEdit(null),
      );

  Future<void> _openEdit(CategoryModel? category) async {
    await context.push(
      Routes.editCategory,
      extra: {'category': category, 'type': _type},
    );
    if (mounted) ref.invalidate(categoriesByTypeProvider(_type));
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.type,
    required this.onTap,
  });

  final CategoryModel category;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasCustomIcon =
        category.icon != null && category.icon!.startsWith('http');
    final tint = category.color != null && category.color!.isNotEmpty
        ? _parseHex(category.color!) ?? c.primary
        : c.primary;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: hasCustomIcon
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      category.icon!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => WealthifyIcon(
                        resolveCategoryIcon(category.title,
                                income: type == 'income', colors: c)
                            .name,
                        size: 28,
                      ),
                    ),
                  )
                : WealthifyIcon(
                    resolveCategoryIcon(category.title,
                            income: type == 'income', colors: c)
                        .name,
                    size: 28,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyMedium.copyWith(color: c.text),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: c.textSubtle),
        ],
      ),
    );
  }
}

/// Parses a '#RRGGBB' / '#AARRGGBB' hex string into a [Color].
Color? _parseHex(String hex) {
  var s = hex.replaceFirst('#', '').trim();
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}
