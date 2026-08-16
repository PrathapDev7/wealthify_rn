import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class WalletCardStack extends StatelessWidget {
  const WalletCardStack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FractionallySizedBox(
          widthFactor: 0.74,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.82,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        FractionallySizedBox(widthFactor: 0.9, child: child),
      ],
    );
  }
}
