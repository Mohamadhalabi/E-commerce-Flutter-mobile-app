import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/MainScaffold.dart';

class EntryPoint extends StatefulWidget {
  final Function(String) onLocaleChange;
  final int initialIndex;

  const EntryPoint({
    super.key,
    required this.onLocaleChange,
    this.initialIndex = 0,
  });

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  // REMOVED: final List _pages = const [...]
  // We will define pages inside build() now.

  late int _currentIndex;
  final List<int> _history = [];
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _history.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Define pages here to pass dynamic data to HomeScreen
    final List<Widget> pages = [
      HomeScreen(
        currentIndex: _currentIndex,
        user: user,
        onTabChanged: _onTabChanged,
        onLocaleChange: widget.onLocaleChange,
      ),
      const DiscoverScreen(),
      const BookmarkScreen(),
      const CartScreen(isStandalone: false), // Assuming CartScreen supports this
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _history.removeLast();
          _currentIndex = _history.last;
        });
      },
      child: MainScaffold(
        user: user,
        onLocaleChange: widget.onLocaleChange,
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
        child: PageTransitionSwitcher(
          duration: defaultDuration,
          transitionBuilder: (child, animation, secondAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondAnimation,
              child: child,
            );
          },
          child: pages[_currentIndex], // Use the local list
        ),
      ),
    );
  }
}