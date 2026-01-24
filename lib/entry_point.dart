import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:showcaseview/showcaseview.dart'; // ✅ Import
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
  final List<int> _history = [];
  Map<String, dynamic>? user;

  // ✅ 1. Define ALL Keys for the Tutorial Steps
  final GlobalKey _appBarMenuKey = GlobalKey(); // Menu in AppBar
  final GlobalKey _categoriesKey = GlobalKey(); // Home Categories
  final GlobalKey _searchTabKey = GlobalKey();  // Search in BottomNav
  final GlobalKey _shopTabKey = GlobalKey();    // Shop in BottomNav
  final GlobalKey _cartTabKey = GlobalKey();    // Cart in BottomNav
  final GlobalKey _profileTabKey = GlobalKey(); // Profile in BottomNav

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _history.add(_currentIndex);
    _loadUserData();

    // ✅ 2. Trigger Tutorial Check
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstTime());
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ---------------------------------------------------------
    // 👇 DEVELOPMENT MODE (Use this while you are building/testing)
    // await prefs.setBool('first_time_tutorial', true);
    // ---------------------------------------------------------

    bool? isFirstTime = prefs.getBool('first_time_tutorial');

    if (isFirstTime == null || isFirstTime == true) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // ✅ 3. Start the FULL Sequence
        ShowCaseWidget.of(context).startShowCase([
          _appBarMenuKey,  // 1. Menu
          _categoriesKey,  // 2. Categories
          _searchTabKey,   // 3. Search
          _shopTabKey,     // 4. Shop
          _cartTabKey,     // 5. Cart
          _profileTabKey   // 6. Profile
        ]);
      }
      await prefs.setBool('first_time_tutorial', false);
    }
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
      HomeScreen(
        currentIndex: _currentIndex,
        user: user,
        onTabChanged: _onTabChanged,
        onLocaleChange: widget.onLocaleChange,
        categoryKey: _categoriesKey, // Pass Key
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

        // ✅ Pass ALL Keys down to MainScaffold
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