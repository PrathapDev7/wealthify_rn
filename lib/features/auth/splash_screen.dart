import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gradient_scaffold.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GradientScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: const Image(
                // The app's real logo (same mark as the launcher icon and the
                // native splash) — not the abstract glyph used previously.
                image: AssetImage('assets/images/icon-purple.png'),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Wealthify', style: AppText.titleLg.copyWith(color: c.text)),
            const SizedBox(height: AppSpacing.xl2),
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                  duration: 1000.ms,
                  color: c.primary.withValues(alpha: 0.85),
                ),
          ],
        ),
      ),
    );
  }
}
