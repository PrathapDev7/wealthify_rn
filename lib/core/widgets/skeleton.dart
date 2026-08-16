import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Rounded-rect placeholder block with a shimmer sweep, for skeleton loading
/// states. Fill mirrors the app's existing neutral "empty" surface
/// (`AppProgressBar` track, `AppChip` unselected state).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
          duration: 1200.ms,
          color: c.surface,
        );
  }
}

/// Circular placeholder, for avatar/icon-badge skeletons.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
    ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
          duration: 1200.ms,
          color: c.surface,
        );
  }
}

/// Thin rounded bar for a single text-line placeholder.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, radius: height / 2);
  }
}

/// Spacer matching [AppSpacing] scale, for readability inside skeleton
/// layouts.
class SkeletonGap extends StatelessWidget {
  const SkeletonGap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
