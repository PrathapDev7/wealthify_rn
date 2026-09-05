import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_summary_screen.dart';
import 'workout_widgets.dart';

/// A past workout, opened from history — the same breakdown the user saw the
/// moment they finished it, plus a way to delete it.
///
/// Pops `true` when the session was deleted, so the list behind it refetches.
class WorkoutSessionDetailScreen extends ConsumerStatefulWidget {
  const WorkoutSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<WorkoutSessionDetailScreen> createState() =>
      _WorkoutSessionDetailScreenState();
}

class _WorkoutSessionDetailScreenState
    extends ConsumerState<WorkoutSessionDetailScreen> {
  SessionResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await ref
          .read(workoutRepositoryProvider)
          .session(widget.sessionId);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: 'Delete workout',
      message: 'This removes the workout and its sets from your history.',
      onConfirm: () =>
          ref.read(workoutRepositoryProvider).deleteSession(widget.sessionId),
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final result = _result;

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const SafeArea(child: _SessionDetailSkeleton()),
      );
    }

    if (result == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Workout not found',
              action: FitnessPill(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Back',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final date = result.session.finishedAt ?? result.session.startedAt;

    return WorkoutSummaryScreen(
      result: result,
      heading: date == null
          ? 'Workout'
          : DateFormat('EEEE, d MMM').format(date),
      onDelete: _delete,
    );
  }
}

/// Loading placeholder mirroring [WorkoutSummaryScreen]'s layout: the
/// donut, its legend, the stats row, and a couple of exercise cards.
class _SessionDetailSkeleton extends StatelessWidget {
  const _SessionDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
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
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl4),
                const Center(child: SkeletonLine(width: 150, height: 20)),
                const SizedBox(height: AppSpacing.xl),
                const Center(child: SkeletonCircle(size: 210)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SkeletonLine(width: 70, height: 12),
                    SizedBox(width: AppSpacing.lg),
                    SkeletonLine(width: 70, height: 12),
                    SizedBox(width: AppSpacing.lg),
                    SkeletonLine(width: 70, height: 12),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: const [
                    Expanded(child: SkeletonLine(width: 60, height: 22)),
                    Expanded(child: SkeletonLine(width: 100, height: 22)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const ExerciseCardSkeleton(),
        const ExerciseCardSkeleton(),
      ],
    );
  }
}
