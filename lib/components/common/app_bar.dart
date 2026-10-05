import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shop/components/tutorial_tooltip.dart';
import 'package:shop/constants.dart';

/// Compact header: [menu]  ( search pill )  [bell]
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey? menuKey;
  final VoidCallback? onSearchTap;
  final bool canGoBack;
  final VoidCallback? onBack;

  // Kept so MainScaffold keeps compiling; not shown in this layout.
  final Map<String, dynamic>? user;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.menuKey,
    this.onSearchTap,
    this.canGoBack = false,
    this.onBack,
    this.user,
    this.notificationCount = 0,
    this.onNotificationTap,
  });

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    Widget leading = canGoBack
        ? _CircleButton(
      icon: Icons.arrow_back_ios_new_rounded,
      iconSize: 18,
      semanticLabel: 'Back',
      onTap: onBack,
    )
        : Builder(
      builder: (ctx) => _CircleButton(
        icon: Icons.menu_rounded,
        semanticLabel: 'Menu',
        onTap: () => Scaffold.of(ctx).openDrawer(),
      ),
    );

    if (!canGoBack && menuKey != null) {
      leading = Showcase.withWidget(
        key: menuKey!,
        height: 200,
        width: 280,
        container: const TutorialTooltip(
          title: "Menu",
          description: "Open the side menu to access categories...",
          currentStep: 1,
          totalSteps: 6,
        ),
        child: leading,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(child: _SearchPill(onTap: onSearchTap)),
                  const SizedBox(width: 10),
                  _CircleButton(
                    icon: Icons.notifications_none_rounded,
                    semanticLabel: 'Notifications',
                    showDot: notificationCount > 0,
                    onTap: onNotificationTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.iconSize = 22,
    this.showDot = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double iconSize;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final bg = AppPalette.cardElevated(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: bg,
        shape: CircleBorder(
          side: BorderSide(color: AppPalette.border(context)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: iconSize, color: AppPalette.text(context)),
                if (showDot)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    final shape = StadiumBorder(
      side: BorderSide(color: AppPalette.border(context)),
    );

    return Semantics(
      button: true,
      label: 'Search products',
      child: Material(
        color: AppPalette.cardElevated(context),
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: muted, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search products or SKU',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}