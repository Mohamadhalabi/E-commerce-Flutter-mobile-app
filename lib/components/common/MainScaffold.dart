import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/components/common/drawer.dart';
import 'package:shop/components/common/glass_bottom_nav.dart';
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
    this.canGoBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final showAppBar =
        currentIndex != 1 && currentIndex != 2 && currentIndex != 3;

    return Scaffold(
      // Lets page content scroll underneath the frosted nav
      extendBody: true,
      appBar: showAppBar
          ? CustomAppBar(
        menuKey: appBarMenuKey,
        user: user,
        canGoBack: canGoBack,
        onBack: onBack,
        onSearchTap: () => onTabChanged?.call(1),
      )
          : null,
      drawer: CustomEndDrawer(
        onLocaleChange: onLocaleChange,
        user: user,
        onTabChanged: onTabChanged!,
      ),
      body: child,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: currentIndex,
        onTabChanged: (index) => onTabChanged?.call(index),
        // Number of different products in the cart
        cartCount: context.select<CartProvider, int>(
              (cart) => cart.cartItems.length,
        ),
        searchTabKey: searchTabKey,
        shopTabKey: shopTabKey,
        cartTabKey: cartTabKey,
        profileTabKey: profileTabKey,
      ),
    );
  }
}