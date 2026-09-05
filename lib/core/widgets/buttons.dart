import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    this.loadingLabel,
    this.gradientColors,
    this.radius = AppRadius.pill,
    this.labelStyle,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final bool loading;
  final Widget? leading;
  final bool expand;

  /// Fully round by default; override for the buttons that should read as a
  /// rounded box instead, like the ones sitting under an empty state.
  final double radius;

  /// Overrides the bold [AppText.button] the label is set in — pass a whole
  /// style rather than a weight, since google_fonts drops a `copyWith`
  /// fontWeight on the way to the font file. Its color is always the
  /// variant's foreground.
  final TextStyle? labelStyle;

  /// Full-height CTA by default; the lighter buttons that sit inside a screen
  /// (under an empty state, say) run shorter.
  final double height;

  /// Overrides the primary-variant gradient (defaults to
  /// `[c.primaryDark, c.primaryDarker]`) — lets a caller in an ambient theme
  /// (e.g. a modal outside [HealthifyTheme]) still show the Healthify brand
  /// gradient on its submit button.
  final List<Color>? gradientColors;

  /// When set, shown next to the spinner while [loading] is true instead of
  /// a bare spinner — lets a button surface progress text on itself.
  final String? loadingLabel;

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
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                width: 40,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                    duration: 1000.ms,
                    color: fg.withValues(alpha: 0.85),
                  ),
              if (loadingLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    loadingLabel!,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.button.copyWith(color: fg),
                  ),
                ),
              ],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (labelStyle ?? AppText.button).copyWith(color: fg),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          width: expand ? double.infinity : null,
          height: height,
          // Only while expanding: a Container with an alignment wraps its
          // child in an Align, which fills the space it is given — which kept
          // `expand: false` full width anyway. Without it the Row's own
          // mainAxisSize.min is what sizes the button, so it hugs its label.
          alignment: expand ? Alignment.center : null,
          padding: expand
              ? null
              : const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(colors: gradientColors ?? [c.primaryDark, c.primaryDarker])
                : null,
            color: switch (variant) {
              PillVariant.primary => null,
              PillVariant.secondary => c.surface,
              PillVariant.ghost => Colors.transparent,
            },
            borderRadius: BorderRadius.circular(radius),
            border: variant == PillVariant.secondary
                ? Border.all(color: c.border)
                : null,
            boxShadow: null,
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
