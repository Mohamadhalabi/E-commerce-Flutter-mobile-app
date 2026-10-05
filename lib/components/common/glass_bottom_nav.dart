import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';
import 'package:shop/constants.dart';

/// Floating, frosted-glass pill navigation.
///
/// Use it as `bottomNavigationBar` of a Scaffold that has `extendBody: true`,
/// so page content scrolls underneath the blur.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    this.cartCount = 0,
    this.searchTabKey,
    this.shopTabKey,
    this.cartTabKey,
    this.profileTabKey,
    this.reselectable = false,
  });

  final int currentIndex;

  /// On pushed screens (product details, search results) tapping the
  /// highlighted tab should still navigate, e.g. back to Home.
  final bool reselectable;
  final ValueChanged<int> onTabChanged;
  final int cartCount;

  // Tutorial (showcase) keys — same ones EntryPoint already creates.
  final GlobalKey? searchTabKey;
  final GlobalKey? shopTabKey;
  final GlobalKey? cartTabKey;
  final GlobalKey? profileTabKey;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(navBarHeight / 2);

    final items = <_NavItem>[
      const _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.search_rounded,
        activeIcon: Icons.search_rounded,
        label: 'Search',
        showcaseKey: searchTabKey,
        showcaseDescription: 'Find any product by name or SKU.',
        step: 3,
      ),
      _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Shop',
        showcaseKey: shopTabKey,
        showcaseDescription: 'Browse the full catalog.',
        step: 4,
      ),
      _NavItem(
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart_rounded,
        label: 'Cart',
        showcaseKey: cartTabKey,
        showcaseDescription: 'Review your items and check out.',
        step: 5,
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        showcaseKey: profileTabKey,
        showcaseDescription: 'Manage your account, orders and settings.',
        step: 6,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        bottomInset > 0 ? bottomInset + 4 : 16,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          // Keeps the pill from stretching edge-to-edge on tablets
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: navBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? darkCardColor.withOpacity(0.72)
                        : Colors.white.withOpacity(0.74),
                    borderRadius: radius,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == currentIndex,
                            badgeCount: i == 3 ? cartCount : 0,
                            isDark: isDark,
                            onTap: () {
                              if (i == currentIndex && !reselectable) return;
                              HapticFeedback.selectionClick();
                              onTabChanged(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showcaseKey,
    this.showcaseDescription,
    this.step,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final GlobalKey? showcaseKey;
  final String? showcaseDescription;
  final int? step;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.isDark,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badgeCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
    isDark ? Colors.white.withOpacity(0.55) : blackColor60;
    final size = selected ? 50.0 : 44.0;

    Widget button = Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEF4444), primaryDarkColor],
              )
                  : null,
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey(selected),
                    size: 24,
                    color: selected ? Colors.white : inactiveColor,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: _CountBadge(
                      count: badgeCount,
                      inverted: selected,
                      ringColor: isDark ? darkCardColor : Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (item.showcaseKey != null) {
      button = Showcase.withWidget(
        key: item.showcaseKey!,
        height: 200,
        width: 280,
        container: TutorialTooltip(
          title: item.label,
          description: item.showcaseDescription ?? '',
          currentStep: item.step ?? 1,
          totalSteps: 6,
        ),
        child: button,
      );
    }
    return button;
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.inverted,
    required this.ringColor,
  });

  final int count;
  final bool inverted; // white badge when sitting on the red active circle
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : primaryColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyle(
          color: inverted ? primaryColor : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}