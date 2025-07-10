import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/constants.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  SvgPicture svgIcon(String src, {Color? color}) {
    return SvgPicture.asset(
      src,
      height: 24,
      colorFilter: ColorFilter.mode(
        color ?? Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      selectedItemColor: primaryColor,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF101015),
      items: [
        BottomNavigationBarItem(
          icon: svgIcon("assets/icons/Shop.svg"),
          activeIcon: svgIcon("assets/icons/Shop.svg", color: primaryColor),
          label: "Shop",
        ),
        BottomNavigationBarItem(
          icon: svgIcon("assets/icons/Category.svg"),
          activeIcon: svgIcon("assets/icons/Category.svg", color: primaryColor),
          label: "Discover",
        ),
        BottomNavigationBarItem(
          icon: svgIcon("assets/icons/Bookmark.svg"),
          activeIcon: svgIcon("assets/icons/Bookmark.svg", color: primaryColor),
          label: "Bookmark",
        ),
        BottomNavigationBarItem(
          icon: svgIcon("assets/icons/Bag.svg"),
          activeIcon: svgIcon("assets/icons/Bag.svg", color: primaryColor),
          label: "Cart",
        ),
        BottomNavigationBarItem(
          icon: svgIcon("assets/icons/Profile.svg"),
          activeIcon: svgIcon("assets/icons/Profile.svg", color: primaryColor),
          label: "Profile",
        ),
      ],
    );
  }
}