import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_models.dart';
// dart:io does not exist on web, so the file half lives behind this: the stub
// misses on every read and drops every write, leaving the cache in memory for
// the session there.
import 'exercise_catalog_file_stub.dart'
    if (dart.library.io) 'exercise_catalog_file_io.dart';
import 'workout_repository.dart';

final exerciseCatalogCacheProvider = Provider<ExerciseCatalogCache>(
  (ref) => ExerciseCatalogCache(ref.read(workoutRepositoryProvider)),
);

/// The whole exercise catalog, held in memory and mirrored to disk, so the
/// picker can search and filter without a round trip.
///
/// The catalog is server-seeded reference data: ~1,600 rows of metadata that
/// only change when the animation library is re-seeded. Paging it from the API
/// on every keystroke and every filter change meant a spinner for each, so it
/// is pulled once in the background at app start and filtered locally
/// afterwards. The animations themselves are *not* part of this — they are
/// ~100 KB each and stay on demand behind [ExerciseAnimationCache].
///
/// Freshness is "show what we have, then quietly catch up": the disk copy is
/// served immediately and a refresh runs behind it, so a re-seeded catalog
/// lands on the next launch without the user waiting for it.
class ExerciseCatalogCache extends ChangeNotifier {
  ExerciseCatalogCache(this._repo);

  final WorkoutRepository _repo;

  static const _fileName = 'exercise_catalog.json';

  /// Bumped when the shape written to disk changes, so an old file is dropped
  /// rather than parsed into something the app no longer understands.
  static const _schemaVersion = 1;

  List<ExerciseCatalogItem> items = const [];
  List<MuscleCount> muscles = const [];
  List<String> equipments = const [];

  /// True once there is a catalog to show, from either source.
  bool get isReady => _ready;
  bool _ready = false;

  Future<void>? _boot;

  /// Starts the catalog loading and completes as soon as there is something to
  /// show. Safe to call from anywhere, as often as you like — the work happens
  /// once per app run.
  Future<void> ensureLoaded() => _boot ??= _load();

  Future<void> _load() async {
    if (await _readFromDisk()) {
      _ready = true;
      notifyListeners();
      // Caught up behind the user rather than in front of them.
      unawaited(_refresh());
      return;
    }
    // Nothing cached (first run, or a platform without a writable directory —
    // web) so this launch does have to wait for the network.
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _repo.fullCatalog(),
        _repo.catalogMuscles(),
        _repo.equipments(),
      ]);
      items = results[0] as List<ExerciseCatalogItem>;
      muscles = results[1] as List<MuscleCount>;
      equipments = results[2] as List<String>;
      _ready = true;
      notifyListeners();
      await _writeToDisk();
    } catch (_) {
      // Offline, or the catalog endpoint is down. Whatever came off disk still
      // stands; with nothing cached the picker shows its empty state, which is
      // the same thing it did when every keystroke hit the network.
    }
  }

  /* -------------------------------------------------------------- disk -- */

  Future<bool> _readFromDisk() async {
    try {
      final raw = await readCatalogFile(_fileName);
      if (raw == null) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      if (decoded['version'] != _schemaVersion) return false;

      final cached = _maps(decoded['items'])
          .map(ExerciseCatalogItem.fromJson)
          .toList();
      if (cached.isEmpty) return false;

      items = cached;
      muscles = _maps(decoded['muscles']).map(MuscleCount.fromJson).toList();
      equipments = ((decoded['equipments'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeToDisk() async {
    if (items.isEmpty) return;
    await writeCatalogFile(
      _fileName,
      jsonEncode({
        'version': _schemaVersion,
        'items': [for (final e in items) e.toJson()],
        'muscles': [for (final m in muscles) m.toJson()],
        'equipments': equipments,
      }),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
}
