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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [c.primaryGradientStart, c.primaryGradientEnd]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: const Center(
                child: Text('₹',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800)),
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
