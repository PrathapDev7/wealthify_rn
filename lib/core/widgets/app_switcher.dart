import 'package:flutter/material.dart';

import '../providers.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Two-segment switcher pinned to the top of Home, letting the user
/// flip between the finance app (Wealthify) and the calorie tracker
/// (Healthify) — mirrors the JioHotstar/Tadka app-switcher pattern.
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({super.key, required this.active, required this.onChanged});

  final ActiveApp active;
  final ValueChanged<ActiveApp> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitcherSegment(
              label: 'Wealthify',
              icon: Icons.account_balance_wallet_rounded,
              selected: active == ActiveApp.wealthify,
              gradient: [c.primaryGradientStart, c.primaryGradientEnd],
              onTap: () => onChanged(ActiveApp.wealthify),
            ),
          ),
          Expanded(
            child: _SwitcherSegment(
              label: 'Healthify',
              icon: Icons.restaurant_rounded,
              selected: active == ActiveApp.healthify,
              gradient: [c.warning, c.warning.withValues(alpha: 0.75)],
              onTap: () => onChanged(ActiveApp.healthify),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherSegment extends StatelessWidget {
  const _SwitcherSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: gradient) : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : c.textSubtle),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.bodyLarge.copyWith(
                color: selected ? Colors.white : c.textSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
