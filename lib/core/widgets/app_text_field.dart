import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.errorText,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.label.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            color: c.inputBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
                color: errorText != null ? c.negative : c.inputBorder),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            maxLines: obscureText ? 1 : maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: AppText.body.copyWith(color: c.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: AppText.body.copyWith(color: c.textPlaceholder),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              prefixIcon:
                  prefixIcon != null ? Icon(prefixIcon, size: 18, color: c.textSubtle) : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              suffixIcon: suffix,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: AppText.caption.copyWith(color: c.negative)),
        ],
      ],
    );
  }
}
