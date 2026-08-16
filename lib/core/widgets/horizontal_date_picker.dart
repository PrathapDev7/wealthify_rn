import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'buttons.dart';

/// Month/year header + a week of day badges, with prev/next/today controls.
/// Shared by the Healthify Today and Statistics screens so both present the
/// exact same date-navigation UI.
class HorizontalDatePicker extends StatelessWidget {
  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onTodayTap,
    this.onPrevTap,
    this.onNextTap,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onTodayTap;
  final VoidCallback? onPrevTap;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final monthYear = DateFormat('MMMM yyyy').format(selectedDate);
    final days = _getWeekDays(selectedDate);
    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(monthYear, style: AppText.bodyLarge.copyWith(color: c.text)),
            const Spacer(),
            GestureDetector(
              onTap: onTodayTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Today',
                  style: AppText.bodySm.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleIconButton(
              icon: Icons.chevron_left,
              size: 32,
              iconSize: 18,
              onTap: onPrevTap,
            ),
            const SizedBox(width: AppSpacing.xs),
            CircleIconButton(
              icon: Icons.chevron_right,
              size: 32,
              iconSize: 18,
              onTap: onNextTap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Weekday initials
        Row(
          children: days
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      (day['abbrev'] as String).substring(0, 1),
                      style: AppText.caption.copyWith(color: c.textSubtle),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Date circles
        Row(
          children: days
              .map(
                (day) => Expanded(
                  child: Center(
                    child: _DateBadge(
                      day: day['day'] as int,
                      isSelected: (day['key'] as String) == selectedKey,
                      isToday: (day['key'] as String) == todayKey,
                      onTap: () => onDateSelected(day['date'] as DateTime),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeekDays(DateTime date) {
    final days = <Map<String, dynamic>>[];
    // Start from the Monday of the current week
    final startOfWeek = DateTime(
      date.year,
      date.month,
      date.day - date.weekday + 1,
    );
    for (int i = 0; i < 7; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      days.add({
        'abbrev': DateFormat('EEE').format(dayDate),
        'date': dayDate,
        'day': dayDate.day,
        'key': DateFormat('yyyy-MM-dd').format(dayDate),
      });
    }
    return days;
  }
}

/// Fixed-size circular date badge — a single centered number, so it can
/// never look vertically off-center regardless of the column width.
class _DateBadge extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateBadge({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? LinearGradient(colors: [c.primaryDark, c.primaryDarker])
              : null,
          color: isSelected
              ? null
              : (isToday ? c.primarySoft : Colors.transparent),
          border: !isSelected && isToday
              ? Border.all(color: c.primary, width: 1.2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$day',
          style: AppText.bodyMedium.copyWith(
            color: isSelected ? Colors.white : (isToday ? c.primary : c.text),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
