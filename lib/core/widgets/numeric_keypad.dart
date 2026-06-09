import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// On-screen number pad for amount entry. Mirrors
/// `legacy_rn/src/components/ui/NumericKeypad.tsx`: a 3x4 grid of 1-9, a
/// decimal point (bottom-left), 0, and a backspace key (bottom-right).
///
/// Digits and '.' are reported via [onDigit]; the backspace key via
/// [onBackspace]. The parent owns the amount string and decides what to do
/// with each key (e.g. clamp length, strip leading zeros, one decimal point).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key, required this.onDigit, required this.onBackspace});

  /// Called with the tapped digit ('0'-'9') or the decimal point ('.').
  final ValueChanged<String> onDigit;

  /// Called when the backspace key is tapped.
  final VoidCallback onBackspace;

  // Bottom row mirrors the RN layout but swaps the empty slot for a usable
  // decimal-point key so the Flutter keypad can drive a fractional amount.
  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];

  // Sub-labels under each digit, matching the phone-keypad lettering in RN.
  static const Map<String, String> _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(child: _KeypadKey(value: key, onTap: _handle(key))),
              ],
            ),
        ],
      ),
    );
  }

  VoidCallback _handle(String key) =>
      key == 'backspace' ? onBackspace : () => onDigit(key);
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isBackspace = value == 'backspace';
    final letters = NumericKeypad._letters[value];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: SizedBox(
        height: 54,
        child: isBackspace
            ? Icon(Icons.backspace_outlined, size: 20, color: c.text)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppText.title.copyWith(
                      color: c.text,
                      fontSize: 22,
                      height: 25 / 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    letters ?? '',
                    style: AppText.caption.copyWith(
                      color: c.text,
                      fontSize: 9,
                      height: 11 / 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
