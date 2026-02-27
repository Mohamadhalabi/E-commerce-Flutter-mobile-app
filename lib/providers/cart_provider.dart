import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../route/route_constants.dart';

class CartItem {
  final int id;
  final String title;
  final String sku;
  final String image;

  double price;
  final double regularPrice;
  int quantity;
  final int stock;

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
  bool _isSyncing = false;

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
      Map<int, CartItem> groupedItems = {};

      for (var itemData in serverData) {
        CartItem parsedItem = CartItem.fromJson(itemData);

        if (groupedItems.containsKey(parsedItem.id)) {
          // 🚨 BACKEND DUPLICATE DETECTED! Self-Healing Protocol:
          int combinedQty = groupedItems[parsedItem.id]!.quantity + parsedItem.quantity;
          groupedItems[parsedItem.id]!.quantity = combinedQty;

          // Silently clean up the backend: Delete all rows for this product, then insert ONE clean row
          await ApiService.removeFromCart(parsedItem.id, _authToken!);
          await ApiService.addToCart(parsedItem.id, combinedQty, _authToken!, 'en');
        } else {
          groupedItems[parsedItem.id] = parsedItem;
        }
      }

      _cartItems = groupedItems.values.toList();

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
    required String sku,
    required String image,
    required double price,
    required int quantity,
    required int stock,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    final tr = AppLocalizations.of(context)!;

    // ✅ FIX: PREVENT DUPLICATES!
    // If the item is already in the cart, just update the quantity instead of adding a new row!
    int existingIndex = _cartItems.indexWhere((item) => item.id == productId);
    if (existingIndex >= 0) {
      int newQty = _cartItems[existingIndex].quantity + quantity;
      await updateQuantity(productId, newQty);

      _isLoading = false;
      notifyListeners();

      NotificationService.show(
        context: context,
        title: tr.itemAddedTitle,
        message: "Quantity updated in your cart.",
        sku: sku,
        image: image,
        isError: false,
        onActionPressed: () {
          Navigator.pushNamed(context, cartScreenRoute);
        },
      );
      return; // Stop here so we don't duplicate
    }

    bool success = false;

    if (isLoggedIn) {
      success = await ApiService.addToCart(productId, quantity, _authToken!, 'en');
      if (success) {
        await fetchServerCart();
      }
    } else {
      await _addToLocalCart(productId, title, sku, image, price, quantity, stock);
      success = true;
    }

    _isLoading = false;
    notifyListeners();

    if (success) {
      NotificationService.show(
        context: context,
        title: tr.itemAddedTitle,
        message: "has been added to your cart.",
        sku: sku,
        image: image,
        isError: false,
        onActionPressed: () {
          Navigator.pushNamed(context, cartScreenRoute);
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.addedToCartFail), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity < 1) return;

    int index = _cartItems.indexWhere((item) => item.id == productId);
    if (index == -1) return;

    int oldQuantity = _cartItems[index].quantity; // Save in case of failure

    if (isLoggedIn) {
      // Optimistic update (feels instantly fast to the user)
      _cartItems[index].quantity = quantity;
      notifyListeners();

      // ✅ FIX: Send productId as expected by Laravel
      double? newUnitPrice = await ApiService.updateCartQuantity(productId, quantity, _authToken!);

      if (newUnitPrice != null) { // Success!
        if (newUnitPrice > 0) {
          // Update price if the server returned a new bulk discount price
          _cartItems[index].price = newUnitPrice;
        }
        notifyListeners();
      } else {
        // API Failed (Returned null). Revert back to the old quantity so the user isn't tricked.
        _cartItems[index].quantity = oldQuantity;
        notifyListeners();
      }
    } else {
      _cartItems[index].quantity = quantity;
      await _saveCartToPrefs();
      notifyListeners();
    }
  }

  Future<void> removeItem(int productId, BuildContext context) async {
    int index = _cartItems.indexWhere((item) => item.id == productId);
    CartItem? removedItem;
    if (index != -1) {
      removedItem = _cartItems[index];
    }

    final tr = AppLocalizations.of(context)!;

    if (isLoggedIn) {
      // ✅ FIX: Send productId
      bool success = await ApiService.removeFromCart(productId, _authToken!);
      if (success) {
        _cartItems.removeWhere((item) => item.id == productId);
        notifyListeners();

        if (removedItem != null) {
          NotificationService.show(
            context: context,
            title: tr.itemRemovedTitle,
            message: "${removedItem.title} removed from cart.",
            sku: removedItem.sku,
            image: removedItem.image,
            isError: true,
          );
        }
      }
    } else {
      _cartItems.removeWhere((item) => item.id == productId);
      await _saveCartToPrefs();
      notifyListeners();

      if (removedItem != null) {
        NotificationService.show(
          context: context,
          title: tr.itemRemovedTitle,
          message: "${removedItem.title} removed from cart.",
          sku: removedItem.sku,
          image: removedItem.image,
          isError: true,
        );
      }
    }
  }

  Future<void> mergeLocalCartToAccount(String token) async {
    if (_cartItems.isEmpty || _isSyncing) return;

    _isSyncing = true;

    List<Map<String, dynamic>> apiFormat = _cartItems.map((e) {
      return {'product_id': e.id, 'quantity': e.quantity};
    }).toList();

    bool success = await ApiService.syncGuestCart(apiFormat, token);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_cart');
      _cartItems.clear();
    }

    _isSyncing = false;
  }

  Future<void> _addToLocalCart(int id, String title, String sku, String image, double price, int qty, int stock) async {
    int index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index].quantity += qty;
    } else {
      _cartItems.add(CartItem(
        id: id,
        title: title,
        sku: sku,
        image: image,
        price: price,
        regularPrice: price,
        quantity: qty,
        stock: stock,
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

  void clearLocalCart() {
    _cartItems = [];
    _authToken = null;
    notifyListeners();
  }
}