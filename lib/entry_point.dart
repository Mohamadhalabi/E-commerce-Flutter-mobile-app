import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/MainScaffold.dart';

class EntryPoint extends StatefulWidget {
  final Function(String) onLocaleChange;

  // ✅ 1. Add initialIndex parameter
  final int initialIndex;

  const EntryPoint({
    super.key,
    required this.onLocaleChange,
    this.initialIndex = 0, // Default to Home
  });

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  final List _pages = const [
    HomeScreen(),
    DiscoverScreen(),
    BookmarkScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  late int _currentIndex; // Changed to late so we can init in initState
  final List<int> _history = [];

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    // ✅ 2. Initialize current index from widget parameter
    _currentIndex = widget.initialIndex;

    // Initialize history with the starting index
    _history.add(_currentIndex);

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        user = jsonDecode(userString);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only allow app to close if history has 1 item or less
      canPop: _history.length <= 1,

      onPopInvoked: (didPop) {
        if (didPop) return;

        // Go back logic
        setState(() {
          _history.removeLast();
          _currentIndex = _history.last;
        });
      },

      child: MainScaffold(
        user: user,
        onLocaleChange: widget.onLocaleChange,
        currentIndex: _currentIndex,
        onTabChanged: (index) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
              _history.add(index);
            });
          }
        },
        child: PageTransitionSwitcher(
          duration: defaultDuration,
          transitionBuilder: (child, animation, secondAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondAnimation,
              child: child,
            );
          },
          child: _pages[_currentIndex],
        ),
      ),
    );
  }
}