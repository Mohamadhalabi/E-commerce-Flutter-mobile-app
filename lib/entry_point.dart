import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:showcaseview/showcaseview.dart';
import 'components/common/MainScaffold.dart';
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
  final List<int> _history = []; // Tracks tab navigation for hardware back button
  Map<String, dynamic>? user;

  final GlobalKey _appBarMenuKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _searchTabKey = GlobalKey();
  final GlobalKey _shopTabKey = GlobalKey();
  final GlobalKey _cartTabKey = GlobalKey();
  final GlobalKey _profileTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _history.add(_currentIndex);
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstTime());
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('first_time_tutorial');
    if (isFirstTime == null || isFirstTime == true) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([
          _appBarMenuKey, _categoriesKey, _searchTabKey, _shopTabKey, _cartTabKey, _profileTabKey
        ]);
      }
      await prefs.setBool('first_time_tutorial', false);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() => user = jsonDecode(userString));
    }
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;

        // Keep track of history for the physical phone back button
        _history.remove(index);
        _history.add(index);
      });
    }
  }

  // ✅ Function to handle going back (via phone swipe/button)
  void _handleBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _currentIndex = _history.last;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        currentIndex: _currentIndex,
        user: user,
        onTabChanged: _onTabChanged,
        onLocaleChange: widget.onLocaleChange,
        categoryKey: _categoriesKey,
      ),
      const DiscoverScreen(),
      SubCategoryProductsScreen(
        categorySlug: "",
        title: "Shop",
        currentIndex: 2,
        user: user,
        onTabChanged: _onTabChanged,
        onLocaleChange: widget.onLocaleChange,
        isMainTab: true,
      ),
      const CartScreen(isStandalone: false),
      const ProfileScreen(),
    ];

    return PopScope(
      // ✅ Intercepts iPhone/Android Swipe-to-back
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: MainScaffold(
        user: user,
        onLocaleChange: widget.onLocaleChange,
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,

        // ✅ THE FIX: Hardcode this to false!
        // Because these 5 pages are root-level bottom navigation tabs,
        // the visual AppBar should ALWAYS show the Drawer menu, not a back arrow.
        canGoBack: false,
        onBack: _handleBack,

        appBarMenuKey: _appBarMenuKey,
        searchTabKey: _searchTabKey,
        shopTabKey: _shopTabKey,
        cartTabKey: _cartTabKey,
        profileTabKey: _profileTabKey,
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