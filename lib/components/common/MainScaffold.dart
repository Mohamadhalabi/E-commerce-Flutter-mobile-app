import 'package:flutter/material.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/components/common/drawer.dart';

import 'app_bar.dart'; // Checked import path

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
      // ✅ FIX: Hide AppBar on Shop Tab (Index 2) to avoid double bars
      appBar: currentIndex == 2 ? null : const CustomAppBar(),

      drawer: CustomEndDrawer(
        onLocaleChange: onLocaleChange,
        user: user,
        onTabChanged: onTabChanged!,
      ),

      body: child,

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
      ),
    );
  }
}