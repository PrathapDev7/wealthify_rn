import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/workout_models.dart';
import 'workout_widgets.dart';

/* --------------------------------------------------------- routine menu -- */

/// What the routine menu on the bottom action bar offers. The sheet itself is
/// a [showFitnessOptionSheet], built where it is opened.
enum RoutineMenuAction { rename, reorderExercises, restBetweenExercises, delete }

/* ------------------------------------------------------ manage routines -- */

/// What the "Manage Routines" sheet decided: the surviving routines in their
/// new order, plus any renames. The screen replays it against the API.
class ManageRoutinesResult {
  const ManageRoutinesResult({
    required this.order,
    required this.renamed,
    required this.removed,
  });

  /// Routine ids, in the order the user left them.
  final List<String> order;

  /// `routineId -> new name`, only for the ones actually changed.
  final Map<String, String> renamed;

  /// Ids the user removed — deleted one call at a time, because the reorder
  /// endpoint owns order and the delete endpoint owns removal.
  final List<String> removed;
}

/// Pass [onSave] to replay the changes from inside the sheet: Save reads
/// "Saving…" and the sheet stays open until the API answers.
Future<ManageRoutinesResult?> showManageRoutines(
  BuildContext context, {
  required List<Routine> routines,
  Future<void> Function(ManageRoutinesResult result)? onSave,
}) {
  return showFitnessSheet<ManageRoutinesResult>(
    context: context,
    builder: (sheetContext) =>
        _ManageRoutinesSheet(routines: routines, onSave: onSave),
  );
}

class _ManageRoutinesSheet extends StatefulWidget {
  const _ManageRoutinesSheet({required this.routines, this.onSave});

  final List<Routine> routines;
  final Future<void> Function(ManageRoutinesResult result)? onSave;

  @override
  State<_ManageRoutinesSheet> createState() => _ManageRoutinesSheetState();
}

class _ManageRoutinesSheetState extends State<_ManageRoutinesSheet> {
  late final List<Routine> _original = List.of(widget.routines);
  late List<String> _order = [for (final r in widget.routines) r.id];
  final Map<String, String> _names = {};
  final List<String> _removed = [];

  String _nameOf(String id) =>
      _names[id] ??
      _original.firstWhere((r) => r.id == id, orElse: () => _fallback).name;

  static const Routine _fallback = Routine(id: '', name: '');

  int _exerciseCount(String id) => _original
      .firstWhere((r) => r.id == id, orElse: () => _fallback)
      .exercises
      .length;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manage Routines',
            textAlign: TextAlign.center,
            style: AppText.bodyLargeRegular.copyWith(color: c.text),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorder: (oldIndex, newIndex) => setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                _order.insert(newIndex, _order.removeAt(oldIndex));
              }),
              itemBuilder: (context, index) {
                final id = _order[index];
                final count = _exerciseCount(id);
                return Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: c.negative,
                          size: 20,
                        ),
                        // The last routine cannot go: a plan with no routine
                        // has nothing to show, and the API would happily
                        // create that state.
                        onPressed: _order.length <= 1
                            ? null
                            : () => setState(() {
                                _removed.add(id);
                                _order = [..._order]..removeAt(index);
                              }),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final name = await showNamePrompt(
                              context,
                              title: 'Rename routine',
                              initial: _nameOf(id),
                            );
                            if (name != null) setState(() => _names[id] = name);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameOf(id),
                                style: AppText.bodyMedium.copyWith(
                                  color: c.text,
                                ),
                              ),
                              Text(
                                count == 1 ? '1 exercise' : '$count exercises',
                                style: AppText.caption.copyWith(
                                  color: c.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: c.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SheetSaveButton(
            onPressed: () async {
              final result = ManageRoutinesResult(
                order: _order,
                renamed: _names,
                removed: _removed,
              );
              await widget.onSave?.call(result);
              if (mounted) Navigator.of(context).pop(result);
            },
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------ reminders -- */

class RemindersResult {
  const RemindersResult({required this.enabled, required this.reminders});

  final bool enabled;
  final List<WorkoutReminder> reminders;
}

const List<String> kWeekdayNames = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

Future<RemindersResult?> showRemindersSheet(
  BuildContext context, {
  required bool enabled,
  required List<WorkoutReminder> reminders,
}) {
  return showFitnessSheet<RemindersResult>(
    context: context,
    builder: (sheetContext) =>
        _RemindersSheet(enabled: enabled, reminders: reminders),
  );
}

class _RemindersSheet extends StatefulWidget {
  const _RemindersSheet({required this.enabled, required this.reminders});

  final bool enabled;
  final List<WorkoutReminder> reminders;

  @override
  State<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<_RemindersSheet> {
  late bool _enabled = widget.enabled;

  /// Kept as `(day, time)` pairs rather than [WorkoutReminder]s: a reminder the
  /// user adds here has no id until the plan is saved, so an id would be a lie
  /// for part of the list.
  late List<(int, String)> _items = [
    for (final r in widget.reminders) (r.dayOfWeek, r.time),
  ];

  Future<void> _add() async {
    final now = TimeOfDay.now();
    final time = await showTimePicker(context: context, initialTime: now);
    if (time == null || !mounted) return;

    final day = await showFitnessSheet<int>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++)
            SheetActionRow(
              icon: Icons.event_rounded,
              label: kWeekdayNames[i],
              onTap: () => Navigator.of(sheetContext).pop(i),
            ),
        ],
      ),
    );
    if (day == null || !mounted) return;

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    setState(() {
      _items = [..._items, (day, '$hh:$mm')];
      _enabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Workout reminders',
                  style: AppText.subtitle.copyWith(color: c.text),
                ),
              ),
              Switch(
                value: _enabled,
                activeThumbColor: c.textOnPrimary,
                activeTrackColor: c.primary,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No reminders yet.',
                style: AppText.body.copyWith(color: c.textSubtle),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${kWeekdayNames[_items[i].$1.clamp(0, 6)]} · ${_items[i].$2}',
                                style: AppText.bodyMedium.copyWith(
                                  color: c.text,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: c.textSubtle,
                              ),
                              onPressed: () => setState(() {
                                _items = [..._items]..removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            onPressed: _add,
            icon: Icon(Icons.add_rounded, size: 18, color: c.primary),
            label: Text(
              'Add reminder',
              style: AppText.button.copyWith(color: c.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.textOnPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(
              RemindersResult(
                enabled: _enabled,
                reminders: [
                  for (final item in _items)
                    WorkoutReminder(
                      id: '',
                      dayOfWeek: item.$1,
                      time: item.$2,
                    ),
                ],
              ),
            ),
            child: Text('Save', style: AppText.button),
          ),
        ],
      ),
    );
  }
}
