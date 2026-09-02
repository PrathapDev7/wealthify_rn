import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/exercise_animation_model.dart';

final exerciseAnimationsRepositoryProvider =
    Provider<ExerciseAnimationsRepository>(
      (ref) => ExerciseAnimationsRepository(ref.read(apiClientProvider)),
    );

/// Reads the exercise animation catalog seeded into Mongo.
///
/// The filter triple (gender / muscle / equipment) is optional at every level:
/// the muscle and equipment lists narrow to whatever is already chosen, because
/// the catalog is not a full cross product and offering every combination leads
/// to selections with no exercises behind them.
class ExerciseAnimationsRepository {
  ExerciseAnimationsRepository(this._api);

  final ApiClient _api;

  Future<List<String>> muscles({String? gender}) async {
    final res = await _api.dio.get(
      'get-exercise-muscles',
      queryParameters: _filter(gender: gender),
    );
    return _strings(res.data);
  }

  Future<List<String>> equipments({String? gender, String? muscle}) async {
    final res = await _api.dio.get(
      'get-exercise-equipments',
      queryParameters: _filter(gender: gender, muscle: muscle),
    );
    return _strings(res.data);
  }

  Future<List<ExerciseAnimationModel>> exercises({
    String? gender,
    String? muscle,
    String? equipment,
  }) async {
    final res = await _api.dio.get(
      'get-exercises',
      queryParameters: _filter(
        gender: gender,
        muscle: muscle,
        equipment: equipment,
      ),
    );
    final rows = (res.data as List?) ?? const [];
    return rows
        .map(
          (row) => ExerciseAnimationModel.fromJson(
            (row as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  /// The raw Lottie document for one exercise.
  ///
  /// Kept as bytes rather than a decoded map because `Lottie.memory` parses the
  /// JSON itself — decoding here would parse ~100 KB twice per animation. The
  /// backend stores it gzipped and serves it under `Content-Encoding: gzip`,
  /// which the HTTP client unwraps before Dio ever sees the body.
  Future<Uint8List> composition(String id) async {
    final res = await _api.dio.get<List<int>>(
      'get-exercise-animation',
      queryParameters: {'id': id},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  List<String> _strings(dynamic data) =>
      ((data as List?) ?? const []).map((value) => value.toString()).toList();

  /// An untouched dropdown sends nothing at all. An empty string would become
  /// `{gender: ''}` on the server, which matches no row and reads as an empty
  /// catalog rather than as "no filter".
  Map<String, dynamic> _filter({
    String? gender,
    String? muscle,
    String? equipment,
  }) {
    return {
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (muscle != null && muscle.isNotEmpty) 'muscle': muscle,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
    };
  }
}
