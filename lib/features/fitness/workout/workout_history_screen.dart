import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_session_detail_screen.dart';
import 'workout_widgets.dart';

/// Every workout the user has finished, newest first.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  static const int _pageSize = 30;

  final ScrollController _scroll = ScrollController();
  final List<WorkoutSessionRow> _rows = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _exhausted || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _fetchMore();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final rows = await ref
          .read(workoutRepositoryProvider)
          .sessions(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _rows
          ..clear()
          ..addAll(rows);
        _exhausted = rows.length < _pageSize;
      });
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _loadingMore = true);
    try {
      final rows = await ref
          .read(workoutRepositoryProvider)
          .sessions(limit: _pageSize, skip: _rows.length);
      if (!mounted) return;
      setState(() {
        _rows.addAll(rows);
        _exhausted = rows.length < _pageSize;
      });
    } catch (_) {
      // A failed page just stops the list growing; the rows already on screen
      // are still good.
      if (mounted) setState(() => _exhausted = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _open(WorkoutSessionRow row) async {
    final changed = await pushFitness<bool>(
      context,
      WorkoutSessionDetailScreen(sessionId: row.id),
    );
    if (changed == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  FitnessIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    background: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Workout history',
                    style: AppText.screenTitle.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.screenBottomInset,
                      ),
                      child: WorkoutSessionListSkeleton(),
                    )
                  : _rows.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No workouts yet',
                        message: 'Finish a workout and it will show up here.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: c.primary,
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.screenBottomInset,
                        ),
                        itemCount: _rows.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _rows.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final row = _rows[index];
                          return WorkoutSessionRowCard(
                            row: row,
                            onTap: () => _open(row),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of workout history — also used on the Fitness home, so the two
/// lists cannot drift apart.
class WorkoutSessionRowCard extends StatelessWidget {
  const WorkoutSessionRowCard({super.key, required this.row, this.onTap});

  final WorkoutSessionRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final abandoned = row.status == 'abandoned';
    final date = row.startedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: abandoned ? c.surfaceMuted : c.primarySoftStrong,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  abandoned
                      ? Icons.remove_circle_outline_rounded
                      : Icons.fitness_center_rounded,
                  size: 20,
                  color: abandoned ? c.textSubtle : c.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.routineName.isEmpty ? row.planName : row.routineName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMedium.copyWith(color: c.text),
                    ),
                    Text(
                      date == null
                          ? row.planName
                          : DateFormat('EEE d MMM · HH:mm').format(date),
                      style: AppText.caption.copyWith(color: c.textSubtle),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatClock(row.durationSec),
                    style: AppText.bodySm.copyWith(color: c.text),
                  ),
                  Text(
                    '${row.completedSets} sets · ${row.exerciseCount} ex',
                    style: AppText.caption.copyWith(color: c.textSubtle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
