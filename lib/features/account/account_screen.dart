import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../auth/session_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(sessionProvider).asData?.value;
    final initials = (user?.username ?? '?')
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
      children: [
        Center(
            child: Text('Account',
                style: AppText.screenTitle.copyWith(color: c.text))),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [c.primaryGradientStart, c.primaryGradientEnd]),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                    child: Text(initials.isEmpty ? '?' : initials,
                        style: AppText.title.copyWith(color: Colors.white))),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.username ?? '—',
                        style: AppText.bodyMedium.copyWith(color: c.text)),
                    Text('+91 ${user?.mobile ?? '—'}',
                        style: AppText.bodySm.copyWith(color: c.textSubtle)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => context.push(Routes.premium),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [c.primaryGradientStart, c.primaryGradientEnd]),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium Account',
                          style: AppText.subtitle.copyWith(color: Colors.white)),
                      Text('Unlock advanced insights',
                          style: AppText.caption
                              .copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        _section(c, 'Money'),
        _group(context, c, [
          (Icons.pie_chart_outline, 'Budgets', Routes.budgets),
          (Icons.sell_outlined, 'Manage Categories', Routes.manageCategories),
          (Icons.autorenew, 'Recurring', Routes.recurring),
          (Icons.flag_outlined, 'Savings Goals', Routes.goals),
          (Icons.account_balance_wallet_outlined, 'Wallets', Routes.wallets),
        ]),
        _section(c, 'Reports & Insights'),
        _group(context, c, [
          (Icons.insights_outlined, 'Insights', Routes.insights),
          (Icons.description_outlined, 'Reports & Export', Routes.reports),
        ]),
        _section(c, 'Settings'),
        _group(context, c, [
          (Icons.settings_outlined, 'Preferences', Routes.preferences),
          (Icons.notifications_outlined, 'Reminders', Routes.notifications),
          (Icons.lock_outline, 'App Lock', Routes.security),
        ]),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
          icon: Icon(Icons.logout, color: c.negative, size: 18),
          label: Text('Logout', style: AppText.button.copyWith(color: c.negative)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: c.negativeSoft),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill)),
          ),
        ),
      ],
    );
  }

  Widget _section(AppColors c, String label) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl2, bottom: AppSpacing.sm),
        child: Text(label, style: AppText.label.copyWith(color: c.textSubtle)),
      );

  Widget _group(BuildContext context, AppColors c,
      List<(IconData, String, String)> rows) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            ListTile(
              leading: Icon(rows[i].$1, color: c.text),
              title: Text(rows[i].$2,
                  style: AppText.bodyMedium.copyWith(color: c.text)),
              trailing: Icon(Icons.chevron_right, color: c.textSubtle),
              onTap: () => context.push(rows[i].$3),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, color: c.divider, indent: 56),
          ],
        ],
      ),
    );
  }
}
