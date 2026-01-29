import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class LocalStorageService {
  static const String _historyKey = 'search_history';
  static const String _recentsKey = 'recently_viewed';

  // --- SEARCH HISTORY ---
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

  static Future<List<ProductModel>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = prefs.getStringList(_recentsKey) ?? [];

    return jsonList.map((str) {
      return ProductModel.fromJson(jsonDecode(str));
    }).toList();
  }

  static Future<void> addToRecentlyViewed(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = prefs.getStringList(_recentsKey) ?? [];

    // [UPDATE] Mapped to match ProductModel.fromJson expectations
    Map<String, dynamic> simpleProduct = {
      'id': product.id,
      'title': product.title,
      'image': product.image,

      // Pricing Fields
      'price': product.effectivePrice,   // Mapped to effectivePrice in fromJson
      'regular_price': product.regularPrice,
      'sale_price': product.salePrice,

      // Stock
      'quantity': product.stock,

      'sku': product.sku,
      'rating': product.rating,
      'is_free_shipping': product.freeShipping,
      'discount': product.discount,
      'brand_name': "", // Add if available in model or leave empty
      'category': product.category,

      // Complex objects set to defaults to avoid storage bloat/errors
      'table_price': [],
      'faq': [],
    };

    String jsonStr = jsonEncode(simpleProduct);

    // Remove if already exists (check by ID)
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