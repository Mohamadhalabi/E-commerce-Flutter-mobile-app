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

// ✅ 1. ADD THIS IMPORT
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ✅ 2. ADD THIS LINE (Must be before running the app)
  // This uses the GoogleService-Info.plist you added to Xcode.
  await Firebase.initializeApp();

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
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('lang_code');
    if (langCode != null) {
      setState(() {
        _locale = Locale(langCode);
      });
    }
    FlutterNativeSplash.remove();
  }

  Future<void> _setLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', langCode);
    setState(() {
      _locale = Locale(langCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: 'Techno Lock Keys Trading mobile app',

      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),

      themeMode: themeProvider.themeMode,
      onGenerateRoute: router.generateRoute,
      initialRoute: entryPointScreenRoute,
      builder: (context, child) {
        return ShowCaseWidget(
          builder: (context) => child!,
          autoPlay: false,
          blurValue: 1,
        );
      },
    );
  }
}