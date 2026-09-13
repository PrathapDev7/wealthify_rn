import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/network/api_client.dart';
import '../models/wishlist_item_model.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(ref.read(apiClientProvider)),
);

final wishlistListProvider =
    FutureProvider.autoDispose<List<WishlistItemModel>>(
      (ref) => ref.read(wishlistRepositoryProvider).getItems(),
    );

class WishlistRepository {
  WishlistRepository(this._api);

  final ApiClient _api;

  Future<List<WishlistItemModel>> getItems() async {
    final res = await _api.dio.get('get-wishlist-items');
    final data = res.data;
    final list = (data['data'] as List<dynamic>?) ?? const [];
    return list
        .map((item) => WishlistItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveItem(WishlistItemModel item) async {
    final body = {
      'title': item.title,
      'estimatedAmount': item.estimatedAmount,
      'priority': item.priority,
      'category': item.category,
      'targetDate': item.targetDate?.toIso8601String(),
      'notes': item.notes,
      'isPurchased': item.isPurchased,
    };

    final isNew = !RegExp(r'^[0-9a-f]{24}$').hasMatch(item.id);
    if (isNew) {
      await _api.dio.post('add-wishlist-item', data: body);
      return;
    }

    await _api.dio.put('update-wishlist-item/${item.id}', data: body);
  }

  Future<void> deleteItem(String id) async {
    await _api.dio.delete('delete-wishlist-item/$id');
  }
}
