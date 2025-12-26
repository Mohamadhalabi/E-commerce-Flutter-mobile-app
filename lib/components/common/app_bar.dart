import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    const Color brandingColor = Color(0xFF0C1E4E);

    return AppBar(
      // ✅ 1. White Background for the Bar itself
      backgroundColor: Colors.white,

      // ✅ 2. Add Shadow (Clean, no tint)
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.7), // Soft shadow color
      surfaceTintColor: Colors.transparent, // Removes the "ugly" scroll color change
      scrolledUnderElevation: 3, // Keeps shadow when scrolling

      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // Menu Button
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: const Color(0xFFF5F5F5), // Light Grey background
          radius: 20,
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, color: brandingColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      leadingWidth: 60,

      // Search Bar
      title: Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // ✅ 3. Light Grey Background for Search (Contrast against White App Bar)
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Search...',
                  // Clean grey text
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.camera_alt_outlined, color: Colors.grey[600], size: 22),
              ),
            ),
          ],
        ),
      ),

      // Notification Button
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF5F5F5), // Light Grey background
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: brandingColor),
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