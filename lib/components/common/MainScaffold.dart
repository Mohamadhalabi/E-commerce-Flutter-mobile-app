// lib/components/common/main_scaffold.dart
import 'package:flutter/material.dart';
import 'CustomBottomNavigationBar.dart';
import 'app_bar.dart';
import 'drawer.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int)? onTabChanged;
  final Map<String, dynamic>? user;
  final Function(String) onLocaleChange;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChanged,
    required this.user,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: CustomEndDrawer(
        onLocaleChange: onLocaleChange,
        user: user,
      ),
      body: child,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
      ),
    );
  }
}