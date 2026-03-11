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

  final GlobalKey? appBarMenuKey;
  final GlobalKey? searchTabKey;
  final GlobalKey? shopTabKey;
  final GlobalKey? cartTabKey;
  final GlobalKey? profileTabKey;

  // ✅ 1. Define the new parameters
  final bool canGoBack;
  final VoidCallback? onBack;

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
    // ✅ 2. Add them to the constructor
    this.canGoBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    bool showAppBar = currentIndex != 1 && currentIndex != 2 && currentIndex != 3;

    return Scaffold(
      appBar: showAppBar
          ? CustomAppBar(
        menuKey: appBarMenuKey,
        // ✅ 3. Pass the back logic into your CustomAppBar
        canGoBack: canGoBack,
        onBack: onBack,
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