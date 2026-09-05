import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/workout_models.dart';
import 'workout_widgets.dart';

/// What you see the moment the last set is ticked off: the split across
/// muscles, the two headline numbers, and every exercise you did.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.result,
    this.heading = 'Nice workout!',
    this.onDelete,
  });

  final SessionResult result;

  /// Reused by the history detail screen, where "Nice workout!" would be a
  /// congratulation on something the user did weeks ago.
  final String heading;

  /// Only the history detail screen passes this; a workout you just finished
  /// has no delete affordance.
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = result.session;
    final summary = result.summary;
    final slices = [
      for (final m in summary.muscles)
        if (m.count > 0) MuscleSlice(label: m.muscle, count: m.count),
    ];
    final date = session.finishedAt ?? session.startedAt;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl2,
          ),
          children: [
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        if (onDelete != null) ...[
                          FitnessIconButton(
                            icon: Icons.delete_outline_rounded,
                            background: Colors.transparent,
                            color: c.negative,
                            onTap: onDelete!,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        FitnessIconButton(
                          icon: Icons.close_rounded,
                          background: Colors.transparent,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: AppText.titleLg.copyWith(
                        color: c.textSubtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      session.routineName.isEmpty
                          ? session.planName
                          : '${session.planName} · ${session.routineName}',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(color: c.textSubtle),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: MuscleDonut(
                        muscles: slices,
                        centerValue: '${summary.completedSets}',
                        centerLabel: summary.completedSets == 1
                            ? 'set'
                            : 'sets',
                        size: 210,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MuscleLegend(muscles: slices),
                    const SizedBox(height: AppSpacing.xl),
                    _stats(
                      context,
                      summary.durationSec,
                      date,
                      summary.volume,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final exercise in session.exercises)
              _SummaryExerciseCard(exercise: exercise),
          ],
        ),
      ),
    );
  }

  Widget _stats(
    BuildContext context,
    int durationSec,
    DateTime? date,
    double volume,
  ) {
    final c = context.colors;

    Widget column(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
          const SizedBox(height: 4),
          Text(value, style: AppText.subtitle.copyWith(color: c.text)),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          column('Workout time', formatClock(durationSec)),
          VerticalDivider(color: c.border, width: 1, thickness: 1),
          column(
            'Date',
            date == null ? '--' : DateFormat('d MMM, HH:mm').format(date),
          ),
          // Bodyweight-only workouts have no volume to report, so the third
          // column only appears when there is a number in it.
          if (volume > 0) ...[
            VerticalDivider(color: c.border, width: 1, thickness: 1),
            column('Volume', '${formatValue(volume.round())} kg'),
          ],
        ],
      ),
    );
  }
}

class _SummaryExerciseCard extends StatelessWidget {
  const _SummaryExerciseCard({required this.exercise});

  final SessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final timed = exercise.mode == ExerciseMode.time;
    final first = exercise.sets.isEmpty ? null : exercise.sets.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExerciseInfoCard(
        catalogId: exercise.catalogId,
        name: exercise.name,
        muscleLabel: exercise.muscleLabel,
        restBetweenSetsSec: exercise.restBetweenSetsSec,
        setCount: exercise.sets.length,
        statValue: timed
            ? formatClock(first?.durationSec ?? 0)
            : formatValue(first?.reps),
        statLabel: timed ? 'Time' : 'Reps',
      ),
    );
  }
}
