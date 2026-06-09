import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/widgets/widgets.dart';
import '../../categories/select_category_screen.dart';

/// Horizontal strip of popular categories (recents + saved + defaults, deduped)
/// plus a "More" chip that opens the full picker. Shared by the add + edit
/// transaction screens so both offer the same quick icon picker.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({
    super.key,
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onMore,
  });

  final String type; // 'income' | 'expense'
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(categoryOptionsProvider(type));
    final income = type == 'income';

    final options = async.maybeWhen(
      data: (o) => [...o.recent, ...o.grid],
      orElse: () => <String>[],
    );

    // Dedupe, keep current selection in view, cap to 6.
    final seen = <String>{};
    final popular = <String>[];
    for (final name in [
      if (selected.trim().isNotEmpty) selected.trim(),
      ...options,
    ]) {
      final label = name.trim();
      if (label.isEmpty) continue;
      if (seen.add(label.toLowerCase())) popular.add(label);
    }
    final visible = popular.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final name in visible) ...[
            Builder(builder: (_) {
              final spec = resolveCategoryIcon(name, income: income, colors: c);
              return AppChip(
                label: name,
                selected: name.toLowerCase() == selected.toLowerCase(),
                onTap: enabled ? () => onSelect(name) : null,
                leading: WealthifyIcon(spec.name, size: 15),
              );
            }),
            const SizedBox(width: AppSpacing.sm),
          ],
          AppChip(
            label: 'More',
            icon: Icons.more_horiz,
            onTap: enabled ? onMore : null,
          ),
        ],
      ),
    );
  }
}
