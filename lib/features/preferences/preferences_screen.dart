import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/widgets.dart';
import 'preferences_controller.dart';

/// App-wide preferences: appearance (theme), currency, transaction defaults and
/// calendar week start. Mirrors `legacy_rn/app/preferences.tsx`.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final mode = ref.watch(themeControllerProvider);
    final prefs = ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Preferences'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                // Appearance
                _SectionLabel('Appearance'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme',
                          style: AppText.bodyMedium.copyWith(color: c.text)),
                      const SizedBox(height: AppSpacing.md),
                      _Segmented<ThemeMode>(
                        value: mode,
                        onChanged: (m) => ref
                            .read(themeControllerProvider.notifier)
                            .setMode(m),
                        options: const [
                          _SegOption(ThemeMode.light, 'Light',
                              icon: Icons.light_mode_outlined),
                          _SegOption(ThemeMode.dark, 'Dark',
                              icon: Icons.dark_mode_outlined),
                          _SegOption(ThemeMode.system, 'System',
                              icon: Icons.phone_iphone),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Currency
                _SectionLabel('Currency'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Symbol',
                              style:
                                  AppText.bodyMedium.copyWith(color: c.text)),
                          Text(money(1234.5),
                              style: AppText.bodyStrong
                                  .copyWith(color: c.primary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (final cur in _currencies) ...[
                            if (cur != _currencies.first)
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _CurrencyTile(
                                symbol: cur.symbol,
                                code: cur.code,
                                selected: cur.code == prefs.currencyCode,
                                onTap: () => ref
                                    .read(preferencesProvider.notifier)
                                    .update(prefs.copyWith(
                                      currencySymbol: cur.symbol,
                                      currencyCode: cur.code,
                                    )),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Defaults
                _SectionLabel('Defaults'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New transaction type',
                          style: AppText.bodyMedium.copyWith(color: c.text)),
                      const SizedBox(height: AppSpacing.md),
                      _Segmented<String>(
                        value: prefs.defaultTxnType,
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .update(prefs.copyWith(defaultTxnType: v)),
                        options: const [
                          _SegOption('expense', 'Expense',
                              icon: Icons.arrow_upward),
                          _SegOption('income', 'Income',
                              icon: Icons.arrow_downward),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Calendar
                _SectionLabel('Calendar'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Week starts on',
                          style: AppText.bodyMedium.copyWith(color: c.text)),
                      const SizedBox(height: AppSpacing.md),
                      _Segmented<String>(
                        value: prefs.weekStart,
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .update(prefs.copyWith(weekStart: v)),
                        options: const [
                          _SegOption('monday', 'Monday'),
                          _SegOption('sunday', 'Sunday'),
                        ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: AppText.label.copyWith(color: c.textSubtle)),
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption(this.symbol, this.code);
  final String symbol;
  final String code;
}

const _currencies = <_CurrencyOption>[
  _CurrencyOption('₹', 'INR'),
  _CurrencyOption('\$', 'USD'),
  _CurrencyOption('€', 'EUR'),
  _CurrencyOption('£', 'GBP'),
];

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.symbol,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Column(
          children: [
            Text(symbol,
                style: AppText.title
                    .copyWith(color: selected ? c.textInverse : c.text)),
            const SizedBox(height: 2),
            Text(code,
                style: AppText.caption.copyWith(
                    color: selected ? c.textInverse : c.textSubtle)),
          ],
        ),
      ),
    );
  }
}

class _SegOption<T> {
  const _SegOption(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Reusable segmented control. The active segment uses the primary fill with
/// inverse text; inactive segments are transparent over a muted track.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<_SegOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          for (final opt in options) ...[
            if (opt != options.first) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt.value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: opt.value == value ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (opt.icon != null) ...[
                        Icon(
                          opt.icon,
                          size: 15,
                          color: opt.value == value
                              ? c.textInverse
                              : c.textSubtle,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          opt.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: opt.value == value
                                ? c.textInverse
                                : c.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
