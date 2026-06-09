import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// Premium upsell screen: a gradient hero card, the feature list and an
/// upgrade CTA. Purely presentational for now (no billing wired up).
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  static const _features = <String>[
    'Advanced insights & trends',
    'Unlimited budgets',
    'Export to CSV & PDF',
    'Priority support',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Premium'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                // Gradient hero card.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.primaryGradientStart, c.primaryGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.diamond_outlined,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Wealthify Premium',
                          textAlign: TextAlign.center,
                          style: AppText.title.copyWith(color: Colors.white)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Unlock the full power of your money.',
                        textAlign: TextAlign.center,
                        style:
                            AppText.bodySm.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Feature list.
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("What's included",
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < _features.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.13),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check,
                                  size: 16, color: c.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(_features[i],
                                  style: AppText.bodyMedium
                                      .copyWith(color: c.text)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),

                PillButton(
                  label: 'Upgrade',
                  leading: const Icon(Icons.diamond_outlined,
                      color: Colors.white, size: 18),
                  onPressed: () => showAppSnack(context, 'Coming soon'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
