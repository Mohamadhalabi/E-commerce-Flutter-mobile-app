import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'glass_bottom_nav.dart';

/// Old name kept on purpose: every screen that still uses
/// CustomBottomNavigationBar now shows the new glass nav automatically.
///
/// For the see-through effect, give that screen's Scaffold `extendBody: true`.
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.searchTabKey,
    this.shopTabKey,
    this.cartTabKey,
    this.profileTabKey,
  });

  final int currentIndex;
  final Function(int)? onTap;
  final GlobalKey? searchTabKey;
  final GlobalKey? shopTabKey;
  final GlobalKey? cartTabKey;
  final GlobalKey? profileTabKey;

  @override
  Widget build(BuildContext context) {
    return GlassBottomNav(
      currentIndex: currentIndex,
      onTabChanged: (index) => onTap?.call(index),
      cartCount: context.select<CartProvider, int>(
            (cart) => cart.cartItems.length,
      ),
      searchTabKey: searchTabKey,
      shopTabKey: shopTabKey,
      cartTabKey: cartTabKey,
      profileTabKey: profileTabKey,
      reselectable: true,
    );
  }
}