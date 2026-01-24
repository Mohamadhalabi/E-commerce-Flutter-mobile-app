import 'package:flutter/material.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/components/common/drawer.dart';
import 'app_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int)? onTabChanged;
  final Map<String, dynamic>? user;
  final Function(String) onLocaleChange;

  // ✅ Add ALL Key Variables
  final GlobalKey? appBarMenuKey;
  final GlobalKey? searchTabKey;
  final GlobalKey? shopTabKey;
  final GlobalKey? cartTabKey;
  final GlobalKey? profileTabKey;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChanged,
    required this.user,
    required this.onLocaleChange,

    // ✅ Initialize Keys
    this.appBarMenuKey,
    this.searchTabKey,
    this.shopTabKey,
    this.cartTabKey,
    this.profileTabKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Pass key to AppBar
      appBar: currentIndex == 2
          ? null
          : CustomAppBar(menuKey: appBarMenuKey),

      drawer: CustomEndDrawer(
        onLocaleChange: onLocaleChange,
        user: user,
        onTabChanged: onTabChanged!,
      ),
      body: child,

      // ✅ Pass keys to BottomNav
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        searchTabKey: searchTabKey,
        shopTabKey: shopTabKey,
        cartTabKey: cartTabKey,
        profileTabKey: profileTabKey,
      ),
    );
  }
}