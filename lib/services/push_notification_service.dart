import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart'; // Make sure this is imported

class PushNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> setupInteractions() async {
    // 1. Request permission
    await FirebaseMessaging.instance.requestPermission();

    // ✅ ADD THESE LINES TO GET AND PRINT YOUR TOKEN
    String? token = await FirebaseMessaging.instance.getToken();
    print("========== FCM TOKEN ==========");
    print(token);
    print("===============================");

    // 2. Handle app opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);

    // 3. Handle app opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    if (message.data.isEmpty) return;

    final String? type = message.data['type']; // 'product' or 'category'

    if (type == 'product') {
      // Your router expects an int for productDetailsScreenRoute
      final int productId = int.tryParse(message.data['id'].toString()) ?? 0;
      navigatorKey.currentState?.pushNamed(
        productDetailsScreenRoute,
        arguments: productId,
      );
    }
    else if (type == 'category') {
      // Your router expects a Map for sub_category_products_screen
      navigatorKey.currentState?.pushNamed(
        "sub_category_products_screen",
        arguments: {
          'categorySlug': message.data['categorySlug'] ?? '',
          'title': message.data['title'] ?? 'Products',
        },
      );
    }
  }
}