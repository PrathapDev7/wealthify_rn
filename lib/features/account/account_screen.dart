import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/auth_screen.dart';
import '../auth/session_controller.dart';

/// Describes a single tappable row inside an [AppCard] group.
class _Row {
  const _Row(this.icon, this.label, this.onTap, {this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

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
              GestureDetector(
                onTap: () => _editName(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('Edit',
                      style: AppText.bodySm.copyWith(
                          color: c.primary, fontWeight: FontWeight.w600)),
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
        _group(c, [
          _Row(Icons.pie_chart_outline, 'Budgets',
              () => context.push(Routes.budgets)),
          _Row(Icons.sell_outlined, 'Manage Categories',
              () => context.push(Routes.manageCategories)),
          _Row(Icons.autorenew, 'Recurring',
              () => context.push(Routes.recurring)),
          _Row(Icons.flag_outlined, 'Savings Goals',
              () => context.push(Routes.goals)),
          _Row(Icons.account_balance_wallet_outlined, 'Wallets',
              () => context.push(Routes.wallets)),
        ]),
        _section(c, 'Reports & Insights'),
        _group(c, [
          _Row(Icons.insights_outlined, 'Insights',
              () => context.push(Routes.insights)),
          _Row(Icons.description_outlined, 'Reports & Export',
              () => context.push(Routes.reports)),
        ]),
        _section(c, 'Account Settings'),
        _group(c, [
          _Row(Icons.person_outline, 'Account Information',
              () => _editName(context, ref)),
          _Row(Icons.key_outlined, 'Change Password',
              () => _changePassword(context, ref)),
          _Row(Icons.phone_iphone_outlined, 'Device',
              () => showAppSnack(context, 'Coming soon')),
          _Row(Icons.business_outlined, 'Connect to Banks',
              () => showAppSnack(context, 'Coming soon')),
        ]),
        _section(c, 'Settings'),
        _group(c, [
          _Row(Icons.settings_outlined, 'Preferences',
              () => context.push(Routes.preferences)),
          _Row(Icons.notifications_outlined, 'Reminders',
              () => context.push(Routes.notifications)),
          _Row(Icons.lock_outline, 'App Lock',
              () => context.push(Routes.security)),
          _Row(Icons.delete_outline, 'Reset local app data',
              () => _resetLocalData(context, ref),
              danger: true),
          _Row(Icons.help_outline, 'Help & Support',
              () => showAppSnack(context, 'Coming soon')),
          _Row(Icons.info_outline, 'About', () => _about(context)),
        ]),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => _logout(context, ref),
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

  Widget _group(AppColors c, List<_Row> rows) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            ListTile(
              leading: Icon(rows[i].icon,
                  color: rows[i].danger ? c.negative : c.text),
              title: Text(rows[i].label,
                  style: AppText.bodyMedium
                      .copyWith(color: rows[i].danger ? c.negative : c.text)),
              trailing: Icon(Icons.chevron_right, color: c.textSubtle),
              onTap: rows[i].onTap,
            ),
            if (i < rows.length - 1)
              Divider(height: 1, color: c.divider, indent: 56),
          ],
        ],
      ),
    );
  }

  // --- Edit name ----------------------------------------------------------

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final user = ref.read(sessionProvider).asData?.value;
    final controller = TextEditingController(text: user?.username ?? '');
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: c.surface,
          title: Text('Account information',
              style: AppText.subtitle.copyWith(color: c.text)),
          content: AppTextField(
            controller: controller,
            label: 'Name',
            hint: 'Enter your name',
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: AppText.button.copyWith(color: c.textSubtle)),
            ),
            PillButton(
              label: 'Save',
              expand: false,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        showAppSnack(ctx, 'Name cannot be empty', error: true);
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .updateProfile(username: name);
                        await ref
                            .read(sessionProvider.notifier)
                            .refreshProfile();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          showAppSnack(context, 'Name updated');
                        }
                      } catch (e) {
                        setState(() => saving = false);
                        if (ctx.mounted) {
                          showAppSnack(ctx, errorMessage(e), error: true);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  // --- Change password ----------------------------------------------------

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: c.surface,
          title: Text('Update password',
              style: AppText.subtitle.copyWith(color: c.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: oldPw,
                  label: 'Old password',
                  hint: 'Enter old password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: newPw,
                  label: 'New password',
                  hint: 'Enter new password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: confirmPw,
                  label: 'Confirm new password',
                  hint: 'Re-enter new password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: Text('Close',
                  style: AppText.button.copyWith(color: c.textSubtle)),
            ),
            PillButton(
              label: 'Save',
              expand: false,
              loading: saving,
              onPressed: saving
                  ? null
                  : () async {
                      final oldVal = oldPw.text;
                      final newVal = newPw.text;
                      final confirmVal = confirmPw.text;
                      if (oldVal.isEmpty) {
                        showAppSnack(ctx, 'Please enter old password',
                            error: true);
                        return;
                      }
                      if (newVal.isEmpty) {
                        showAppSnack(ctx, 'Please enter new password',
                            error: true);
                        return;
                      }
                      if (confirmVal.isEmpty) {
                        showAppSnack(ctx, 'Please confirm new password',
                            error: true);
                        return;
                      }
                      if (confirmVal != newVal) {
                        showAppSnack(ctx,
                            'New password should match with confirm password',
                            error: true);
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await ref.read(authRepositoryProvider).updatePassword({
                          'old_password': oldVal,
                          'new_password': newVal,
                          'confirm_new_password': confirmVal,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          showAppSnack(
                              context, 'Password updated successfully');
                        }
                      } catch (e) {
                        setState(() => saving = false);
                        if (ctx.mounted) {
                          showAppSnack(ctx, errorMessage(e), error: true);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
    oldPw.dispose();
    newPw.dispose();
    confirmPw.dispose();
  }

  // --- Reset local app data ----------------------------------------------

  Future<void> _resetLocalData(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Reset local app data',
            style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Reset local app data on this device? This clears saved login, '
          'onboarding, tour, and cached profile data.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep data',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset data',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = ref.read(prefsProvider);
    await prefs.remove(Prefs.kSeenWelcome);
    await prefs.remove(Prefs.kTheme);
    await prefs.remove(Prefs.kPreferences);
    await prefs.remove(Prefs.kAppLock);
    await prefs.remove(Prefs.kNotifSettings);
    await prefs.remove(Prefs.kAddMenuTourSeen);
    await ref.read(secureStoreProvider).clearSession();

    if (context.mounted) {
      showAppSnack(context, 'Local app data reset');
      context.go(Routes.auth);
    }
  }

  // --- About --------------------------------------------------------------

  Future<void> _about(BuildContext context) async {
    final c = context.colors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('About', style: AppText.subtitle.copyWith(color: c.text)),
        content:
            Text('Wealthify v1.0', style: AppText.body.copyWith(color: c.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('OK', style: AppText.button.copyWith(color: c.primary)),
          ),
        ],
      ),
    );
  }

  // --- Logout -------------------------------------------------------------

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Log out', style: AppText.subtitle.copyWith(color: c.text)),
        content: Text('Are you sure you want to log out?',
            style: AppText.bodySm.copyWith(color: c.textSubtle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Log me out',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionProvider.notifier).logout();
  }
}
