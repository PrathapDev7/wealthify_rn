import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'app_text_field.dart';
import 'buttons.dart';
import 'misc.dart';

/// Minimal single-field "quick add" bottom sheet — an icon-badged header, one
/// text field, and a submit button. While [onSubmit] is running the button
/// shows a spinner, optionally cycling through [loadingMessages] the way the
/// full Calorie Tracker screen does. Lets flows like wishlist or calorie
/// logging be triggered from anywhere (e.g. the shell's Quick Add menu)
/// without leaving the current screen or duplicating their save logic.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.fieldLabel,
    required this.fieldHint,
    required this.buttonLabel,
    required this.onSubmit,
    this.maxLines = 1,
    this.keyboardType,
    this.loadingMessages,
    this.emptyErrorText = 'This field is required',
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? fieldLabel;
  final String fieldHint;
  final String buttonLabel;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Cycled on the button every 3s while [onSubmit] is in flight — omit for
  /// a plain spinner.
  final List<String>? loadingMessages;
  final String emptyErrorText;

  /// Runs the actual save. Whatever it returns is passed back through
  /// `Navigator.pop` once it resolves; a thrown error is caught and shown
  /// as an inline snack without closing the sheet.
  final Future<dynamic> Function(BuildContext context, String value) onSubmit;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String _loadingMessage = '';
  Timer? _loadingTimer;
  int _loadingStep = 0;

  @override
  void dispose() {
    _controller.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _startLoadingMessages() {
    final messages = widget.loadingMessages;
    if (messages == null || messages.isEmpty) return;
    _loadingStep = 0;
    _loadingMessage = messages[0];
    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _loadingStep = (_loadingStep + 1) % messages.length;
      setState(() => _loadingMessage = messages[_loadingStep]);
    });
  }

  void _stopLoadingMessages() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      showAppSnack(context, widget.emptyErrorText, error: true);
      return;
    }
    setState(() => _loading = true);
    _startLoadingMessages();
    try {
      final result = await widget.onSubmit(context, value);
      _stopLoadingMessages();
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      _stopLoadingMessages();
      if (mounted) {
        final message = e is Exception ? e.toString() : 'Something went wrong';
        showAppSnack(context, message, error: true);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottom + AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppText.title.copyWith(color: c.text)),
                      Text(widget.subtitle, style: AppText.bodySm.copyWith(color: c.textSubtle)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: c.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _controller,
              label: widget.fieldLabel,
              hint: widget.fieldHint,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              readOnly: _loading,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: widget.buttonLabel,
              loading: _loading,
              loadingLabel: _loading && widget.loadingMessages != null ? _loadingMessage : null,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
