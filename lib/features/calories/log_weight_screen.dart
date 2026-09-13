import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// Deep-linkable weight logger: the "Log Weight" quick action and the
/// home-screen widget both land here. Reuses the same add-weight-entry API
/// the Quick Add sheet uses, so logging twice in a day still updates.
class LogWeightScreen extends ConsumerStatefulWidget {
  const LogWeightScreen({super.key});

  @override
  ConsumerState<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends ConsumerState<LogWeightScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  double? _latestKg;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    try {
      final res =
          await ref.read(caloriesRepositoryProvider).getWeightHistory();
      final entries = (res['entries'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _latestKg = entries.isNotEmpty
            ? (entries.last['weightKg'] as num?)?.toDouble()
            : (res['currentWeightKg'] as num?)?.toDouble();
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    final weightKg = double.tryParse(_controller.text.trim());
    if (weightKg == null || weightKg <= 0) {
      showAppSnack(context, 'Enter a valid weight', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(caloriesRepositoryProvider)
          .addWeightEntry(weightKg: weightKg);
      ref.read(dataRefreshProvider.notifier).bump();
      if (!mounted) return;
      showAppSnack(context, 'Weight logged');
      context.pop();
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final latest = _latestKg == null
        ? null
        : 'Latest: ${_latestKg!.toStringAsFixed(1)} kg';
    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Log Weight'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.screenBottomInset,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.info.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.monitor_weight_rounded,
                              color: c.info,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE, d MMM',
                                  ).format(DateTime.now()),
                                  style: AppText.bodyMedium.copyWith(
                                    color: c.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (latest != null)
                                  Text(
                                    latest,
                                    style: AppText.bodySm.copyWith(
                                      color: c.textSubtle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _controller,
                        label: 'Weight (kg)',
                        hint: 'e.g. 72.5',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.monitor_weight_outlined,
                        readOnly: _saving,
                        autofocus: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'Log weight',
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Logging again today just updates it.',
                        style: AppText.caption.copyWith(color: c.textSubtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
