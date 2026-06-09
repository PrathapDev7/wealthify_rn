import 'package:flutter/material.dart';

import '../../../core/data/provider_catalog.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// Horizontal strip of popular [FinProvider]s (plus the current selection) and a
/// "More" chip that opens the full searchable picker. Mirrors the transaction
/// category chips for a familiar interaction.
class ProviderChips extends StatelessWidget {
  const ProviderChips({
    super.key,
    required this.type, // 'bank' | 'wallet'
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
    required this.onMore,
  });

  final String type;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<FinProvider> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final popular = popularProviders(type);
    final selected = providerById(selectedId);
    final list = <FinProvider>[
      if (selected != null && !popular.any((p) => p.id == selected.id))
        selected,
      ...popular,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in list) ...[
            AppChip(
              label: p.name,
              selected: p.id == selectedId,
              onTap: enabled ? () => onSelect(p) : null,
              leading: ProviderAvatar(provider: p, size: 18),
            ),
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
