import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/providers/theme_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!context.mounted) return;
    Provider.of<CartProvider>(context, listen: false).clearLocalCart();
    if (mounted) setState(() {});
  }

  // --------------------------------------------------------------------------
  // DELETE ACCOUNT
  // --------------------------------------------------------------------------
  void _confirmDeleteAccount(BuildContext context) {
    final tr = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr?.deleteAccount ?? "Delete Account",
          style: TextStyle(
            color: AppPalette.text(context),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to delete your account?\n\nThis action is permanent and cannot be undone. All your data and order history will be lost.",
          style: TextStyle(color: AppPalette.textMuted(context), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: AppPalette.text(context)),
            child: Text(tr?.cancel ?? "Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.deleteAccount();

              if (!context.mounted) return;
              if (success) {
                Provider.of<CartProvider>(context, listen: false).clearLocalCart();
                Navigator.pushNamedAndRemoveUntil(context, logInScreenRoute, (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account deleted.")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Couldn't delete the account. Try again.")),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: Text(
              tr?.delete ?? "Delete",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // THEME SHEET
  // --------------------------------------------------------------------------
  void _showThemeSelection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final tr = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr?.darkMode ?? "Theme",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text(context),
                  ),
                ),
                const SizedBox(height: 12),
                _themeOption(sheetContext, themeProvider, "System default", ThemeMode.system),
                _themeOption(sheetContext, themeProvider, "Light", ThemeMode.light),
                _themeOption(sheetContext, themeProvider, "Dark", ThemeMode.dark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption(
      BuildContext context, ThemeProvider provider, String title, ThemeMode mode) {
    final isSelected = provider.themeMode == mode;
    IconData icon;
    if (mode == ThemeMode.light) {
      icon = Icons.wb_sunny_rounded;
    } else if (mode == ThemeMode.dark) {
      icon = Icons.dark_mode_rounded;
    } else {
      icon = Icons.settings_brightness_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected
            ? primaryColor.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            provider.setTheme(mode);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _IconTile(icon: icon, active: isSelected),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? primaryColor : AppPalette.text(context),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    if (mode == ThemeMode.light) return "Light";
    if (mode == ThemeMode.dark) return "Dark";
    return "System";
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    final tr = AppLocalizations.of(context);
    if (tr == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    // Includes the floating nav height (MainScaffold uses extendBody)
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.fromLTRB(defaultPadding, 8, defaultPadding, bottomPad),
        children: [
          // 1. PROFILE CARD
          _ProfileHeader(
            isAuthenticated: isAuthenticated,
            name: isAuthenticated ? (user?['name'] ?? "User").toString() : "Guest",
            subtitle: isAuthenticated
                ? (user?['email'] ?? "").toString()
                : "Sign in to track orders and save addresses",
            avatarUrl: isAuthenticated ? (user?['avatar'])?.toString() : null,
            actionLabel: isAuthenticated ? null : tr.loginRegister,
            onTap: () => Navigator.pushNamed(
              context,
              isAuthenticated ? userInfoScreenRoute : logInScreenRoute,
            ),
          ),

          const SizedBox(height: 24),

          // 2. MY ACCOUNT
          if (isAuthenticated) ...[
            _SectionLabel(tr.myAccount),
            _MenuCard(children: [
              _MenuItem(
                title: tr.myOrders,
                iconSrc: "assets/icons/Order.svg",
                onTap: () => Navigator.pushNamed(context, ordersScreenRoute),
              ),
              _MenuItem(
                title: tr.myAddresses,
                iconSrc: "assets/icons/Location.svg",
                onTap: () => Navigator.pushNamed(context, addressesScreenRoute),
              ),
            ]),
            const SizedBox(height: 20),
          ],

          // 3. INFORMATION
          _SectionLabel(tr.information),
          _MenuCard(children: [
            _MenuItem(
              title: tr.aboutUs,
              icon: Icons.info_outline_rounded,
              onTap: () => Navigator.pushNamed(context, aboutUsScreenRoute),
            ),
            _MenuItem(
              title: tr.deliveryInfo,
              iconSrc: "assets/icons/Delivery.svg",
              onTap: () => Navigator.pushNamed(context, deliveryInfoScreenRoute),
            ),
            _MenuItem(
              title: tr.termsConditions,
              icon: Icons.description_outlined,
              onTap: () => Navigator.pushNamed(context, termsConditionScreenRoute),
            ),
            _MenuItem(
              title: tr.contactUs,
              icon: Icons.headset_mic_outlined,
              onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
            ),
          ]),

          const SizedBox(height: 20),

          // 4. SETTINGS
          _SectionLabel(tr.settings),
          _MenuCard(children: [
            // _MenuItem(
            //   title: tr.changeLanguage,
            //   iconSrc: "assets/icons/Language.svg",
            //   onTap: () => Navigator.pushNamed(context, selectLanguageScreenRoute),
            // ),
            _MenuItem(
              title: tr.darkMode,
              icon: Icons.dark_mode_outlined,
              value: _themeName(themeProvider.themeMode),
              onTap: () => _showThemeSelection(context),
            ),
          ]),

          const SizedBox(height: 24),

          // 5. LOGOUT / DELETE
          if (isAuthenticated) ...[
            SizedBox(
              height: 52,
              child: TextButton.icon(
                onPressed: () => _logout(context),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor:
                  primaryColor.withOpacity(AppPalette.isDark(context) ? 0.16 : 0.07),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  tr.logout,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _confirmDeleteAccount(context),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.textMuted(context),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text(
                "Delete account",
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// PIECES
// =============================================================================
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isAuthenticated,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.avatarUrl,
    this.actionLabel,
  });

  final bool isAuthenticated;
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String? actionLabel;
  final VoidCallback onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDeepColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Soft decorative circles, same language as the New Arrival band
              PositionedDirectional(
                top: -40,
                end: -30,
                child: _circle(140, 0.08),
              ),
              PositionedDirectional(
                bottom: -50,
                start: 60,
                child: _circle(110, 0.05),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.25),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                            child: isAuthenticated
                                ? Text(
                              _initials,
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                                : const Icon(Icons.person_rounded,
                                color: primaryColor, size: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAuthenticated)
                          Icon(
                            isRtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                      ],
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            actionLabel!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppPalette.textMuted(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 64,
          endIndent: 16,
          color: AppPalette.border(context),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({this.icon, this.iconSrc, this.active = false});
  final IconData? icon;
  final String? iconSrc;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppPalette.text(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? primaryColor : AppPalette.cardElevated(context),
        borderRadius: BorderRadius.circular(11),
      ),
      child: iconSrc != null
          ? SvgPicture.asset(
        iconSrc!,
        width: 19,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      )
          : Icon(icon, size: 19, color: color),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.iconSrc,
    this.value,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final String? iconSrc;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final muted = AppPalette.textMuted(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconTile(icon: icon, iconSrc: iconSrc),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.text(context),
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}