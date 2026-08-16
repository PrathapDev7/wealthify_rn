import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/wishlist_item_model.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../auth/auth_screen.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  var _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wishlistListProvider);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: AppText.screenTitle.copyWith(color: c.text),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: c.text),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(context),
        backgroundColor: c.primary,
        foregroundColor: c.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: async.when(
        loading: () => const _WishlistSkeleton(),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load wishlist',
          message: errorMessage(error),
          action: PillButton(
            label: 'Try again',
            expand: false,
            onPressed: () => ref.invalidate(wishlistListProvider),
          ),
        ),
        data: (items) {
          final filtered = _filtered(items);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(wishlistListProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                120,
              ),
              children: [
                _summary(items),
                const SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        'All',
                        'High priority',
                        'Soon',
                        'Purchased',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: AppChip(
                            label: filter,
                            selected: _filter == filter,
                            onTap: () => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (filtered.isEmpty)
                  EmptyState(
                    icon: _filter == 'All'
                        ? Icons.bookmark_border
                        : Icons.filter_alt_off_outlined,
                    title: _filter == 'All'
                        ? 'Plan your next purchase'
                        : 'No matching items',
                    message: _filter == 'All'
                        ? 'Save things you want to buy later and keep them in view.'
                        : 'Try another filter or add a new item.',
                    action: _filter == 'All'
                        ? PillButton(
                            label: 'Add your first item',
                            expand: false,
                            onPressed: () => _editItem(context),
                          )
                        : null,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < filtered.length; i++) ...[
                          _itemTile(filtered[i]),
                          if (i < filtered.length - 1)
                            Divider(height: 1, color: c.divider, indent: 68),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<WishlistItemModel> _filtered(List<WishlistItemModel> items) {
    final now = DateTime.now();
    return items.where((item) {
      if (_filter == 'Purchased') return item.isPurchased;
      if (_filter == 'High priority') {
        return !item.isPurchased && item.priority == 'High';
      }
      if (_filter == 'Soon') {
        return !item.isPurchased &&
            item.targetDate != null &&
            item.targetDate!.difference(now).inDays <= 30;
      }
      return !item.isPurchased;
    }).toList();
  }

  Widget _summary(List<WishlistItemModel> items) {
    final c = context.colors;
    final active = items.where((item) => !item.isPurchased).toList();
    final total = active.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedAmount ?? 0),
    );
    return AppCard(
      child: Row(
        children: [
          Expanded(child: _metric('${active.length}', 'Active items')),
          Container(width: 1, height: 40, color: c.divider),
          Expanded(child: _metric(_amount(total), 'Estimated total')),
          Container(width: 1, height: 40, color: c.divider),
          Expanded(
            child: _metric(
              '${items.where((item) => item.isPurchased).length}',
              'Purchased',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Column(
    children: [
      Text(
        value,
        textAlign: TextAlign.center,
        style: AppText.subtitle.copyWith(color: context.colors.text),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.caption.copyWith(color: context.colors.textSubtle),
      ),
    ],
  );

  Widget _itemTile(WishlistItemModel item) {
    final c = context.colors;
    final date = item.targetDate;
    final details = [
      if (item.estimatedAmount != null) _amount(item.estimatedAmount!),
      if (date != null) '${date.day}/${date.month}/${date.year}',
      item.category,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${item.title}, $details',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        leading: IconButton(
          tooltip: item.isPurchased ? 'Mark as active' : 'Mark as purchased',
          onPressed: () => _togglePurchased(item),
          icon: Icon(
            item.isPurchased
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: item.isPurchased ? c.primary : c.textSubtle,
            size: 26,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.bodyMedium.copyWith(
            color: item.isPurchased ? c.textSubtle : c.text,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          details.isEmpty ? item.priority : '$details · ${item.priority}',
          style: AppText.caption.copyWith(color: c.textSubtle),
        ),
        trailing: IconButton(
          tooltip: 'Edit ${item.title}',
          onPressed: () => _editItem(context, item: item),
          icon: Icon(Icons.chevron_right, color: c.textSubtle),
        ),
        onTap: () => _editItem(context, item: item),
      ),
    );
  }

  String _amount(double amount) => '₹${amount.toStringAsFixed(0)}';

  Future<void> _togglePurchased(WishlistItemModel item) async {
    await ref
        .read(wishlistRepositoryProvider)
        .saveItem(item.copyWith(isPurchased: !item.isPurchased));
    ref.invalidate(wishlistListProvider);
  }

  Future<void> _editItem(
    BuildContext context, {
    WishlistItemModel? item,
  }) async {
    final result = await showModalBottomSheet<WishlistItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WishlistForm(item: item),
    );
    ref.invalidate(wishlistListProvider);
    if (result == null) return;
    await ref.read(wishlistRepositoryProvider).saveItem(result);
    if (context.mounted) {
      showAppSnack(
        context,
        item == null ? 'Added to wishlist' : 'Wishlist item updated',
      );
    }
  }
}

/// Mirrors [_WishlistScreenState]'s data layout: 3-metric summary card,
/// filter-chip row, and a list of item rows.
class _WishlistSkeleton extends StatelessWidget {
  const _WishlistSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        120,
      ),
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(child: _metric()),
              Container(width: 1, height: 40, color: c.divider),
              Expanded(child: _metric()),
              Container(width: 1, height: 40, color: c.divider),
              Expanded(child: _metric()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (final width in [40.0, 100.0, 50.0, 80.0]) ...[
              SkeletonBox(width: width, height: 32, radius: AppRadius.pill),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 5; i++) ...[
                const _WishlistItemRowSkeleton(),
                if (i < 4) Divider(height: 1, color: c.divider, indent: 68),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric() => const Column(
    children: [
      SkeletonLine(width: 40, height: 20),
      SizedBox(height: 4),
      SkeletonLine(width: 70, height: 10),
    ],
  );
}

class _WishlistItemRowSkeleton extends StatelessWidget {
  const _WishlistItemRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140),
                const SizedBox(height: 6),
                SkeletonLine(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistForm extends ConsumerStatefulWidget {
  const _WishlistForm({this.item});
  final WishlistItemModel? item;

  @override
  ConsumerState<_WishlistForm> createState() => _WishlistFormState();
}

class _WishlistFormState extends ConsumerState<_WishlistForm> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _priority;
  late String _category;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _amount = TextEditingController(
      text: item?.estimatedAmount == null
          ? ''
          : item!.estimatedAmount!.toStringAsFixed(0),
    );
    _notes = TextEditingController(text: item?.notes ?? '');
    _priority = item?.priority ?? 'Medium';
    _category = item?.category ?? 'Other';
    _targetDate = item?.targetDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item == null
                      ? 'Add to wishlist'
                      : 'Edit wishlist item',
                  style: AppText.title.copyWith(color: c.text),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: c.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _title,
              label: 'Item name',
              hint: 'What do you want to buy?',
              prefixIcon: Icons.bookmark_border,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _amount,
              label: 'Estimated price',
              hint: 'Optional',
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Priority',
              style: AppText.label.copyWith(color: c.textSubtle),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final value in ['Low', 'Medium', 'High'])
                  AppChip(
                    label: value,
                    selected: _priority == value,
                    onTap: () => setState(() => _priority = value),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Category',
              style: AppText.label.copyWith(color: c.textSubtle),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: c.surface,
              style: AppText.body.copyWith(color: c.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(color: c.inputBorder),
                ),
              ),
              items: [
                for (final value in [
                  'Other',
                  'Electronics',
                  'Home',
                  'Travel',
                  'Fashion',
                  'Education',
                ])
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? 'Other'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _notes,
              label: 'Notes',
              hint: 'Optional details',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_outlined, color: c.textSubtle),
              title: Text(
                _targetDate == null
                    ? 'Target date'
                    : 'Target: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                style: AppText.body.copyWith(color: c.text),
              ),
              subtitle: Text(
                'Optional',
                style: AppText.caption.copyWith(color: c.textSubtle),
              ),
              trailing: IconButton(
                tooltip: 'Choose date',
                onPressed: _pickDate,
                icon: Icon(Icons.chevron_right, color: c.textSubtle),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: widget.item == null ? 'Add to wishlist' : 'Save changes',
              onPressed: _save,
            ),
            if (widget.item != null) ...[
              const SizedBox(height: AppSpacing.sm),
              PillButton(
                label: 'Delete item',
                variant: PillVariant.ghost,
                onPressed: _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _targetDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, 'Item name is required', error: true);
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    final existing = widget.item;
    context.pop(
      WishlistItemModel(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        estimatedAmount: amount,
        priority: _priority,
        category: _category,
        targetDate: _targetDate,
        notes: _notes.text.trim(),
        isPurchased: existing?.isPurchased ?? false,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null) return;
    await ref.read(wishlistRepositoryProvider).deleteItem(item.id);
    if (mounted) {
      context.pop();
      showAppSnack(context, 'Item removed from wishlist');
    }
  }
}
