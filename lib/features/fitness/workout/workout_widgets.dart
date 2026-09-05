import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/misc.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/repositories/exercise_animation_cache.dart';

/* ----------------------------------------------------------- navigation -- */

/// Pushes a workout screen on the root navigator — above the tab bar, the way
/// the reference's full-bleed screens sit — and re-applies the Fitness palette,
/// which a root route would otherwise not inherit from the tab's subtree.
Future<T?> pushFitness<T>(BuildContext context, Widget child) =>
    Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(builder: (_) => FitnessTheme(child: child)),
    );

/* --------------------------------------------------------------- format -- */

/// `mm:ss`, or `h:mm:ss` once a workout runs past the hour.
String formatClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// The rest label on a card and in the config screen: a zero rest is "Off",
/// not "00:00" — the reference treats no rest as an absent feature rather than
/// a zero-length one.
String formatRest(int seconds) => seconds <= 0 ? 'Off' : formatClock(seconds);

/// Trims a planned number for display: `12`, `2.5`, and `-` for nothing set.
String formatValue(num? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/* ------------------------------------------------------------ animation -- */

/// Plays one catalog animation on the white panel the reference uses.
///
/// The catalog art is drawn for a white ground, so the panel stays white in
/// both themes — it is the one surface in the workout screens that does not
/// follow the palette.
class ExerciseAnimationView extends ConsumerStatefulWidget {
  const ExerciseAnimationView({
    super.key,
    required this.catalogId,
    this.aspectRatio = 1,
    this.radius = AppRadius.md,
    this.padding = EdgeInsets.zero,
    this.fallbackIcon = Icons.fitness_center_rounded,
  });

  final String? catalogId;
  final double aspectRatio;
  final double radius;
  final EdgeInsets padding;
  final IconData fallbackIcon;

  @override
  ConsumerState<ExerciseAnimationView> createState() =>
      _ExerciseAnimationViewState();
}

class _ExerciseAnimationViewState extends ConsumerState<ExerciseAnimationView> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimationView old) {
    super.didUpdateWidget(old);
    if (old.catalogId != widget.catalogId) {
      _bytes = null;
      _failed = false;
      _resolve();
    }
  }

  /// Paints straight from the cache when the bytes are already there, so a
  /// revisited animation never flashes a placeholder.
  void _resolve() {
    final cache = ref.read(exerciseAnimationCacheProvider);
    final hit = cache.peek(widget.catalogId);
    if (hit != null) {
      _bytes = hit;
      return;
    }

    final wanted = widget.catalogId;
    cache.load(wanted).then((bytes) {
      if (!mounted || wanted != widget.catalogId) return;
      setState(() {
        _bytes = bytes;
        _failed = bytes == null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bytes = _bytes;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Container(
        color: Colors.white,
        padding: widget.padding,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio <= 0 ? 1 : widget.aspectRatio,
          child: bytes == null
              ? Center(
                  child: Icon(
                    widget.fallbackIcon,
                    // A failed load settles on a grey glyph; a pending one
                    // fades it, so the panel never jumps between two layouts.
                    color: (_failed ? c.textSubtle : c.textPlaceholder)
                        .withValues(alpha: 0.5),
                    size: 28,
                  ),
                )
              : Lottie.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// The 56pt white square in front of every exercise row.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({super.key, required this.catalogId, this.size = 56});

  final String? catalogId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ExerciseAnimationView(
        catalogId: catalogId,
        radius: AppRadius.sm,
        padding: const EdgeInsets.all(2),
      ),
    );
  }
}

/* -------------------------------------------------------------- controls -- */

/// The reference's black square control — the `⋮`, the back chevron, the chart
/// and notes buttons. A near-black tile cut out of the graphite page.
class FitnessIconButton extends StatelessWidget {
  const FitnessIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.color,
    this.radius = AppRadius.sm,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: background ?? c.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: color ?? c.text),
        ),
      ),
    );
  }
}

/// A black pill with a label — the plan selector, the search box, the
/// "Previous exercises" toggle.
class FitnessPill extends StatelessWidget {
  const FitnessPill({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.background,
    this.border,
    this.radius = AppRadius.pill,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? background;
  final Color? border;

  /// Fully round by default; override for the pills that should read as a
  /// rounded box instead, like the plan switcher in the Workouts header.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: background ?? c.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The grey muscle divider that sits between groups of exercise cards.
class MuscleGroupChip extends StatelessWidget {
  const MuscleGroupChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: c.textSecondary),
      ),
    );
  }
}

/// The two-part exercise card shared by the routine list and the workout
/// summary: the movement on top, its planned volume on the strip underneath.
class ExerciseInfoCard extends StatelessWidget {
  const ExerciseInfoCard({
    super.key,
    required this.catalogId,
    required this.name,
    required this.muscleLabel,
    required this.restBetweenSetsSec,
    required this.setCount,
    required this.statValue,
    required this.statLabel,
    this.accentColor,
    this.onTap,
    this.trailing,
  });

  final String? catalogId;
  final String name;
  final String muscleLabel;
  final int restBetweenSetsSec;
  final int setCount;

  /// The first set's headline number (reps, or a formatted clock for timed
  /// exercises) and the unit under it.
  final String statValue;
  final String statLabel;

  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Width of the colour tag running down the card's left edge.
  static const _accentWidth = 6.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = accentColor;
    // Content is pushed clear of the tag so the two never touch.
    final leftPad = accent == null
        ? AppSpacing.md
        : AppSpacing.md + _accentWidth;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // A full-height stripe on the edge rather than a stub beside the
            // thumbnail: the colour is how a routine is scanned, so it has to
            // read at a glance down the whole list.
            if (accent != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _accentWidth,
                child: ColoredBox(color: accent),
              ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    leftPad,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      ExerciseThumb(catalogId: catalogId, size: 72),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMedium.copyWith(color: c.text),
                            ),
                            if (muscleLabel.isNotEmpty)
                              Text(
                                muscleLabel,
                                style: AppText.bodySm.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.xs),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Rest time - ',
                                    style: AppText.bodySm.copyWith(
                                      color: c.textSubtle,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatRest(restBetweenSetsSec),
                                    style: AppText.bodyMedium.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: c.surfaceMuted,
                  padding: EdgeInsets.fromLTRB(
                    leftPad,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: accent ?? c.textSubtle,
                          shape: BoxShape.circle,
                        ),
                      ),
                      _Stat(value: '$setCount', label: 'Sets'),
                      const SizedBox(width: AppSpacing.lg),
                      _Stat(value: statValue, label: statLabel),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: AppText.bodyMedium.copyWith(color: c.text),
          ),
          TextSpan(
            text: ' $label',
            style: AppText.bodySm.copyWith(color: c.textSubtle),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------- skeletons -- */

/// Placeholder matching [ExerciseInfoCard]'s exact shape: thumbnail, two
/// text lines, and the stats strip underneath.
class ExerciseCardSkeleton extends StatelessWidget {
  const ExerciseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 72, height: 72, radius: AppRadius.sm),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLine(width: 170, height: 14),
                        const SkeletonGap(AppSpacing.xs),
                        const SkeletonLine(width: 90, height: 12),
                        const SkeletonGap(AppSpacing.sm),
                        const SkeletonLine(width: 120, height: 12),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 36, height: 36, radius: AppRadius.sm),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: c.surfaceMuted,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const SkeletonLine(width: 56, height: 12),
                  const SizedBox(width: AppSpacing.lg),
                  const SkeletonLine(width: 56, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [ExerciseCardSkeleton], repeated — the routine list and picker catalog's
/// loading state.
class ExerciseCardListSkeleton extends StatelessWidget {
  const ExerciseCardListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [for (var i = 0; i < count; i++) const ExerciseCardSkeleton()],
  );
}

/// Placeholder matching [WorkoutSessionRowCard]'s exact shape: a leading
/// icon square, two lines of text, and two lines of trailing stats.
class WorkoutSessionRowSkeleton extends StatelessWidget {
  const WorkoutSessionRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 44, height: 44, radius: AppRadius.sm),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 140, height: 14),
                  const SkeletonGap(AppSpacing.xs),
                  const SkeletonLine(width: 110, height: 11),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SkeletonLine(width: 44, height: 12),
                const SkeletonGap(AppSpacing.xs),
                const SkeletonLine(width: 76, height: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// [WorkoutSessionRowSkeleton], repeated — the history list and the Fitness
/// home "recent workouts" loading state.
class WorkoutSessionListSkeleton extends StatelessWidget {
  const WorkoutSessionListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++) const WorkoutSessionRowSkeleton(),
    ],
  );
}

/* ---------------------------------------------------------------- sheets -- */

/// The palette's own bottom-sheet shell — rounded, near-black, with the grab
/// handle the reference draws on every sheet.
///
/// [heightFactor] caps how much of the screen it may take. A long list — the
/// muscle and equipment pickers — would otherwise grow until the sheet was
/// indistinguishable from a full-screen page.
Future<T?> showFitnessSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double heightFactor = 0.85,
}) {
  final c = context.colors;
  // showModalBottomSheet inserts its route as a sibling overlay entry of the
  // pushed workout screen, not a descendant of its FitnessTheme — so without
  // re-applying the theme here, the sheet's own content would resolve colors
  // from the ambient (non-Fitness) app theme instead. On a light-mode device
  // that means near-black text on this sheet's near-black surface: invisible,
  // which is what a "blank" sheet actually is.
  final theme = Theme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: c.surface,
    barrierColor: c.overlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => Theme(
      data: theme,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * heightFactor,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(child: builder(sheetContext)),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A row in one of the action sheets.
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    super.key,
    this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
    this.trailing,
    this.enabled = true,
  });

  /// Optional: the pickers that list plain values (a muscle, a piece of
  /// equipment) read better without one in front of every row.
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  /// A disabled row stays in the list, greyed and untappable, so the option is
  /// still where the user expects to find it.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = enabled
        ? (danger ? c.negative : c.text)
        : c.textPlaceholder;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(color: tint),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A plain menu sheet: a grab handle, a quiet heading naming what is being
/// acted on, and a list of [SheetActionRow]s that pop their own result.
///
/// Pushed on the root navigator so it covers everything — a screen shown as a
/// tab body sits inside a branch navigator whose overlay stops at [AppShell]'s
/// body, which would slide the sheet up *behind* the floating nav bar.
Future<T?> showFitnessOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<Widget> Function(BuildContext sheetContext) options,
}) {
  // Resolved here and not inside the builder: the sheet's route is a sibling
  // overlay entry of the calling screen, not a descendant of its FitnessTheme,
  // so colors looked up in the builder would come from the ambient app theme
  // instead (see showFitnessSheet for the same trap).
  final c = context.colors;
  final theme = Theme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.overlay,
    builder: (sheetContext) => Theme(
      data: theme,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            // c.surface is deliberately *darker* than the background in
            // fitnessDark — under the sheet's dimming barrier it lands on the
            // same shade as its own backdrop. surfaceElevated is the token
            // that lifts a surface off the page.
            color: c.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            boxShadow: AppShadows.xl,
          ),
          // The sheet route's own Material sits behind this Container (the
          // sheet background is transparent), so the rows' ink would be
          // painted under the surface — this one puts it back on top.
          child: Material(
            type: MaterialType.transparency,
            // The rows run edge to edge and carry their own padding, so only
            // the heading is inset here.
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: c.borderStrong,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Same size as the options below it; the muted color is
                      // what sets it apart, not a smaller type size.
                      style: AppText.body.copyWith(color: c.textSubtle),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...options(sheetContext),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Runs [action] behind a dialog that cannot be dismissed, for the writes with
/// no button of their own to disable — a menu row that fires straight off, say.
/// The screen behind it stays put and untappable until the API answers, and a
/// failure comes back as null with [onError] told why.
Future<T?> runWithPendingDialog<T>(
  BuildContext context, {
  required String label,
  required Future<T> Function() action,
  void Function(Object error)? onError,
}) async {
  final c = context.colors;
  final theme = Theme.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  var closed = false;
  unawaited(
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: c.overlay,
      builder: (_) => Theme(
        data: theme,
        child: PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: c.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.bodyMedium.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void close() {
    if (closed) return;
    closed = true;
    navigator.pop();
  }

  try {
    final result = await action();
    close();
    return result;
  } catch (e) {
    close();
    onError?.call(e);
    return null;
  }
}

/// The filled Save button the sheets end with, which runs its own write: it
/// disables itself and reads [pendingLabel] until the call comes back, so the
/// sheet cannot be double-submitted or closed onto a half-finished save.
class SheetSaveButton extends StatefulWidget {
  const SheetSaveButton({
    super.key,
    required this.onPressed,
    this.label = 'Save',
    this.pendingLabel = 'Saving…',
  });

  final Future<void> Function() onPressed;
  final String label;
  final String pendingLabel;

  @override
  State<SheetSaveButton> createState() => _SheetSaveButtonState();
}

class _SheetSaveButtonState extends State<SheetSaveButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } catch (e) {
      // The sheet stays open on a failure, with the button live again, so the
      // save can be retried without redoing the input.
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.textOnPrimary,
        disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
        disabledForegroundColor: c.textOnPrimary.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      onPressed: _busy ? null : _run,
      child: Text(
        _busy ? widget.pendingLabel : widget.label,
        style: AppText.button,
      ),
    );
  }
}

/// The minutes/seconds wheel behind "Rest between sets" and "Rest between
/// exercises". Returns the chosen number of seconds, or null if dismissed.
///
/// Pass [onSave] to run the write from inside the sheet: Save reads "Saving…"
/// and the sheet stays open until the API answers.
Future<int?> showDurationSheet(
  BuildContext context, {
  required String title,
  required int initialSeconds,
  int maxMinutes = 10,
  Future<void> Function(int seconds)? onSave,
}) {
  return showFitnessSheet<int>(
    context: context,
    builder: (sheetContext) => _DurationSheet(
      title: title,
      initialSeconds: initialSeconds,
      maxMinutes: maxMinutes,
      onSave: onSave,
    ),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({
    required this.title,
    required this.initialSeconds,
    required this.maxMinutes,
    this.onSave,
  });

  final String title;
  final int initialSeconds;
  final int maxMinutes;
  final Future<void> Function(int seconds)? onSave;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _minutes = (widget.initialSeconds ~/ 60)
      .clamp(0, widget.maxMinutes);
  late int _seconds = widget.initialSeconds % 60;

  late final FixedExtentScrollController _minCtrl =
      FixedExtentScrollController(initialItem: _minutes);
  late final FixedExtentScrollController _secCtrl =
      FixedExtentScrollController(initialItem: _seconds);

  @override
  void dispose() {
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppText.bodyLargeRegular.copyWith(color: c.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _wheel(
                        controller: _minCtrl,
                        count: widget.maxMinutes + 1,
                        unit: 'min',
                        onChanged: (v) => setState(() => _minutes = v),
                      ),
                    ),
                    Expanded(
                      child: _wheel(
                        controller: _secCtrl,
                        count: 60,
                        unit: 'sec',
                        onChanged: (v) => setState(() => _seconds = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: SheetSaveButton(
              onPressed: () async {
                final seconds = _minutes * 60 + _seconds;
                await widget.onSave?.call(seconds);
                if (mounted) Navigator.of(context).pop(seconds);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    final c = context.colors;
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 40,
      squeeze: 1.1,
      onSelectedItemChanged: onChanged,
      selectionOverlay: const SizedBox.shrink(),
      children: [
        for (var i = 0; i < count; i++)
          Center(
            child: Text(
              '$i $unit',
              style: AppText.bodyLarge.copyWith(color: c.text),
            ),
          ),
      ],
    );
  }
}

/// The "New Routine" / "Rename" dialog: a title, one underlined field, Cancel
/// and Save. Returns the trimmed text, or null if cancelled or left empty.
///
/// Pass [onConfirm] to run the write from inside the dialog: the buttons and
/// the field go dead, the confirm button reads [pendingLabel] until the call
/// comes back, and only then does the dialog close — so the screen behind it
/// never updates out from under a dialog that is still open. A failure is
/// shown in place and leaves the dialog up to retry from.
Future<String?> showNamePrompt(
  BuildContext context, {
  required String title,
  String initial = '',
  String confirmLabel = 'Save',
  String? hint,
  int maxLength = 60,
  String pendingLabel = 'Saving…',
  Future<void> Function(String value)? onConfirm,
}) async {
  final c = context.colors;
  final controller = TextEditingController(text: initial);
  var busy = false;
  String? error;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> submit() async {
          final value = controller.text.trim();
          if (busy || value.isEmpty) return;
          if (onConfirm == null) {
            Navigator.of(dialogContext).pop(value);
            return;
          }
          setDialogState(() {
            busy = true;
            error = null;
          });
          try {
            await onConfirm(value);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(value);
            }
          } catch (e) {
            if (!dialogContext.mounted) return;
            setDialogState(() {
              busy = false;
              error = e.toString();
            });
          }
        }

        return PopScope(
          // Neither the back button nor a tap on the barrier can take the
          // dialog away while its write is still in flight.
          canPop: !busy,
          child: AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            title: Text(
              title,
              style: AppText.bodyLargeRegular.copyWith(color: c.text),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  enabled: !busy,
                  maxLength: maxLength,
                  textCapitalization: TextCapitalization.words,
                  style: AppText.bodyLargeRegular.copyWith(color: c.text),
                  cursorColor: c.primary,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    hintStyle: AppText.body.copyWith(color: c.textPlaceholder),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: c.primary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error!,
                    style: AppText.bodySm.copyWith(color: c.negative),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: AppText.button.copyWith(
                    color: busy ? c.textPlaceholder : c.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: busy ? null : submit,
                child: Text(
                  busy ? pendingLabel : confirmLabel,
                  style: AppText.button.copyWith(
                    color: busy ? c.textPlaceholder : c.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}

/// Yes/no for the destructive actions. Returns true only on an explicit
/// confirm.
///
/// Pass [onConfirm] to run the delete from inside the dialog — see
/// [showNamePrompt] for what that changes. True then means the call succeeded,
/// not just that the user tapped through.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String pendingLabel = 'Deleting…',
  Future<void> Function()? onConfirm,
}) async {
  final c = context.colors;
  var busy = false;
  String? error;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> confirm() async {
          if (busy) return;
          if (onConfirm == null) {
            Navigator.of(dialogContext).pop(true);
            return;
          }
          setDialogState(() {
            busy = true;
            error = null;
          });
          try {
            await onConfirm();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
          } catch (e) {
            if (!dialogContext.mounted) return;
            setDialogState(() {
              busy = false;
              error = e.toString();
            });
          }
        }

        return PopScope(
          canPop: !busy,
          child: AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            title: Text(
              title,
              style: AppText.bodyLargeRegular.copyWith(color: c.text),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppText.body.copyWith(color: c.textSecondary),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error!,
                    style: AppText.bodySm.copyWith(color: c.negative),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: AppText.button.copyWith(
                    color: busy ? c.textPlaceholder : c.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: busy ? null : confirm,
                child: Text(
                  busy ? pendingLabel : confirmLabel,
                  style: AppText.button.copyWith(
                    color: busy ? c.textPlaceholder : c.negative,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return ok ?? false;
}

/* --------------------------------------------------------------- colors -- */

/// The eight swatches on the exercise config screen. The first entry is null —
/// "no color", drawn as a check rather than a fill.
const List<String?> kExerciseColors = [
  null,
  '#5CC98E',
  '#4F9DFF',
  '#F0A94B',
  '#FF5C5C',
  '#B57BFF',
  '#22D3EE',
  '#F472B6',
];

/// Parses a `#RRGGBB` swatch back to a [Color]; null for "no color" and for
/// anything unparseable, so a bad value degrades to the default card rather
/// than throwing.
Color? parseSwatch(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// Slice colours for the muscle donut, reused by its legend so the chart and
/// the labels can never disagree.
const List<Color> kMuscleSliceColors = [
  Color(0xFF5CC98E),
  Color(0xFF4F9DFF),
  Color(0xFFF0A94B),
  Color(0xFFB57BFF),
  Color(0xFF22D3EE),
  Color(0xFFF472B6),
  Color(0xFFFF5C5C),
];

/// Completed sets split by muscle, with a headline number in the hole.
///
/// Drawn with plain painting rather than a chart package: it is one ring of
/// arcs, and this way the summary and the stats page share the exact same one.
class MuscleDonut extends StatelessWidget {
  const MuscleDonut({
    super.key,
    required this.muscles,
    required this.centerValue,
    required this.centerLabel,
    this.size = 200,
    this.thickness = 26,
    this.icon = Icons.fitness_center_rounded,
  });

  final List<MuscleSlice> muscles;
  final String centerValue;
  final String centerLabel;
  final double size;
  final double thickness;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = muscles.fold<int>(0, (sum, m) => sum + m.count);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              slices: total == 0 ? const [] : muscles,
              total: total,
              thickness: thickness,
              emptyColor: c.surfaceMuted,
            ),
          ),
          Container(
            width: size - thickness * 2 - 12,
            height: size - thickness * 2 - 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: c.primary),
                const SizedBox(height: 4),
                Text(
                  centerValue,
                  style: AppText.title.copyWith(color: c.text),
                ),
                Text(
                  centerLabel,
                  style: AppText.caption.copyWith(color: c.textSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One arc of [MuscleDonut] — kept separate from the API model so the widget
/// works for any "label + count" pair.
class MuscleSlice {
  const MuscleSlice({required this.label, required this.count});

  final String label;
  final int count;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.total,
    required this.thickness,
    required this.emptyColor,
  });

  final List<MuscleSlice> slices;
  final int total;
  final double thickness;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    if (slices.isEmpty || total == 0) {
      canvas.drawArc(rect, 0, 6.28318, false, paint..color = emptyColor);
      return;
    }

    // Starts at 12 o'clock and runs clockwise, leaving a hairline gap between
    // slices so neighbouring colours stay readable.
    const gap = 0.02;
    var start = -1.5708;
    for (var i = 0; i < slices.length; i++) {
      final sweep = 6.28318 * slices[i].count / total;
      canvas.drawArc(
        rect,
        start + gap / 2,
        (sweep - gap).clamp(0.01, 6.28318),
        false,
        paint..color = kMuscleSliceColors[i % kMuscleSliceColors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.total != total ||
      old.thickness != thickness ||
      old.slices.length != slices.length;
}

/// The labels under a [MuscleDonut], in the same order as its slices.
class MuscleLegend extends StatelessWidget {
  const MuscleLegend({super.key, required this.muscles});

  final List<MuscleSlice> muscles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < muscles.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: kMuscleSliceColors[i % kMuscleSliceColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${muscles[i].label} · ${muscles[i].count}',
                style: AppText.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
      ],
    );
  }
}
