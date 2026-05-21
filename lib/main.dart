import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/providers/theme_provider.dart';
import 'package:shop/services/api_initializer.dart';
import 'package:shop/theme/app_theme.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:flutter/services.dart';
import "controllers/locale_controller.dart";
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

// Top-level function for background notifications (MUST keep the pragma)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase already initialized in background');
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Give iOS native system time to register for remote notifications
  if (Platform.isIOS) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Firebase initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase already initialized in main');
  }

  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load();
  await initApiClient();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (context, auth, cart) {
            if (cart == null) throw ArgumentError.notNull('cart');
            if (auth.isAuthenticated && !cart.isLoggedIn) {
              cart.setAuthToken(auth.token);
            }
            return cart;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
    LocaleController.updateLocale = _setLocale;

    // Initialize notification listeners after a short delay
    // to ensure the app is fully mounted before setting up notifications
    Future.delayed(const Duration(seconds: 2), () {
      PushNotificationService.setupInteractions();
    });
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('lang_code');
      if (langCode != null) {
        if (mounted) {
          setState(() {
            _locale = Locale(langCode);
          });
        }
      }
    } catch (e) {
      debugPrint('Load locale error: $e');
    } finally {
      // Always remove splash, even if something fails
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _setLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', langCode);
    if (mounted) {
      setState(() {
        _locale = Locale(langCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // CRITICAL: Connect the navigatorKey here
      navigatorKey: PushNotificationService.navigatorKey,

      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: 'Techno Lock Keys mobile app',

      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),

      themeMode: themeProvider.themeMode,
      onGenerateRoute: router.generateRoute,
      initialRoute: entryPointScreenRoute,
      builder: (context, child) {
        return ShowCaseWidget(
          builder: (context) => UpgradeAlert(
            showIgnore: false,
            showLater: false,
            barrierDismissible: false,
            upgrader: Upgrader(),
            child: child!,
          ),
          autoPlay: false,
          blurValue: 1,
        );
      },
    );
  }
}