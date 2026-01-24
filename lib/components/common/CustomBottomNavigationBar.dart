import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  final GlobalKey? searchTabKey;
  final GlobalKey? shopTabKey;
  final GlobalKey? cartTabKey;
  final GlobalKey? profileTabKey;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.searchTabKey,
    this.shopTabKey,
    this.cartTabKey,
    this.profileTabKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ✅ FIX 1: Change Active Color based on Theme
    // Navy is invisible in Dark Mode, so we use White.
    final Color activeColor = isDarkMode ? Colors.white : const Color(0xFF0C1E4E);

    // ✅ FIX 2: Background Color
    // Use a slightly lighter dark grey (Surface color) for the bar in Dark Mode
    final Color barBackgroundColor = isDarkMode ? const Color(0xFF1C1C23) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: barBackgroundColor,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: barBackgroundColor,

          // ✅ Applied the Dynamic Active Color
          selectedItemColor: activeColor,

          // Good visibility for unselected items in both modes
          unselectedItemColor: isDarkMode ? Colors.white38 : Colors.grey.shade400,

          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            // 0. Home (No Tutorial)
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: AppLocalizations.of(context)!.home,
            ),

            // 1. Search (STEP 3)
            BottomNavigationBarItem(
              icon: searchTabKey != null
                  ? Showcase.withWidget(
                key: searchTabKey!,
                height: 200,
                width: 280,
                container: const TutorialTooltip(
                  title: "Search",
                  description: "Find products quickly by typing here.",
                  currentStep: 3,
                  totalSteps: 6,
                ),
                child: const Icon(Icons.search_rounded),
              )
                  : const Icon(Icons.search_rounded),
              activeIcon: const Icon(Icons.search_rounded, weight: 800),
              label: AppLocalizations.of(context)!.search,
            ),

            // 2. Shop (STEP 4)
            BottomNavigationBarItem(
              icon: shopTabKey != null
                  ? Showcase.withWidget(
                key: shopTabKey!,
                height: 200,
                width: 280,
                container: const TutorialTooltip(
                  title: "Shop",
                  description: "View our full catalog of products and top brands.",
                  currentStep: 4,
                  totalSteps: 6,
                ),
                child: const Icon(Icons.grid_view_outlined),
              )
                  : const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view_rounded),
              label: AppLocalizations.of(context)!.shop,
            ),

            // 3. Cart (STEP 5)
            BottomNavigationBarItem(
              icon: cartTabKey != null
                  ? Showcase.withWidget(
                key: cartTabKey!,
                height: 200,
                width: 280,
                container: const TutorialTooltip(
                  title: "Cart",
                  description: "View your selected items and checkout.",
                  currentStep: 5,
                  totalSteps: 6,
                ),
                child: const Icon(Icons.shopping_cart_outlined),
              )
                  : const Icon(Icons.shopping_cart_outlined),
              activeIcon: const Icon(Icons.shopping_cart_rounded),
              label: AppLocalizations.of(context)!.cart,
            ),

            // 4. Profile (STEP 6)
            BottomNavigationBarItem(
              icon: profileTabKey != null
                  ? Showcase.withWidget(
                key: profileTabKey!,
                height: 200,
                width: 280,
                container: const TutorialTooltip(
                  title: "Profile",
                  description: "Manage your account, orders, and addresses.",
                  currentStep: 6,
                  totalSteps: 6,
                ),
                child: const Icon(Icons.person_outline_rounded),
              )
                  : const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );
  }
}