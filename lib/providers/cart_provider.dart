import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CartItem {
  final int id;
  final String title;
  final String sku; // ✅ Added
  final String image;

  double price; // Effective Price
  final double regularPrice; // ✅ Added

  int quantity;
  final int stock; // ✅ Added

  CartItem({
    required this.id,
    required this.title,
    required this.sku,
    required this.image,
    required this.price,
    required this.regularPrice,
    required this.quantity,
    required this.stock,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sku': sku,
      'image': image,
      'price': price,
      'regular_price': regularPrice,
      'quantity': quantity,
      'stock': stock,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      title: json['title'] ?? 'Unknown',
      sku: json['sku'] ?? '',
      image: json['image']?.toString() ?? '',
      // Ensure we parse numbers safely
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      regularPrice: (json['regular_price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      stock: json['stock'] ?? 0,
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  String? _authToken;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;

  void setAuthToken(String? token) {
    _authToken = token;
    notifyListeners();
    if (isLoggedIn) {
      _handleLoginSync();
    }
  }

  Future<void> _handleLoginSync() async {
    await loadCart();
    if (_cartItems.isNotEmpty) {
      await mergeLocalCartToAccount(_authToken!);
    }
    await fetchServerCart();
  }

  double get totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // ==========================================================
  // SERVER ACTIONS
  // ==========================================================

  Future<void> fetchServerCart() async {
    if (!isLoggedIn) return;
    _isLoading = true;
    notifyListeners();

    try {
      List<dynamic> serverData = await ApiService.fetchCart(_authToken!, 'en');
      _cartItems = serverData.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      print("Error fetching server cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required int productId,
    required String title,
    required String image,
    required double price,
    required int quantity,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    bool success = false;

    if (isLoggedIn) {
      // 1. SERVER FLOW
      success = await ApiService.addToCart(productId, quantity, _authToken!, 'en');
      if (success) {
        await fetchServerCart();
      }
    } else {
      // 2. GUEST FLOW (Local)
      await _addToLocalCart(productId, title, image, price, quantity);
      success = true;
    }

    _isLoading = false;
    notifyListeners();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title added to cart"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add to cart"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity < 1) return;

    int index = _cartItems.indexWhere((item) => item.id == productId);
    if (index == -1) return;

    if (isLoggedIn) {
      // Optimistic Update
      _cartItems[index].quantity = quantity;
      notifyListeners();

      // Call API
      double? newUnitPrice = await ApiService.updateCartQuantity(productId, quantity, _authToken!);

      if (newUnitPrice != null && newUnitPrice >= 0) {
        // Update Price from Server (Table Pricing)
        _cartItems[index].price = newUnitPrice;
        notifyListeners();
      } else {
        // Failed, revert
        await fetchServerCart();
      }
    } else {
      // Guest Logic
      _cartItems[index].quantity = quantity;
      await _saveCartToPrefs();
      notifyListeners();
    }
  }

  Future<void> removeItem(int productId) async {
    if (isLoggedIn) {
      bool success = await ApiService.removeFromCart(productId, _authToken!);
      if (success) {
        _cartItems.removeWhere((item) => item.id == productId);
        notifyListeners();
      }
    } else {
      _cartItems.removeWhere((item) => item.id == productId);
      await _saveCartToPrefs();
      notifyListeners();
    }
  }

  Future<void> mergeLocalCartToAccount(String token) async {
    if (_cartItems.isEmpty) return;

    List<Map<String, dynamic>> apiFormat = _cartItems.map((e) {
      return {'product_id': e.id, 'quantity': e.quantity};
    }).toList();

    bool success = await ApiService.syncGuestCart(apiFormat, token);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_cart');
      _cartItems.clear();
    }
  }

  // ==========================================================
  // LOCAL STORAGE HELPERS
  // ==========================================================
  Future<void> _addToLocalCart(int id, String title, String image, double price, int qty) async {
    int index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index].quantity += qty;
    } else {
      // For local add, we might not have SKU/Stock/RegularPrice yet.
      // Use defaults until user logs in or we fetch full details.
      _cartItems.add(CartItem(
        id: id,
        title: title,
        sku: '', // Placeholder
        image: image,
        price: price,
        regularPrice: price, // Placeholder
        quantity: qty,
        stock: 9999, // Assume in stock locally until verified
      ));
    }
    await _saveCartToPrefs();
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    String? cartString = prefs.getString('guest_cart');
    if (cartString != null) {
      List<dynamic> decoded = jsonDecode(cartString);
      _cartItems = decoded.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_cartItems.map((e) => e.toJson()).toList());
    await prefs.setString('guest_cart', encoded);
  }
}