import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

const _slides = [
  _Slide(Icons.account_balance_wallet_outlined, 'Your Finances in One Place',
      'Track every rupee — incomes, expenses, and budgets — without juggling apps.'),
  _Slide(Icons.pie_chart_outline, 'Budgets That Work',
      'Set monthly limits per category and see exactly where your money goes.'),
  _Slide(Icons.savings_outlined, 'Reach Your Goals',
      'Save towards what matters, automate recurring bills, and grow your wealth.'),
];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(prefsProvider).setBool(Prefs.kSeenWelcome, true);
    context.go(Routes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isLast = _page == _slides.length - 1;
    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip',
                    style: AppText.bodyMedium.copyWith(color: c.textSubtle)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            c.primaryGradientStart,
                            c.primaryGradientEnd
                          ]),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Icon(s.icon, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      Text(s.title,
                          textAlign: TextAlign.center,
                          style: AppText.titleLg.copyWith(color: c.text)),
                      const SizedBox(height: AppSpacing.md),
                      Text(s.subtitle,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(color: c.textSubtle)),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? c.primary : c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PillButton(
              label: isLast ? 'Get Started' : 'Next',
              onPressed: () {
                if (isLast) {
                  _finish();
                } else {
                  _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
