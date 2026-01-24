import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Default to System so it matches device settings automatically
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // 1. Check if the current ACTIVE theme is dark (helper for UI logic)
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      // If system, ask the device what the brightness is
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // 2. Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString('theme_mode');

    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // 3. Set and Save Theme
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String themeString;

    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }
    await prefs.setString('theme_mode', themeString);
  }
}