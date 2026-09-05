import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exercise_animations_repository.dart';

final exerciseAnimationCacheProvider = Provider<ExerciseAnimationCache>(
  (ref) => ExerciseAnimationCache(ref.read(exerciseAnimationsRepositoryProvider)),
);

/// A process-wide cache of Lottie compositions, keyed by catalog id.
///
/// The workout screens show the same handful of animations over and over — the
/// picker's thumbnails, the config screen's preview, the session's player — and
/// each one is a ~100 KB decompressed document. Without a shared cache every
/// screen refetches what the one before it just had, and the user sees a
/// spinner on each. [peek] exists so a widget can paint a cached animation
/// synchronously in its first `build` and never show a loader at all.
///
/// Bounded because the catalog is 1,603 entries long: `Map` iterates in
/// insertion order, so dropping the first key evicts the oldest fetch. Anything
/// currently on screen holds its own reference to the bytes and survives
/// eviction.
class ExerciseAnimationCache {
  ExerciseAnimationCache(this._repo);

  final ExerciseAnimationsRepository _repo;

  static const int _limit = 24;

  final Map<String, Uint8List> _bytes = {};

  /// Requests already in flight, so two widgets asking for the same animation
  /// in the same frame share one round trip instead of racing.
  final Map<String, Future<Uint8List?>> _inFlight = {};

  /// The bytes if they are already here, without starting a fetch.
  Uint8List? peek(String? id) => (id == null || id.isEmpty) ? null : _bytes[id];

  /// Fetches (or joins an in-flight fetch) and caches. Returns null when the
  /// animation cannot be loaded — the caller shows its placeholder rather than
  /// an error, because a missing animation is cosmetic.
  Future<Uint8List?> load(String? id) {
    if (id == null || id.isEmpty) return Future.value();

    final hit = _bytes[id];
    if (hit != null) return Future.value(hit);

    return _inFlight.putIfAbsent(id, () async {
      try {
        final bytes = await _repo.composition(id);
        _bytes[id] = bytes;
        if (_bytes.length > _limit) _bytes.remove(_bytes.keys.first);
        return bytes;
      } catch (_) {
        return null;
      } finally {
        _inFlight.remove(id);
      }
    });
  }

  /// Warms the cache without waiting — used to pull the next exercise's
  /// animation while the current one is still playing.
  void prefetch(Iterable<String?> ids) {
    for (final id in ids) {
      if (id == null || id.isEmpty) continue;
      if (_bytes.containsKey(id) || _inFlight.containsKey(id)) continue;
      load(id);
    }
  }
}
