import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shop/route/route_constants.dart';

class PushNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> setupInteractions() async {
    debugPrint('🔔 setupInteractions started');

    // ── 1. Request permission ──────────────────────────────────────────────
    final NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');

    // ── 2. Wait for APNS token ─────────────────────────────────────────────
    if (Platform.isIOS) {
      debugPrint('🍎 Waiting for APNS token...');
      String? apnsToken;
      int retries = 0;
      while (apnsToken == null && retries < 15) {
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          debugPrint('🍎 APNS attempt $retries: $apnsToken');
        } catch (e) {
          debugPrint('🍎 APNS attempt $retries error: $e');
        }
        if (apnsToken == null) {
          retries++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (apnsToken == null) {
        debugPrint('❌ APNS token NEVER received after $retries attempts');
        debugPrint('❌ Check: Push Notifications capability in Xcode?');
        debugPrint('❌ Check: Real device, not simulator?');
        debugPrint('❌ Check: App has notification permission in iOS Settings?');
      } else {
        debugPrint('✅ APNS token received: $apnsToken');
      }
    }

    // ── 3. Foreground presentation options ────────────────────────────────
    debugPrint('🔔 Setting foreground options...');
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── 4. Init local notifications ───────────────────────────────────────
    debugPrint('🔔 Initializing local notifications...');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {},
    );

    // ── 5. Get FCM token ──────────────────────────────────────────────────
    debugPrint('🔔 Getting FCM token...');
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      debugPrint('========== FCM TOKEN ==========');
      debugPrint(token ?? 'NULL - token is null!');
      debugPrint('===============================');
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
    }

    // ── 6. Foreground messages ────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // ── 7. Terminated state ───────────────────────────────────────────────
    final RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);

    // ── 8. Background → foreground ────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    debugPrint('✅ setupInteractions complete');
  }

  // ── Show a visible banner while app is open ──────────────────────────────
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(iOS: iosDetails),
    );
  }

  // ── Navigation on tap ─────────────────────────────────────────────────────
  static void _handleMessage(RemoteMessage message) {
    if (message.data.isEmpty) return;

    final String? type = message.data['type'];

    if (type == 'product') {
      final int productId =
          int.tryParse(message.data['id'].toString()) ?? 0;
      navigatorKey.currentState?.pushNamed(
        productDetailsScreenRoute,
        arguments: productId,
      );
    } else if (type == 'category') {
      navigatorKey.currentState?.pushNamed(
        'sub_category_products_screen',
        arguments: {
          'categorySlug': message.data['categorySlug'] ?? '',
          'title': message.data['title'] ?? 'Products',
        },
      );
    }
  }
}