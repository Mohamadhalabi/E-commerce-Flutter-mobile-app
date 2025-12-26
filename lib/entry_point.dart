import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/MainScaffold.dart';

class EntryPoint extends StatefulWidget {
  final Function(String) onLocaleChange;

  const EntryPoint({super.key, required this.onLocaleChange});

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

  int _currentIndex = 0;

  final List<int> _history = [0];

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
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
      // 2. LOGIC CHANGE:
      // Only allow the app to close if we have 1 item left in history (which is the starting Home).
      canPop: _history.length <= 1,

      onPopInvoked: (didPop) {
        if (didPop) return;

        // 3. GO BACK STEP:
        // Remove the current tab from history and go back to the previous one.
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
          // 4. NAVIGATION LOGIC:
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
              // Add the new tab to our history list so we can go back to it later
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