import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shop/services/api_initializer.dart';
import 'package:shop/theme/app_theme.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await initApiClient();

  runApp(const MyApp());
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
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('lang_code');
    if (langCode != null) {
      setState(() {
        _locale = Locale(langCode);
      });
    }
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
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: 'Techno Lock Keys Trading mobile app',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: entryPointScreenRoute,
    );
  }
}