import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'components/common/MainScaffold.dart';
// ✅ Import the product screen
import 'screens/category/sub_category_products_screen.dart';

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
    final List<Widget> pages = [
      // 0. Home
      HomeScreen(
        currentIndex: _currentIndex,
        user: user,
        onTabChanged: _onTabChanged,
        onLocaleChange: widget.onLocaleChange,
      ),

      // 1. Search / Discover
      const DiscoverScreen(),

      // ✅ 2. Shop Tab (Replaces BookmarkScreen)
      SubCategoryProductsScreen(
        categorySlug: "", // Empty string = fetch ALL products
        title: "Shop",
        currentIndex: 2,
        user: user,
        onTabChanged: _onTabChanged, // Allows tab switching from nav bar
        onLocaleChange: widget.onLocaleChange,
        isMainTab: true, // Enables Menu Icon & Drawer
      ),

      // 3. Cart
      const CartScreen(isStandalone: false),

      // 4. Profile
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
          child: pages[_currentIndex],
        ),
      ),
    );
  }
}