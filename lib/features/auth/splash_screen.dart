import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/align_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlignTheme(child: _SplashBody());
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GradientScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AlignLogo(
              markSize: 104,
              fontSize: 30,
              tagline: 'Your life, in balance.',
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.xl4),
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    c.primaryGradientStart.withValues(alpha: 0.35),
                    c.primaryGradientEnd.withValues(alpha: 0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                  duration: 1000.ms,
                  color: c.primary.withValues(alpha: 0.9),
                ),
          ],
        ),
      ),
    );
  }
}
