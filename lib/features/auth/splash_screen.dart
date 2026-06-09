import 'package:flutter/material.dart';

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Image(
                  image: AssetImage(
                      'assets/wealthify/glyph_256/wealthify_mark.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Wealthify', style: AppText.titleLg.copyWith(color: c.text)),
            const SizedBox(height: AppSpacing.xl2),
            CircularProgressIndicator(color: c.primary, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
