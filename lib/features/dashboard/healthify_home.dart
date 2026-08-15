import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../calories/calorie_history_screen.dart';
import '../calories/calorie_screen.dart';
import '../weight/weight_screen.dart';

enum _HealthifyTab { today, history, weight }

/// Healthify's own three-way sub-nav (Today / History / Weight), shown
/// beneath the Wealthify/Healthify app switcher on the Home tab.
class HealthifyHome extends StatefulWidget {
  const HealthifyHome({super.key});

  @override
  State<HealthifyHome> createState() => _HealthifyHomeState();
}

class _HealthifyHomeState extends State<HealthifyHome> {
  _HealthifyTab _tab = _HealthifyTab.today;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xs,
          ),
          child: _HealthifySubNav(
            active: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _HealthifyTab.today => const CalorieScreen(embedded: true),
            _HealthifyTab.history => const CalorieHistoryScreen(embedded: true),
            _HealthifyTab.weight => const WeightScreen(embedded: true),
          },
        ),
      ],
    );
  }
}

class _HealthifySubNav extends StatelessWidget {
  const _HealthifySubNav({required this.active, required this.onChanged});

  final _HealthifyTab active;
  final ValueChanged<_HealthifyTab> onChanged;

  static const _tabs = [
    (_HealthifyTab.today, 'Today', Icons.restaurant_rounded),
    (_HealthifyTab.history, 'Statistics', Icons.show_chart_rounded),
    (_HealthifyTab.weight, 'Weight', Icons.monitor_weight_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (final t in _tabs)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active == t.$1
                      ? c.warning.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: active == t.$1 ? c.warning : c.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 16,
                      color: active == t.$1 ? c.warning : c.textSubtle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.$2,
                      style: AppText.caption.copyWith(
                        color: active == t.$1 ? c.warning : c.textSubtle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
