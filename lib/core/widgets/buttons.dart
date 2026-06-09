import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum PillVariant { primary, secondary, ghost }

/// Pill-shaped CTA. Primary = gradient + glow, secondary = bordered surface.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.loading = false,
    this.leading,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final bool loading;
  final Widget? leading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPrimary = variant == PillVariant.primary;
    final disabled = onPressed == null || loading;

    final fg = switch (variant) {
      PillVariant.primary => c.textOnPrimary,
      PillVariant.secondary => c.text,
      PillVariant.ghost => c.primary,
    };

    final content = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
              Text(label, style: AppText.button.copyWith(color: fg)),
            ],
          );

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          width: expand ? double.infinity : null,
          height: 52,
          alignment: Alignment.center,
          padding: expand
              ? null
              : const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [c.primaryGradientStart, c.primaryGradientEnd])
                : null,
            color: switch (variant) {
              PillVariant.primary => null,
              PillVariant.secondary => c.surface,
              PillVariant.ghost => Colors.transparent,
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: variant == PillVariant.secondary
                ? Border.all(color: c.border)
                : null,
            boxShadow: isPrimary ? AppShadows.primaryGlow : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Round icon button used for nav/back/settings.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 22,
    this.background,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? c.surface,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
          boxShadow: AppShadows.xs,
        ),
        child: Icon(icon, size: iconSize, color: color ?? c.text),
      ),
    );
  }
}
