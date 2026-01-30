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
  // ✅ Color Preserved (Navy)
  final Color brandingColor = const Color(0xFF0C1E4E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    });
  }

  void _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (context.mounted) {
      Provider.of<CartProvider>(context, listen: false).clearLocalCart();
    }
    setState(() {});
  }

  // --------------------------------------------------------------------------
  // ✅ NEW: Delete Account Logic & Alert
  // --------------------------------------------------------------------------
  void _confirmDeleteAccount(BuildContext context) {
    final tr = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr?.deleteAccount ?? "Delete Account"),
        // Warning user it is permanent (even though backend is soft delete)
        content: const Text(
            "Are you sure you want to delete your account?\n\nThis action is permanent and cannot be undone. All your data and order history will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr?.cancel ?? "Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog

              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              // Call provider delete method
              bool success = await authProvider.deleteAccount();

              if (success && context.mounted) {
                // Clear cart and go to login
                Provider.of<CartProvider>(context, listen: false).clearLocalCart();

                // Navigate to Login and remove all previous routes
                Navigator.pushNamedAndRemoveUntil(context, logInScreenRoute, (route) => false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account deleted successfully.")),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete account. Please try again.")),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr?.delete ?? "Delete"),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Theme Selection Logic (Bottom Sheet)
  // --------------------------------------------------------------------------
  void _showThemeSelection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final tr = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                tr?.darkMode ?? "Select Theme",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Options
              _buildThemeOption(context, themeProvider, "System Default", ThemeMode.system),
              _buildThemeOption(context, themeProvider, "Light Mode", ThemeMode.light),
              _buildThemeOption(context, themeProvider, "Dark Mode", ThemeMode.dark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
      BuildContext context, ThemeProvider provider, String title, ThemeMode mode) {
    final isSelected = provider.themeMode == mode;
    final color = isSelected ? brandingColor : Colors.grey;

    IconData icon;
    if (mode == ThemeMode.light) icon = Icons.wb_sunny_rounded;
    else if (mode == ThemeMode.dark) icon = Icons.dark_mode_rounded;
    else icon = Icons.settings_brightness_rounded;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? brandingColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: brandingColor) : null,
      onTap: () {
        provider.setTheme(mode);
        Navigator.pop(context);
      },
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return "Light";
      case ThemeMode.dark: return "Dark";
      case ThemeMode.system: return "System";
    }
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    // Check actual brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tr = AppLocalizations.of(context);
    // If localization is not ready, show loader
    if (tr == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Define Dynamic Colors
    final Color scaffoldBg = isDark ? const Color(0xFF101015) : const Color(0xFFF4F5F7);
    final Color cardBg = isDark ? const Color(0xFF1C1C23) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color iconCircleBg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color iconColor = isDark ? Colors.white : brandingColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ------------------------------------------
          // 1. HEADER SECTION
          // ------------------------------------------
          InkWell(
            onTap: () {
              if (isAuthenticated) {
                Navigator.pushNamed(context, userInfoScreenRoute);
              } else {
                Navigator.pushNamed(context, logInScreenRoute);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          isAuthenticated
                              ? (user?['avatar'] ?? "https://i.imgur.com/IXnwbLk.png")
                              : "https://cdn-icons-png.flaticon.com/512/847/847969.png",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated ? (user?['name'] ?? "User") : "Guest User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAuthenticated
                              ? (user?['email'] ?? "")
                              : "Welcome to our shop",
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthenticated)
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ------------------------------------------
          // 2. MY ACCOUNT
          // ------------------------------------------
          if (isAuthenticated) ...[
            _buildSectionHeader(context, tr.myAccount, isDark),
            _buildMenuCard(cardBg, [
              _buildMenuItem(
                context,
                title: tr.myOrders,
                iconSrc: "assets/icons/Order.svg",
                onTap: () => Navigator.pushNamed(context, ordersScreenRoute),
                circleBg: iconCircleBg,
                iconColor: iconColor,
                textColor: textColor,
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                title: tr.myAddresses,
                iconSrc: "assets/icons/Location.svg",
                onTap: () => Navigator.pushNamed(context, addressesScreenRoute),
                circleBg: iconCircleBg,
                iconColor: iconColor,
                textColor: textColor,
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                title: tr.myWallet,
                iconSrc: "assets/icons/Wallet.svg",
                onTap: () => Navigator.pushNamed(context, walletScreenRoute),
                circleBg: iconCircleBg,
                iconColor: iconColor,
                textColor: textColor,
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------
          // 3. INFORMATION
          // ------------------------------------------
          _buildSectionHeader(context, tr.information, isDark),
          _buildMenuCard(cardBg, [
            _buildMenuItem(
              context,
              title: tr.aboutUs,
              icon: Icons.info_outline_rounded,
              onTap: () => Navigator.pushNamed(context, aboutUsScreenRoute),
              circleBg: iconCircleBg,
              iconColor: iconColor,
              textColor: textColor,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              context,
              title: tr.deliveryInfo,
              iconSrc: "assets/icons/Delivery.svg",
              onTap: () => Navigator.pushNamed(context, deliveryInfoScreenRoute),
              circleBg: iconCircleBg,
              iconColor: iconColor,
              textColor: textColor,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              context,
              title: tr.termsConditions,
              icon: Icons.description_outlined,
              onTap: () => Navigator.pushNamed(context, termsConditionScreenRoute),
              circleBg: iconCircleBg,
              iconColor: iconColor,
              textColor: textColor,
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              context,
              title: tr.contactUs,
              icon: Icons.headset_mic_outlined,
              onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
              circleBg: iconCircleBg,
              iconColor: iconColor,
              textColor: textColor,
            ),
          ]),

          const SizedBox(height: 24),

          // ------------------------------------------
          // 4. SETTINGS
          // ------------------------------------------
          _buildSectionHeader(context, tr.settings, isDark),
          _buildMenuCard(cardBg, [
            _buildMenuItem(
              context,
              title: tr.changeLanguage,
              iconSrc: "assets/icons/Language.svg",
              onTap: () => Navigator.pushNamed(context, selectLanguageScreenRoute),
              circleBg: iconCircleBg,
              iconColor: iconColor,
              textColor: textColor,
            ),
            _buildDivider(isDark),

            // Theme Selection
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.dark_mode_outlined, color: iconColor, size: 20),
              ),
              title: Text(
                tr.darkMode,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getThemeName(themeProvider.themeMode),
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              onTap: () => _showThemeSelection(context),
            ),
          ]),

          const SizedBox(height: 30),

          // ------------------------------------------
          // 5. LOGIN / LOGOUT
          // ------------------------------------------
          if (isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: TextButton(
                onPressed: () => _logout(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFFF0F0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: errorColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      tr.logout,
                      style: const TextStyle(
                        color: errorColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ DELETE ACCOUNT BUTTON (Added below Logout)
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: TextButton(
                onPressed: () => _confirmDeleteAccount(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Delete Account",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, logInScreenRoute),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: brandingColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  tr.loginRegister,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isDark ? Colors.white70 : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(Color bgColor, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String title,
        String? iconSrc,
        IconData? icon,
        required VoidCallback onTap,
        required Color circleBg,
        required Color iconColor,
        required Color textColor,
      }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: circleBg,
          shape: BoxShape.circle,
        ),
        child: iconSrc != null
            ? SvgPicture.asset(
          iconSrc,
          width: 20,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        )
            : Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        indent: 60,
        endIndent: 20
    );
  }
}