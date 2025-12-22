import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserProfile();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      isDarkMode = value;
    });
  }

  void _logout(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (context.mounted) {
      Provider.of<CartProvider>(context, listen: false).clearLocalCart();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    // Safety check for localization
    final tr = AppLocalizations.of(context);
    if (tr == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ------------------------------------------
          // 1. HEADER SECTION (Fixed)
          // ------------------------------------------
          Container(
            padding: const EdgeInsets.all(20), // ✅ Fixed: Removed top:60
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Avatar
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

                // Name & Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ✅ Hardcoded for safety - Replace with tr.guestUser later if needed
                        isAuthenticated ? (user?['name'] ?? "User") : "Guest User",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // ✅ Hardcoded for safety
                        isAuthenticated
                            ? (user?['email'] ?? "")
                            : "Welcome to our shop",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ------------------------------------------
          // 2. MY ACCOUNT (Logged In Only)
          // ------------------------------------------
          if (isAuthenticated) ...[
            _buildSectionHeader(context, tr.myAccount),
            _buildMenuCard([
              _buildMenuItem(
                context,
                title: tr.myOrders,
                iconSrc: "assets/icons/Order.svg",
                onTap: () => Navigator.pushNamed(context, ordersScreenRoute),
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                title: tr.myAddresses,
                iconSrc: "assets/icons/Location.svg",
                onTap: () => Navigator.pushNamed(context, addressesScreenRoute),
              ),
              _buildDivider(),
              _buildMenuItem(
                context,
                title: tr.myWallet,
                iconSrc: "assets/icons/Wallet.svg",
                onTap: () => Navigator.pushNamed(context, walletScreenRoute),
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------
          // 3. INFORMATION
          // ------------------------------------------
          _buildSectionHeader(context, tr.information),
          _buildMenuCard([
            _buildMenuItem(
              context,
              title: tr.aboutUs,
              icon: Icons.info_outline_rounded,
              onTap: () => Navigator.pushNamed(context, aboutUsScreenRoute),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              title: tr.deliveryInfo,
              iconSrc: "assets/icons/Delivery.svg",
              onTap: () => Navigator.pushNamed(context, deliveryInfoScreenRoute),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              title: tr.termsConditions,
              icon: Icons.description_outlined,
              onTap: () => Navigator.pushNamed(context, termsConditionScreenRoute),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              title: tr.contactUs,
              icon: Icons.headset_mic_outlined,
              onTap: () => Navigator.pushNamed(context, contactUsScreenRoute),
            ),
          ]),

          const SizedBox(height: 24),

          // ------------------------------------------
          // 4. SETTINGS
          // ------------------------------------------
          _buildSectionHeader(context, tr.settings),
          _buildMenuCard([
            _buildMenuItem(
              context,
              title: tr.changeLanguage,
              iconSrc: "assets/icons/Language.svg",
              onTap: () => Navigator.pushNamed(context, selectLanguageScreenRoute),
            ),
            _buildDivider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dark_mode_outlined, color: primaryColor, size: 20),
              ),
              title: Text(
                tr.darkMode,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              trailing: Switch.adaptive(
                value: isDarkMode,
                onChanged: _toggleTheme,
                activeColor: primaryColor,
              ),
            ),
          ]),

          const SizedBox(height: 30),

          // ------------------------------------------
          // 5. LOGIN / LOGOUT BUTTON
          // ------------------------------------------
          if (isAuthenticated)
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
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, logInScreenRoute),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
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
      }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: iconSrc != null
            ? SvgPicture.asset(
          iconSrc,
          width: 20,
          colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
        )
            : Icon(icon, size: 20, color: primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 60, endIndent: 20);
  }
}