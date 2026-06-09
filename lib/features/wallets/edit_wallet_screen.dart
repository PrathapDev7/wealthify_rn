import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallets_repository.dart';
import '../auth/auth_screen.dart';

/// Wallet kinds with their segmented-control label + icon (mirrors RN
/// `KIND_OPTIONS`).
const _kindOptions = <(String, String, IconData)>[
  ('cash', 'Cash', Icons.payments_outlined),
  ('bank', 'Bank', Icons.account_balance_outlined),
  ('card', 'Card', Icons.credit_card),
  ('wallet', 'Wallet', Icons.account_balance_wallet_outlined),
];

class EditWalletScreen extends ConsumerStatefulWidget {
  const EditWalletScreen({super.key, this.wallet});

  final WalletModel? wallet;

  @override
  ConsumerState<EditWalletScreen> createState() => _EditWalletScreenState();
}

class _EditWalletScreenState extends ConsumerState<EditWalletScreen> {
  late final TextEditingController _name;
  late final TextEditingController _openingBalance;
  late String _kind;
  bool _saving = false;

  bool get _isEdit => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _name = TextEditingController(text: w?.name ?? '');
    _openingBalance = TextEditingController(
        text: w == null ? '' : '${w.openingBalance}');
    _kind = w?.kind ?? 'cash';
  }

  @override
  void dispose() {
    _name.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a name', error: true);
      return;
    }
    final opening = num.tryParse(_openingBalance.text.trim()) ?? 0;
    final data = <String, dynamic>{
      'name': name,
      'kind': _kind,
      'openingBalance': opening,
    };
    setState(() => _saving = true);
    try {
      final repo = ref.read(walletsRepositoryProvider);
      if (_isEdit) {
        await repo.updateWallet(widget.wallet!.id, data);
      } else {
        await repo.addWallet(data);
      }
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Wallet updated' : 'Wallet added');
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Delete wallet',
            style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Delete this wallet? Its transactions are kept but it will be archived.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(walletsRepositoryProvider).deleteWallet(widget.wallet!.id);
      if (!mounted) return;
      showAppSnack(context, 'Wallet deleted');
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: _isEdit ? 'Edit wallet' : 'Add wallet'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                AppCard(
                  child: AppTextField(
                    controller: _name,
                    label: 'Name',
                    hint: 'e.g. Everyday cash',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            for (final (value, label, icon) in _kindOptions)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _kind = value),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _kind == value
                                          ? c.primary
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.xs),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(icon,
                                            size: 15,
                                            color: _kind == value
                                                ? c.textInverse
                                                : c.textSubtle),
                                        const SizedBox(width: 6),
                                        Text(
                                          label,
                                          style: AppText.bodySm.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: _kind == value
                                                ? c.textInverse
                                                : c.textSubtle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: AppTextField(
                    controller: _openingBalance,
                    label: 'Opening balance',
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: _isEdit ? 'Save changes' : 'Add wallet',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: c.negative, size: 18),
                    label: Text('Delete wallet',
                        style: AppText.button.copyWith(color: c.negative)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
