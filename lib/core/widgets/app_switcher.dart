import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Three-segment switcher pinned to the top of Home, letting the user flip
/// between the finance app (Wealthify), the calorie tracker (Healthify) and
/// Fitness — mirrors the JioHotstar/Tadka app-switcher pattern.
///
/// Only the active segment carries its label; the other two collapse to a bare
/// icon. That is what lets three brands share one row at phone widths — spelt
/// out in full, 'Wealthify' + 'Healthify' + 'Fitness' overflow a 360dp screen.
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({super.key, required this.active, required this.onChanged});

  final ActiveApp active;
  final ValueChanged<ActiveApp> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthify = isDark ? AppColors.healthifyDark : AppColors.healthifyLight;
    final segments = <_SegmentData>[
      _SegmentData(
        app: ActiveApp.wealthify,
        label: 'Wealthify',
        icon: Icons.account_balance_wallet_rounded,
        gradient: [c.primaryGradientStart, c.primaryGradientEnd],
      ),
      _SegmentData(
        app: ActiveApp.healthify,
        label: 'Healthify',
        icon: Icons.restaurant_rounded,
        gradient: [
          healthify.primaryGradientStart,
          healthify.primaryGradientEnd,
        ],
      ),
      _SegmentData(
        app: ActiveApp.fitness,
        label: 'Fitness',
        icon: Icons.fitness_center_rounded,
        gradient: AppColors.fitnessGradient,
      ),
    ];

    // Expanded only on the selected segment: it soaks up whatever width the two
    // collapsed icons leave behind, so the row still fills the bar exactly.
    Widget lay(_SegmentData segment) {
      final selected = segment.app == active;
      final child = _SwitcherSegment(
        data: segment,
        selected: selected,
        onTap: () => onChanged(segment.app),
      );
      return selected ? Expanded(child: child) : child;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Row(children: segments.map(lay).toList()),
    );
  }
}

class _SegmentData {
  const _SegmentData({
    required this.app,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final ActiveApp app;
  final String label;
  final IconData icon;
  final List<Color> gradient;
}

class _SwitcherSegment extends StatelessWidget {
  const _SwitcherSegment({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _SegmentData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, t, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: selected ? LinearGradient(colors: data.gradient) : null,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: data.gradient.first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.icon,
                size: 20,
                color: selected ? Colors.white : c.textSubtle,
              ),
              // It is the label's *occupied width* that animates, not just its
              // opacity: it unrolls from behind the icon and collapses back to
              // zero on deselect, so the icon stays optically centred the whole
              // way through instead of being shoved sideways by a popped-in
              // label. ClipRect keeps the half-revealed text inside the pill.
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: Opacity(
                    opacity: t,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Text(
                        data.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
