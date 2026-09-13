import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../core/providers.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/transfers_repository.dart';
import '../../data/repositories/wallets_repository.dart';
import '../auth/auth_screen.dart';
import 'widgets/wallet_picker.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  List<WalletModel> _wallets = const [];
  String? _fromId;
  String? _toId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _note = TextEditingController();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await ref.read(walletsRepositoryProvider).getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        if (wallets.length >= 2) {
          _fromId ??= wallets[0].id;
          _toId ??= wallets[1].id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    if (_fromId == null || _toId == null) {
      showAppSnack(context, 'Select both wallets', error: true);
      return;
    }
    if (_fromId == _toId) {
      showAppSnack(context, 'Wallets must be different', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(transfersRepositoryProvider).addTransfer({
        'fromWallet': _fromId,
        'toWallet': _toId,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      ref.invalidate(walletsListProvider);
      ref.read(dataRefreshProvider.notifier).bump();
      if (!mounted) return;
      showAppSnack(context, 'Transfer added');
      context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Transfer'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _amount,
                        label: 'Amount',
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('From',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      WalletPicker(
                        wallets: _wallets,
                        selectedId: _fromId,
                        enabled: !_saving,
                        showNone: false,
                        onSelect: (id) => setState(() => _fromId = id),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('To',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      WalletPicker(
                        wallets: _wallets,
                        selectedId: _toId,
                        enabled: !_saving,
                        showNone: false,
                        onSelect: (id) => setState(() => _toId = id),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _note,
                        label: 'Note (optional)',
                        hint: 'Add a note',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.inputBackground,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: c.inputBorder),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: c.textSubtle),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                DateFormat('dd MMM yyyy').format(_date),
                                style: AppText.body.copyWith(color: c.text),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: 'Transfer',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
