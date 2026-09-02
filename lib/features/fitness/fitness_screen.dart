import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/widgets/misc.dart';
import '../../data/models/exercise_animation_model.dart';
import '../../data/repositories/exercise_animations_repository.dart';

/// Fitness home — a throwaway harness for the seeded animation catalog.
///
/// Pick a gender, muscle and equipment; every matching exercise then plays for
/// five seconds before the next one starts. Intentionally undesigned: this
/// exists to prove the catalog renders end to end, not to be a screen.
class FitnessHome extends ConsumerStatefulWidget {
  const FitnessHome({super.key});

  @override
  ConsumerState<FitnessHome> createState() => _FitnessHomeState();
}

class _FitnessHomeState extends ConsumerState<FitnessHome> {
  /// The schema's `gender` enum. Fixed rather than fetched — it is the one axis
  /// of the filter that cannot grow.
  static const List<String> _genders = ['Men', 'Women'];
  static const Duration _slide = Duration(seconds: 5);

  String? _gender;
  String? _muscle;
  String? _equipment;

  List<String> _muscles = const [];
  List<String> _equipments = const [];
  List<ExerciseAnimationModel> _exercises = const [];

  int _index = 0;
  Uint8List? _bytes;
  Timer? _timer;
  String? _error;
  bool _busy = false;

  /// Bumped on every selection change. Each async continuation captures the
  /// value it started with and bails if it no longer matches, so a slow reply
  /// for an abandoned selection cannot overwrite a newer one — the five-second
  /// timer guarantees these requests overlap.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ExerciseAnimationsRepository get _repo =>
      ref.read(exerciseAnimationsRepositoryProvider);

  /// Reloads the dependent dropdowns, then the exercise list once all three
  /// are chosen. Muscle and equipment narrow to the current selection because
  /// the catalog is not a full cross product.
  Future<void> _refresh() async {
    final generation = ++_generation;
    _timer?.cancel();
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final muscles = await _repo.muscles(gender: _gender);
      final equipments = await _repo.equipments(
        gender: _gender,
        muscle: _muscle,
      );
      if (!mounted || generation != _generation) return;

      setState(() {
        _muscles = muscles;
        _equipments = equipments;
        if (_muscle != null && !muscles.contains(_muscle)) _muscle = null;
        if (_equipment != null && !equipments.contains(_equipment)) {
          _equipment = null;
        }
      });

      if (_gender == null || _muscle == null || _equipment == null) {
        setState(() {
          _exercises = const [];
          _bytes = null;
          _index = 0;
          _busy = false;
        });
        return;
      }

      final exercises = await _repo.exercises(
        gender: _gender,
        muscle: _muscle,
        equipment: _equipment,
      );
      if (!mounted || generation != _generation) return;

      setState(() {
        _exercises = exercises;
        _index = 0;
        _bytes = null;
        _busy = false;
      });
      _startCycle(generation);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = '$error';
        _busy = false;
      });
    }
  }

  void _startCycle(int generation) {
    _timer?.cancel();
    if (_exercises.isEmpty) return;

    _loadComposition(generation);
    _timer = Timer.periodic(_slide, (_) {
      if (!mounted || generation != _generation || _exercises.isEmpty) return;
      setState(() {
        _index = (_index + 1) % _exercises.length;
        _bytes = null;
      });
      _loadComposition(generation);
    });
  }

  Future<void> _loadComposition(int generation) async {
    if (_index >= _exercises.length) return;
    final wanted = _exercises[_index];

    try {
      final bytes = await _repo.composition(wanted.id);
      if (!mounted || generation != _generation) return;
      // The timer may have moved on while this was in flight.
      if (_index >= _exercises.length || _exercises[_index].id != wanted.id) {
        return;
      }
      setState(() => _bytes = bytes);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = (_index < _exercises.length) ? _exercises[_index] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown('Gender', _gender, _genders, (value) {
            setState(() {
              _gender = value;
              _muscle = null;
              _equipment = null;
            });
            _refresh();
          }),
          const SizedBox(height: 12),
          _dropdown('Muscle', _muscle, _muscles, (value) {
            setState(() {
              _muscle = value;
              _equipment = null;
            });
            _refresh();
          }),
          const SizedBox(height: 12),
          _dropdown('Equipment', _equipment, _equipments, (value) {
            setState(() => _equipment = value);
            _refresh();
          }),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (current == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pick a gender, muscle and equipment to play the catalog.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Text(
              '${_index + 1} / ${_exercises.length}   ${current.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${current.muscle} · ${current.equipment} · ${current.durationMs} ms',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            // The composition carries its own canvas size; without it a
            // landscape animation letterboxes inside a square box.
            AspectRatio(
              aspectRatio: current.aspectRatio,
              child: _bytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : Lottie.memory(_bytes!, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          // Guarded because the options list is reloaded underneath the
          // selection; a value that is no longer offered would assert.
          value: options.contains(value) ? value : null,
          hint: Text(options.isEmpty ? 'None available' : 'Choose $label'),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: options.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

/// Stand-in for the Fitness surfaces until the real screens land.
///
/// Selecting Fitness in the app switcher re-points all four shell branches at
/// once, so every branch needs *something* to render from the moment the third
/// segment exists — otherwise Fitness silently inherits Healthify's screens
/// (the old `if (wealthify) ... else healthify` fall-through). Each branch
/// passes its own [title]/[message] so the tab bar still reads coherently.
///
/// Replace these call sites one at a time as the real screens are built; the
/// switch statements that select them are exhaustive, so nothing goes stale
/// without the analyzer saying so.
class FitnessPlaceholder extends StatelessWidget {
  const FitnessPlaceholder({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.fitness_center_rounded,
      title: title,
      message: message,
    );
  }
}
