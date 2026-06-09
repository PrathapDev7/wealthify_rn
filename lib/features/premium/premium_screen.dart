import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// Invite & Earn screen — mirrors `legacy_rn/app/premium.tsx` (the
/// `InviteEarnScreen` component). Three referral cards, a centered headline and
/// a "Get Started" CTA. Purely presentational for now (no invite flow wired up).
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  static const _items = <(String, String, String)>[
    (
      'earn_rewards',
      'Earn Rewards',
      'Invite & earn prizes when friends join.',
    ),
    (
      'earn_sharing',
      'Earn Sharing',
      'Share your link and earn too.',
    ),
    (
      'track_referrals',
      'Track Referrals',
      'See who joined and what you earn.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: ''),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl4, AppSpacing.xl, AppSpacing.xl2),
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    _InviteCard(
                      glyph: _items[i].$1,
                      title: _items[i].$2,
                      body: _items[i].$3,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Column(
                      children: [
                        Text('Invite Other People',
                            textAlign: TextAlign.center,
                            style: AppText.title.copyWith(color: c.text)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Connect all your accounts from any bank. Add savings, '
                          'credit cards, PayPal and more.',
                          textAlign: TextAlign.center,
                          style: AppText.bodySm.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl4),
                  PillButton(
                    label: 'Get Started',
                    onPressed: () =>
                        showAppSnack(context, 'Invite flow coming soon'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.glyph,
    required this.title,
    required this.body,
  });

  final String glyph;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: WealthifyIcon(glyph, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.bodyStrong.copyWith(color: c.text)),
                const SizedBox(height: 2),
                Text(body,
                    style: AppText.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
