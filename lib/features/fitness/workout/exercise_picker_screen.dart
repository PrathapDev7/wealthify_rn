import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/exercise_animation_cache.dart';
import '../../../data/repositories/exercise_catalog_cache.dart';
import '../../../data/repositories/workout_repository.dart';
import 'exercise_config_screen.dart';
import 'workout_widgets.dart';

/// Picks the next exercise for a routine: search, the muscle/equipment
/// filters, what the user has done before, and the full catalog.
///
/// Pops the [ExerciseEdit] the config screen made, so the plan screen can add
/// it to its list directly; pops nothing when the user simply backs out.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({
    super.key,
    required this.planId,
    required this.routineId,
  });

  final String planId;
  final String routineId;

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  /// Rows rendered at a time. Not a page of anything — the whole catalog is
  /// already in memory — just a cap on how much of a 1,600-row list is built
  /// before the user has scrolled anywhere near it.
  static const int _renderStep = 40;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  String _query = '';
  String? _muscle;
  String? _equipment;

  List<PreviousExercise> _previous = const [];
  bool _previousOpen = false;

  List<ExerciseCatalogItem> _matches = const [];
  int _shown = _renderStep;

  // Held rather than read on demand: dispose() has to detach from it, and by
  // then reading a provider is no longer safe.
  late final ExerciseCatalogCache _cache = ref.read(
    exerciseCatalogCacheProvider,
  );

  List<MuscleCount> get _muscles => _cache.muscles;
  List<String> get _equipments => _cache.equipments;

  /// Only ever true on the very first run, before the catalog has been pulled
  /// once — after that it is on disk and the screen opens straight onto it.
  late bool _loading = !_cache.isReady;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _cache.addListener(_onCatalogChanged);
    if (_cache.isReady) {
      _matches = _filtered();
    } else {
      _loadCatalog();
    }
    _loadPrevious();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cache.removeListener(_onCatalogChanged);
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _shown >= _matches.length) return;
    final position = _scrollCtrl.position;
    if (position.pixels > position.maxScrollExtent - 400) {
      setState(() => _shown += _renderStep);
    }
  }

  /// Only reached before the catalog has ever been pulled; every later visit
  /// finds it ready in [initState].
  Future<void> _loadCatalog() async {
    await _cache.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
    _applyFilters();
    if (!_cache.isReady) {
      // Nothing on disk and the pull failed — say so, rather than leaving the
      // user to read an empty catalog as "no matches".
      showAppSnack(context, 'Could not load the exercise catalog', error: true);
    }
  }

  /// The background refresh landing behind us — re-filter against whatever the
  /// catalog now holds.
  void _onCatalogChanged() => _applyFilters();

  Future<void> _loadPrevious() async {
    try {
      final previous = await ref
          .read(workoutRepositoryProvider)
          .previousExercises();
      if (mounted) setState(() => _previous = previous);
    } catch (_) {
      // A convenience section; the catalog below it still works without it.
    }
  }

  /// Search and the two dropdowns, run over the local catalog — the same
  /// comparison the API made (a case-insensitive substring of the name or
  /// either muscle field, and exact matches on the filters).
  List<ExerciseCatalogItem> _filtered() {
    final query = _query.toLowerCase();
    return [
      for (final item in _cache.items)
        if ((_muscle == null || item.primaryMuscle == _muscle) &&
            (_equipment == null || item.equipment == _equipment) &&
            (query.isEmpty ||
                item.name.toLowerCase().contains(query) ||
                item.muscle.toLowerCase().contains(query) ||
                item.primaryMuscle.toLowerCase().contains(query)))
          item,
    ];
  }

  void _applyFilters() {
    if (!mounted) return;
    final matches = _filtered();
    setState(() {
      _matches = matches;
      _shown = _renderStep;
    });
    ref
        .read(exerciseAnimationCacheProvider)
        .prefetch(matches.take(8).map((e) => e.catalogId));
  }

  void _onSearchChanged(String value) {
    // Still debounced, even with nothing to wait for: it keeps a fast typist
    // from rebuilding the list on every keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _query = value.trim();
      _applyFilters();
    });
  }

  /// Sends the chosen movement to the config screen, and closes the picker
  /// when it comes back having created something.
  Future<void> _configure(
    RoutineExercise draft, {
    ExerciseCatalogItem? catalogItem,
  }) async {
    final added = await pushFitness<ExerciseEdit>(
      context,
      ExerciseConfigScreen(
        planId: widget.planId,
        routineId: widget.routineId,
        exercise: draft,
        catalogItem: catalogItem,
        isNew: true,
      ),
    );
    // Passed straight through: the plan screen wants the exercise that was
    // created, not just the news that one was.
    if (added != null && mounted) Navigator.of(context).pop(added);
  }

  void _pickCatalogItem(ExerciseCatalogItem item) {
    _configure(
      RoutineExercise(
        id: '',
        name: item.name,
        catalogId: item.catalogId,
        muscle: item.muscle,
        primaryMuscle: item.primaryMuscle,
        equipment: item.equipment,
        // One empty set to start: the reference's add screen opens with row 1
        // already there, waiting for numbers.
        sets: const [WorkoutSet()],
        notes: item.numberedInstructions,
      ),
      catalogItem: item,
    );
  }

  void _pickPrevious(PreviousExercise previous) {
    _configure(
      RoutineExercise(
        id: '',
        name: previous.name,
        catalogId: previous.catalogId,
        customExercise: previous.customExercise,
        muscle: previous.muscle,
        primaryMuscle: previous.primaryMuscle,
        equipment: previous.equipment,
        sets: const [WorkoutSet()],
      ),
    );
  }

  Future<void> _addCustom() async {
    // Created from inside the prompt, which sits on "Adding…" until the API
    // answers rather than closing onto a config screen for something that may
    // not exist yet.
    CustomExercise? custom;
    final name = await showNamePrompt(
      context,
      title: 'Add custom exercise',
      hint: 'Exercise name',
      confirmLabel: 'Add',
      pendingLabel: 'Adding…',
      onConfirm: (value) async {
        custom = await ref
            .read(workoutRepositoryProvider)
            .addCustomExercise(name: value);
      },
    );
    if (name == null || custom == null || !mounted) return;

    _configure(
      RoutineExercise(
        id: '',
        name: custom!.name,
        customExercise: custom!.id,
        muscle: custom!.muscle,
        equipment: custom!.equipment,
        sets: const [WorkoutSet()],
      ),
    );
  }

  Future<void> _pickMuscle() async {
    final choice = await showFitnessSheet<String>(
      context: context,
      // Half the screen: the full muscle list is long enough to fill it
      // otherwise, at which point it stops reading as a sheet at all.
      heightFactor: 0.5,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetActionRow(
              label: 'Any muscle',
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            for (final m in _muscles)
              SheetActionRow(
                label: m.muscle,
                onTap: () => Navigator.of(sheetContext).pop(m.muscle),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    _muscle = choice.isEmpty ? null : choice;
    _applyFilters();
  }

  Future<void> _pickEquipment() async {
    final choice = await showFitnessSheet<String>(
      context: context,
      heightFactor: 0.5,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetActionRow(
              label: 'Any equipment',
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            for (final e in _equipments)
              SheetActionRow(
                label: e,
                onTap: () => Navigator.of(sheetContext).pop(e),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    _equipment = choice.isEmpty ? null : choice;
    _applyFilters();
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
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: c.textSubtle,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              cursorColor: c.primary,
                              style: AppText.body.copyWith(color: c.text),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Exercise name or muscle',
                                hintStyle: AppText.body.copyWith(
                                  color: c.textPlaceholder,
                                ),
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _query = '';
                                _applyFilters();
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: c.textSubtle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const _PickerSkeleton()
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.screenBottomInset,
                      ),
                      children: [
                        _AddCustomButton(onTap: _addCustom),
                        if (_previous.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          FitnessPill(
                            onTap: () => setState(
                              () => _previousOpen = !_previousOpen,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Previous exercises (${_previous.length})',
                                    style: AppText.bodyLarge.copyWith(
                                      color: c.text,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _previousOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: c.text,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          if (_previousOpen)
                            for (final p in _previous)
                              _ExerciseRow(
                                catalogId: p.catalogId,
                                name: p.name,
                                muscle: p.muscleLabel,
                                equipment: p.equipment ?? '',
                                onTap: () => _pickPrevious(p),
                              ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Full exercises catalog',
                          // A normal-weight style, not subtitle + copyWith:
                          // google_fonts drops a copyWith fontWeight on its
                          // way to the font file, so that stayed bold.
                          style: AppText.bodyLargeRegular.copyWith(
                            color: c.textSubtle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _FilterColumn(
                                label: 'Muscle',
                                child: _FilterDropdown(
                                  label: _muscle ?? 'Any muscle',
                                  active: _muscle != null,
                                  onTap: _pickMuscle,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _FilterColumn(
                                label: 'Equipment',
                                child: _FilterDropdown(
                                  label: _equipment ?? 'Any equipment',
                                  active: _equipment != null,
                                  onTap: _pickEquipment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_matches.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xl4),
                            child: const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Nothing matched',
                              message:
                                  'Try another name, or clear the muscle and '
                                  'equipment filters.',
                            ),
                          )
                        else
                          for (final item in _matches.take(_shown))
                            _ExerciseRow(
                              catalogId: item.catalogId,
                              name: item.name,
                              muscle: item.muscleLabel,
                              equipment: item.equipment,
                              onTap: () => _pickCatalogItem(item),
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder mirroring the loaded layout: the "Add custom" button,
/// the filter row, and a few catalog rows.
class _PickerSkeleton extends StatelessWidget {
  const _PickerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.screenBottomInset,
      ),
      children: const [
        SkeletonBox(width: double.infinity, height: 46, radius: AppRadius.pill),
        SizedBox(height: AppSpacing.lg),
        SkeletonLine(width: 150, height: 16),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 50, height: 11),
                  SkeletonGap(AppSpacing.sm),
                  SkeletonLine(width: 90, height: 14),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 70, height: 11),
                  SkeletonGap(AppSpacing.sm),
                  SkeletonLine(width: 110, height: 14),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        ExerciseRowListSkeleton(),
      ],
    );
  }
}

/// [ExerciseRowSkeleton], repeated.
class ExerciseRowListSkeleton extends StatelessWidget {
  const ExerciseRowListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [for (var i = 0; i < count; i++) const ExerciseRowSkeleton()],
  );
}

/// Placeholder matching [_ExerciseRow]'s exact shape: a thumbnail and three
/// text lines spread across its height.
class ExerciseRowSkeleton extends StatelessWidget {
  const ExerciseRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const thumbSize = 72.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(
                width: thumbSize,
                height: thumbSize,
                radius: AppRadius.sm,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: thumbSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SkeletonLine(width: 150, height: 16),
                          SkeletonGap(AppSpacing.xs),
                          SkeletonLine(width: 80, height: 12),
                        ],
                      ),
                      SkeletonLine(width: 100, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCustomButton extends StatelessWidget {
  const _AddCustomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.borderStrong),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 11,
                color: c.textOnPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Add custom', style: AppText.bodyMedium.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}

/// The small caption label the reference prints above each filter dropdown.
class _FilterColumn extends StatelessWidget {
  const _FilterColumn({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: active ? c.primary : c.border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  color: active ? c.primary : c.text,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? c.primary : c.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

/// One catalog / previous-exercise row: thumbnail, name, muscle, equipment.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.catalogId,
    required this.name,
    required this.muscle,
    required this.equipment,
    required this.onTap,
  });

  final String? catalogId;
  final String name;
  final String muscle;
  final String equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const thumbSize = 72.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseThumb(catalogId: catalogId, size: thumbSize),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: thumbSize,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Each of the three lines is held to one line: the
                            // column is fixed to the thumbnail's height, so a
                            // long name wrapping is an overflow, not a taller
                            // row.
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMedium.copyWith(color: c.text),
                            ),
                            if (muscle.isNotEmpty)
                              Text(
                                muscle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodySm.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        if (equipment.isNotEmpty)
                          Text(
                            equipment,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm.copyWith(color: c.textSubtle),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
