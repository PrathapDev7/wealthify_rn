import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/provider_catalog.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// Full searchable grid of catalog providers. Returns the chosen [FinProvider]
/// via `context.pop`. Mirrors `SelectCategoryScreen`.
class SelectProviderScreen extends StatefulWidget {
  const SelectProviderScreen({super.key, required this.type});

  /// 'bank' | 'wallet'
  final String type;

  @override
  State<SelectProviderScreen> createState() => _SelectProviderScreenState();
}

class _SelectProviderScreenState extends State<SelectProviderScreen> {
  final _search = TextEditingController();
  String _query = '';

  bool get _isWallet => widget.type == 'wallet';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = searchProviders(widget.type, _query);

    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: _isWallet ? 'Select Wallet' : 'Select Bank'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppTextField(
              controller: _search,
              hint: _isWallet ? 'Search wallets' : 'Search banks',
              prefixIcon: Icons.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search,
                    title: 'No matches',
                    message: 'Try a different search term.',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl5),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.lg,
                      children: [
                        for (final p in filtered)
                          _ProviderTile(
                            provider: p,
                            onTap: () => context.pop(p),
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

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider, required this.onTap});

  final FinProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tileWidth = (MediaQuery.sizeOf(context).width -
            AppSpacing.xl * 2 -
            AppSpacing.md * 3) /
        4;

    return SizedBox(
      width: tileWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            ProviderAvatar(provider: provider, size: tileWidth * 0.64),
            const SizedBox(height: AppSpacing.xs),
            Text(
              provider.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
