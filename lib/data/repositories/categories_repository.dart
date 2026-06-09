import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final ApiClient _api;

  Future<List<CategoryModel>> getCategories(String type) async {
    final res = await _api.dio.get('get-categories', queryParameters: {'type': type});
    final data = res.data;
    final raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((e) => CategoryModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<String>> getRecentCategories(String type) async {
    final res =
        await _api.dio.get('get-recent-categories', queryParameters: {'type': type});
    final data = res.data;
    final raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((e) => (e['title'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> addCategory(Map<String, dynamic> data) =>
      _api.dio.post('add-category', data: data);
  Future<void> updateCategory(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-category/$id', data: data);
  Future<void> deleteCategory(String id) => _api.dio.delete('delete-category/$id');

  Future<List<String>> getSubCategories(String category) async {
    final res = await _api.dio
        .get('get-sub-categories', queryParameters: {'category': category});
    final data = res.data;
    final raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((e) => (e['title'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> addSubCategory(Map<String, dynamic> data) =>
      _api.dio.post('add-sub-category', data: data);

  /// Uploads an image file to S3 via the backend, returns the public URL.
  Future<String> uploadIcon(String filePath) async {
    final form = FormData.fromMap({
      'folder': 'category-icons',
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.upload('upload-image', form);
    return (res.data['data']?['url'] ?? '').toString();
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.read(apiClientProvider)),
);
