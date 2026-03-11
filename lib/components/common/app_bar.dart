import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey? menuKey;
  final VoidCallback? onSearchTap;

  // ✅ ADDED: Parameters to handle navigation state
  final bool canGoBack;
  final VoidCallback? onBack;

  const CustomAppBar({
    super.key,
    this.menuKey,
    this.onSearchTap,
    this.canGoBack = false, // ✅ Default to false
    this.onBack,           // ✅ Default to null
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF101015) : Colors.white;
    final Color iconColor = isDark ? Colors.white : const Color(0xFF0C1E4E);
    final Color elementBgColor = isDark ? const Color(0xFF1C1C23) : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? Colors.white70 : Colors.grey[500]!;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // ✅ UPDATED: Leading logic to switch between Back and Menu
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: elementBgColor,
          radius: 20,
          child: canGoBack
              ? IconButton(
            // iOS standard back icon
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
              : (menuKey != null
              ? Showcase.withWidget(
            key: menuKey!,
            height: 200,
            width: 280,
            container: const TutorialTooltip(
              title: "Menu",
              description: "Open the side menu to access categories...",
              currentStep: 1,
              totalSteps: 6,
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: iconColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          )
              : IconButton(
            icon: Icon(Icons.menu_rounded, color: iconColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )),
        ),
      ),
      leadingWidth: 60,

      title: GestureDetector(
        onTap: () {
          if (onSearchTap != null) {
            onSearchTap!();
          }
        },
        child: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: elementBgColor,
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

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: elementBgColor,
            radius: 20,
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: iconColor),
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