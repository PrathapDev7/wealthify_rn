import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../models/wishlist_item_model.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(ref.read(prefsProvider)),
);

final wishlistListProvider =
    FutureProvider.autoDispose<List<WishlistItemModel>>(
      (ref) => ref.read(wishlistRepositoryProvider).getItems(),
    );

class WishlistRepository {
  WishlistRepository(this._prefs);

  static const _key = 'wealthify_wishlist_items';
  final Prefs _prefs;

  Future<List<WishlistItemModel>> getItems() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => WishlistItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveItem(WishlistItemModel item) async {
    final items = await getItems();
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      items.insert(0, item);
    } else {
      items[index] = item;
    }
    await _save(items);
  }

  Future<void> deleteItem(String id) async {
    final items = await getItems();
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  Future<void> _save(List<WishlistItemModel> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
