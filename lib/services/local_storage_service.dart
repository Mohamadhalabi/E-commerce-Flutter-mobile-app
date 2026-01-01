import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class LocalStorageService {
  static const String _historyKey = 'search_history';
  static const String _recentsKey = 'recently_viewed';

  // --- SEARCH HISTORY (Keep as is) ---
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  static Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    history.remove(query.trim()); // Remove duplicates
    history.insert(0, query.trim()); // Add to top
    if (history.length > 10) history.removeLast(); // Keep max 10

    await prefs.setStringList(_historyKey, history);
  }

  static Future<void> removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.remove(query);
    await prefs.setStringList(_historyKey, history);
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // --- RECENTLY VIEWED ---

  // 1. Get List
  static Future<List<ProductModel>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = prefs.getStringList(_recentsKey) ?? [];

    // Convert saved JSON strings back to ProductModel using your factory
    return jsonList.map((str) {
      return ProductModel.fromJson(jsonDecode(str));
    }).toList();
  }

  // 2. Add Item
  static Future<void> addToRecentlyViewed(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = prefs.getStringList(_recentsKey) ?? [];

    // We manually create a Map because your model doesn't have .toJson()
    // We only save fields needed for the Product Card to save space.
    Map<String, dynamic> simpleProduct = {
      'id': product.id,
      'title': product.title,
      'image': product.image,
      'price': product.price,
      'sale_price': product.salePrice, // Important: Save sale price
      'sku': product.sku,
      'rating': product.rating,
      'is_free_shipping': product.freeShipping, // Note: mapped to match your fromJson logic
      'discount': product.discount,
      'brand_name': product.brandName,
      'category': product.category,
      'faq': [], // We don't need FAQ for the recent list, save space
    };

    String jsonStr = jsonEncode(simpleProduct);

    // Remove if already exists (check by ID to avoid duplicates)
    jsonList.removeWhere((item) {
      try {
        return jsonDecode(item)['id'] == product.id;
      } catch (e) {
        return false;
      }
    });

    // Add to top
    jsonList.insert(0, jsonStr);

    // Limit to 10 recent items
    if (jsonList.length > 10) jsonList.removeLast();

    await prefs.setStringList(_recentsKey, jsonList);
  }
}