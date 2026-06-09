import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';
import '../auth/auth_screen.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  const EditCategoryScreen({
    super.key,
    required this.category,
    required this.type,
  });

  final CategoryModel? category;
  final String type;

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  late final TextEditingController _name;
  String? _iconUrl;
  String? _colorHex;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _name = TextEditingController(text: cat?.title ?? '');
    final icon = cat?.icon;
    _iconUrl = (icon != null && icon.startsWith('http')) ? icon : null;
    _colorHex = (cat?.color != null && cat!.color!.isNotEmpty) ? cat.color : null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<Color> _swatches(BuildContext context) {
    final c = context.colors;
    return [
      c.accentDark,
      c.primary,
      c.cyan,
      c.warning,
      c.negative,
      c.pink,
      c.info,
      c.primaryDarker,
    ];
  }

  Future<void> _upload() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;
      if (mounted) setState(() => _uploading = true);
      final url =
          await ref.read(categoriesRepositoryProvider).uploadIcon(picked.path);
      if (!mounted) return;
      setState(() => _iconUrl = url);
      showAppSnack(context, 'Icon uploaded');
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a name', error: true);
      return;
    }
    final payload = <String, dynamic>{
      'title': name,
      'type': widget.type,
      if (_iconUrl != null) 'icon': _iconUrl,
      if (_colorHex != null) 'color': _colorHex,
    };
    setState(() => _saving = true);
    try {
      final repo = ref.read(categoriesRepositoryProvider);
      if (_isEdit) {
        await repo.updateCategory(widget.category!.id, payload);
      } else {
        await repo.addCategory(payload);
      }
      if (!mounted) return;
      showAppSnack(context, 'Saved');
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Delete category',
            style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Delete this category? Your past transactions are kept but it will be archived.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(categoriesRepositoryProvider)
          .deleteCategory(widget.category!.id);
      if (!mounted) return;
      showAppSnack(context, 'Category deleted');
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = _swatches(context);
    final tint = _colorHex != null ? _parseHex(_colorHex!) ?? c.primary : c.primary;
    final resolved = resolveCategoryIcon(_name.text,
        income: widget.type == 'income', colors: c);

    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: _isEdit ? 'Edit category' : 'Add category'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                            ),
                            child: _iconUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _iconUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          WealthifyIcon(resolved.name, size: 40),
                                    ),
                                  )
                                : WealthifyIcon(resolved.name, size: 40),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name.text.trim().isEmpty
                                      ? 'New category'
                                      : _name.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppText.subtitle.copyWith(color: c.text),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.type == 'income' ? 'Income' : 'Expense',
                                  style: AppText.bodySm
                                      .copyWith(color: c.textSubtle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _name,
                        label: 'Name',
                        hint: 'e.g. Coffee',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Color',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final color in swatches)
                            _Swatch(
                              color: color,
                              selected: _colorHex != null &&
                                  _parseHex(_colorHex!)?.toARGB32() ==
                                      color.toARGB32(),
                              onTap: () =>
                                  setState(() => _colorHex = _hex(color)),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Icon',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      PillButton(
                        label: _iconUrl != null
                            ? 'Replace custom icon'
                            : 'Upload custom icon',
                        variant: PillVariant.secondary,
                        loading: _uploading,
                        leading: Icon(Icons.cloud_upload_outlined,
                            size: 18, color: c.text),
                        onPressed: _uploading ? null : _upload,
                      ),
                      if (_iconUrl != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _iconUrl = null),
                            icon: Icon(Icons.cancel_outlined,
                                size: 16, color: c.textSubtle),
                            label: Text('Use default icon',
                                style: AppText.bodySm
                                    .copyWith(color: c.textSubtle)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: _isEdit ? 'Save changes' : 'Add category',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _delete,
                    icon:
                        Icon(Icons.delete_outline, color: c.negative, size: 18),
                    label: Text('Delete category',
                        style: AppText.button.copyWith(color: c.negative)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.text : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 16, color: c.textInverse)
            : null,
      ),
    );
  }
}

/// '#RRGGBB' string for a [Color] (drops the alpha byte).
String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Parses a '#RRGGBB' / '#AARRGGBB' hex string into a [Color].
Color? _parseHex(String hex) {
  var s = hex.replaceFirst('#', '').trim();
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}
