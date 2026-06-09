import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/provider_catalog.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallets_repository.dart';
import '../auth/auth_screen.dart';
import '../auth/session_controller.dart';
import 'wallet_ui.dart';
import 'widgets/provider_chips.dart';
import 'widgets/wallet_card_visual.dart';

const _kindOptions = <(String, String, IconData)>[
  ('cash', 'Cash', Icons.payments_outlined),
  ('bank', 'Bank', Icons.account_balance_outlined),
  ('card', 'Card', Icons.credit_card),
  ('wallet', 'Wallet', Icons.account_balance_wallet_outlined),
];

const _cardTypeOptions = <(String, String, IconData)>[
  ('credit', 'Credit', Icons.credit_card),
  ('debit', 'Debit', Icons.payment_outlined),
];

class EditWalletScreen extends ConsumerStatefulWidget {
  const EditWalletScreen({super.key, this.wallet});

  final WalletModel? wallet;

  @override
  ConsumerState<EditWalletScreen> createState() => _EditWalletScreenState();
}

class _EditWalletScreenState extends ConsumerState<EditWalletScreen> {
  late final TextEditingController _name;
  late final TextEditingController _holder;
  late final TextEditingController _last4;
  late final TextEditingController _expiry;
  late final TextEditingController _billDay;
  late final TextEditingController _openingBalance;
  late String _kind;
  String _cardType = '';
  FinProvider? _provider;
  bool _saving = false;

  bool get _isEdit => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _kind = w?.kind ?? 'cash';
    _provider = providerById(w?.provider);
    _cardType = w?.cardType ?? '';
    _name = TextEditingController(text: w?.name ?? '');
    _holder = TextEditingController(text: w?.holderName ?? '');
    _last4 = TextEditingController(text: w?.last4 ?? '');
    _expiry = TextEditingController(text: w?.expiry ?? '');
    _billDay = TextEditingController(text: w?.reminderDay?.toString() ?? '');
    _openingBalance =
        TextEditingController(text: w == null ? '' : '${w.openingBalance}');
  }

  String get _profileName =>
      ref.read(sessionProvider).asData?.value?.username ?? '';

  @override
  void dispose() {
    _name.dispose();
    _holder.dispose();
    _last4.dispose();
    _expiry.dispose();
    _billDay.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  void _setKind(String kind) {
    setState(() {
      _kind = kind;
      if (kind == 'cash') {
        _provider = null;
        if (_name.text.trim().isEmpty) _name.text = 'Cash';
      } else if (_provider != null &&
          _provider!.type != providerTypeForKind(kind)) {
        _provider = null;
      }
    });
  }

  Future<void> _pickProvider() async {
    final type = providerTypeForKind(_kind);
    final picked =
        await context.push<FinProvider>('${Routes.selectProvider}?type=$type');
    if (picked == null || !mounted) return;
    _selectProvider(picked);
  }

  void _selectProvider(FinProvider p) {
    setState(() {
      final prevName = _provider?.name;
      _provider = p;
      // Auto-fill the name when it's blank or still the previous provider's.
      if (_name.text.trim().isEmpty || _name.text.trim() == prevName) {
        _name.text = p.name;
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a name', error: true);
      return;
    }
    final opening = num.tryParse(_openingBalance.text.trim()) ?? 0;
    final last4 = _last4.text.trim();
    final billDay = int.tryParse(_billDay.text.trim());
    final data = <String, dynamic>{
      'name': name,
      'kind': _kind,
      'openingBalance': opening,
      'provider': _provider?.id ?? '',
      'providerName': _provider?.name ?? '',
      'color': _provider != null ? hexFromColor(_provider!.color) : '',
      'cardType': _kind == 'card' ? _cardType : '',
      'last4': _kind == 'cash' ? '' : last4,
      'holderName': _holder.text.trim(),
      'reminderDay': _kind == 'card' ? billDay : null,
      'expiry': _kind == 'card' ? _expiry.text.trim() : '',
    };
    setState(() => _saving = true);
    try {
      final repo = ref.read(walletsRepositoryProvider);
      if (_isEdit) {
        await repo.updateWallet(widget.wallet!.id, data);
      } else {
        await repo.addWallet(data);
      }
      ref.invalidate(walletsListProvider);
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
      ref.invalidate(walletsListProvider);
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
    final isCash = _kind == 'cash';
    final isCard = _kind == 'card';
    final providerType = providerTypeForKind(_kind);
    final identityLabel = switch (_kind) {
      'card' => 'Card issuer',
      'wallet' => 'Wallet',
      _ => 'Bank',
    };

    // Live preview built from the current form state.
    final preview = WalletModel(
      id: '',
      name: _name.text.trim().isEmpty
          ? (_provider?.name ?? kindLabel(_kind))
          : _name.text.trim(),
      kind: _kind,
      provider: _provider?.id,
      providerName: _provider?.name,
      color:
          _provider != null ? hexFromColor(_provider!.color) : widget.wallet?.color,
      cardType: isCard && _cardType.isNotEmpty ? _cardType : null,
      last4: _last4.text.trim().isEmpty ? null : _last4.text.trim(),
      holderName: _holder.text.trim().isEmpty ? null : _holder.text.trim(),
    );

    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: _isEdit ? 'Edit wallet' : 'Add wallet'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                WalletCardVisual(wallet: preview, holderFallback: _profileName),
                const SizedBox(height: AppSpacing.xl),

                // 1) Type — first.
                _label(context, 'Type'),
                const SizedBox(height: AppSpacing.sm),
                _Segmented(
                  options: _kindOptions,
                  selected: _kind,
                  onChanged: _saving ? null : _setKind,
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2) Identity — conditional on type.
                if (!isCash) ...[
                  _label(context, identityLabel),
                  const SizedBox(height: AppSpacing.sm),
                  ProviderChips(
                    type: providerType,
                    selectedId: _provider?.id,
                    enabled: !_saving,
                    onSelect: _selectProvider,
                    onMore: _pickProvider,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                AppTextField(
                  controller: _name,
                  label: 'Name',
                  hint: isCash ? 'e.g. Everyday cash' : 'e.g. HDFC Salary',
                  onChanged: (_) => setState(() {}),
                ),

                if (isCard) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _label(context, 'Card type'),
                  const SizedBox(height: AppSpacing.sm),
                  _Segmented(
                    options: _cardTypeOptions,
                    selected: _cardType,
                    onChanged:
                        _saving ? null : (v) => setState(() => _cardType = v),
                  ),
                ],

                if (!isCash) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _last4,
                    label: 'Last 4 digits (optional)',
                    hint: 'xxxx',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text('Just for your reference — not your full number.',
                      style: AppText.caption.copyWith(color: c.textSubtle)),
                ],

                if (isCard) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _expiry,
                          label: 'Expiry (optional)',
                          hint: 'MM/YY',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          controller: _billDay,
                          label: 'Bill day (optional)',
                          hint: '1-31',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                      'Set a bill day to get a monthly reminder (needs bill reminders on).',
                      style: AppText.caption.copyWith(color: c.textSubtle)),
                ],

                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _holder,
                  label: 'Holder name (optional)',
                  hint: _profileName.isEmpty ? 'Account holder' : _profileName,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _openingBalance,
                  label: 'Opening balance',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),

                const SizedBox(height: AppSpacing.xl),
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

  Widget _label(BuildContext context, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: AppText.label.copyWith(color: context.colors.textSubtle)),
      );
}

/// Generic segmented control (value, label, icon) used for type + card-type.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, String, IconData)> options;
  final String selected;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          for (final (value, label, icon) in options)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        selected == value ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 15,
                          color: selected == value
                              ? c.textInverse
                              : c.textSubtle),
                      const SizedBox(width: 6),
                      Text(label,
                          style: AppText.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected == value
                                ? c.textInverse
                                : c.textSubtle,
                          )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
