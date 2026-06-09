import 'package:flutter/material.dart';

import 'gradient_scaffold.dart';
import 'misc.dart';

/// Placeholder for routes not yet migrated. Swapped out as screens land.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: title),
          const Expanded(
            child: EmptyState(
              icon: Icons.construction_outlined,
              title: 'Coming soon',
              message: 'This screen is being migrated to Flutter.',
            ),
          ),
        ],
      ),
    );
  }
}
