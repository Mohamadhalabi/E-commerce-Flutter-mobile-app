import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey? menuKey;

  const CustomAppBar({
    super.key,
    this.menuKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    // 1. Detect Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Define Dynamic Colors
    // Background: White vs Dark Background
    final Color backgroundColor = isDark ? const Color(0xFF101015) : Colors.white;
    // Icon Color: Navy vs White
    final Color iconColor = isDark ? Colors.white : const Color(0xFF0C1E4E);
    // Button/Search Backgrounds: Light Grey vs Dark Surface
    final Color elementBgColor = isDark ? const Color(0xFF1C1C23) : const Color(0xFFF5F5F5);
    // Text Color: Grey vs White70
    final Color textColor = isDark ? Colors.white70 : Colors.grey[500]!;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0, // Removed elevation for cleaner look in dark mode
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // Leading (Menu)
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: elementBgColor, // Dynamic BG
          radius: 20,
          child: menuKey != null
              ? Showcase.withWidget(
            key: menuKey!,
            height: 200,
            width: 280,
            container: const TutorialTooltip(
              title: "Menu",
              description: "Open the side menu to access categories, language settings, and currency.",
              currentStep: 1,
              totalSteps: 6,
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: iconColor), // Dynamic Icon Color
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          )
              : IconButton(
            icon: Icon(Icons.menu_rounded, color: iconColor), // Dynamic Icon Color
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      leadingWidth: 60,

      // Search Bar
      title: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, discoverScreenRoute);
        },
        child: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: elementBgColor, // Dynamic Search BG
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: textColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search...',
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),

      // Notification Button
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: elementBgColor, // Dynamic BG
            radius: 20,
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: iconColor), // Dynamic Icon
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }
}