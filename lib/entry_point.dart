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
    return MainScaffold(
      user: user,
      onLocaleChange: widget.onLocaleChange,
      currentIndex: _currentIndex,
      onTabChanged: (index) {
        if (index != _currentIndex) {
          setState(() {
            _currentIndex = index;
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
    );
  }
}