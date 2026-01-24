import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:showcaseview/showcaseview.dart'; // ✅ Import Showcase
import 'package:shop/components/tutorial_tooltip.dart'; // ✅ Import Custom Tooltip

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
    const Color brandingColor = Color(0xFF0C1E4E);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 3,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // Leading (Menu)
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: const Color(0xFFF5F5F5),
          radius: 20,
          child: menuKey != null
          // ✅ STEP 1: Custom Tooltip
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
              icon: const Icon(Icons.menu_rounded, color: brandingColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.menu_rounded, color: brandingColor),
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
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
            backgroundColor: const Color(0xFFF5F5F5),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: brandingColor),
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