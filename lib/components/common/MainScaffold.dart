import 'package:flutter/material.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/components/common/drawer.dart';
import 'app_bar.dart'; // Ensure this points to your CustomAppBar file

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int)? onTabChanged;
  final Map<String, dynamic>? user;
  final Function(String) onLocaleChange;

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
    this.appBarMenuKey,
    this.searchTabKey,
    this.shopTabKey,
    this.cartTabKey,
    this.profileTabKey,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ HIDE AppBar for Search (1) and Shop (2)
    // We hide it on Search (1) because DiscoverScreen has its own search bar.
    bool showAppBar = currentIndex != 1 && currentIndex != 2 && currentIndex != 3;

    return Scaffold(
      appBar: showAppBar
          ? CustomAppBar(
        menuKey: appBarMenuKey,
        // ✅ PASS THE SWITCH LOGIC HERE
        // When user clicks search in AppBar, switch to Tab 1
        onSearchTap: () {
          if (onTabChanged != null) {
            onTabChanged!(1);
          }
        },
      )
          : null,
      drawer: CustomEndDrawer(
        onLocaleChange: onLocaleChange,
        user: user,
        onTabChanged: onTabChanged!,
      ),
      body: child,
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