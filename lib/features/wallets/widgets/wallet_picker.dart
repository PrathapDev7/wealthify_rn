import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/wallet_model.dart';
import '../wallet_ui.dart';

/// Horizontal scroll of the user's wallets as branded chips (plus a "None"
/// option), used on the add/edit transaction screens to pick an account.
class WalletPicker extends StatelessWidget {
  const WalletPicker({
    super.key,
    required this.wallets,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  final List<WalletModel> wallets;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(
            label: 'None',
            selected: selectedId == null,
            onTap: enabled ? () => onSelect(null) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final w in wallets) ...[
            AppChip(
              label: w.name,
              selected: selectedId == w.id,
              onTap: enabled ? () => onSelect(w.id) : null,
              leading: walletAvatar(w, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
