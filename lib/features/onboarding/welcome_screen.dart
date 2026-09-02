import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/align_logo.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.subtitle, this.gradient);
  final IconData icon;
  final String title;
  final String subtitle;

  /// Slide-specific pair drawn from the Align violet→blue→teal ramp, so the
  /// pager walks along the brand gradient as you swipe.
  final List<Color> gradient;
}

const _violet = Color(0xFF7C3AED);
const _blue = Color(0xFF4F8EFF);
const _teal = Color(0xFF22D3A6);

const _slides = [
  _Slide(
      Icons.account_balance_wallet_outlined,
      'Your Finances in One Place',
      'Track every rupee — incomes, expenses, and budgets — without juggling apps.',
      [_violet, _blue]),
  _Slide(Icons.pie_chart_outline, 'Set Smart Budgets',
      'Plan ahead with category budgets, and get nudged before you overspend.',
      [_blue, Color(0xFF34B6D8)]),
  _Slide(Icons.bar_chart_outlined, 'Insights That Help',
      'See trends month over month, spot patterns, and make better money decisions.',
      [Color(0xFF34B6D8), _teal]),
];

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const AlignTheme(child: _WelcomeBody());
}

class _WelcomeBody extends ConsumerStatefulWidget {
  const _WelcomeBody();
  @override
  ConsumerState<_WelcomeBody> createState() => _WelcomeBodyState();
}

class _WelcomeBodyState extends ConsumerState<_WelcomeBody> {
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
            Row(
              children: [
                const AlignMark(size: 30),
                const SizedBox(width: AppSpacing.sm),
                AlignWordmark(fontSize: 15, color: c.text),
                const Spacer(),
                TextButton(
                  onPressed: _finish,
                  child: Text('Skip',
                      style: AppText.bodyMedium.copyWith(color: c.textSubtle)),
                ),
              ],
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
                          gradient: LinearGradient(
                            colors: s.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.alignGlowSoft,
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
                    gradient: i == _page
                        ? LinearGradient(colors: _slides[i].gradient)
                        : null,
                    color: i == _page ? null : c.border,
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
