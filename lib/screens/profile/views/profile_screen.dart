import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

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
    // Fetch profile data when screen loads
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
    // Optional: Refresh the screen or go to login
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    return Scaffold(
      body: ListView(
        children: [
          // 1. Profile Card
          if (isAuthenticated)
            ProfileCard(
              // Use user data safely
              name: user?['name'] ?? "User",
              email: user?['email'] ?? "",
              imageSrc: user?['avatar'] ?? "https://i.imgur.com/IXnwbLk.png",
              press: () {
                Navigator.pushNamed(context, userInfoScreenRoute);
              },
            )
          else
            ProfileCard(
              name: "Guest",
              email: "Please login or register",
              imageSrc: "https://cdn-icons-png.flaticon.com/512/847/847969.png",
              press: () {
                Navigator.pushNamed(context, logInScreenRoute);
              },
            ),

          // 2. Banner (Logged in only)
          if (isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding * 1.5),
              child: const AspectRatio(
                aspectRatio: 1.8,
                child: NetworkImageWithLoader("https://i.imgur.com/dz0BBom.png"),
              ),
            ),

          // 3. Menu Items (Logged in only)
          if (isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Text("Account", style: Theme.of(context).textTheme.titleSmall),
            ),
            const SizedBox(height: defaultPadding / 2),
            ProfileMenuListTile(
              text: "Orders",
              svgSrc: "assets/icons/Order.svg",
              press: () => Navigator.pushNamed(context, ordersScreenRoute),
            ),
            ProfileMenuListTile(
              text: "Wallet",
              svgSrc: "assets/icons/Wallet.svg",
              press: () => Navigator.pushNamed(context, walletScreenRoute),
            ),
          ],

          const SizedBox(height: defaultPadding),

          // 4. Personalization
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text("Personalization", style: Theme.of(context).textTheme.titleSmall),
          ),
          ProfileMenuListTile(
            text: "Change Language",
            svgSrc: "assets/icons/Language.svg",
            press: () {
              Navigator.pushNamed(context, selectLanguageScreenRoute);
            },
          ),

          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: _toggleTheme,
            secondary: const Icon(Icons.dark_mode),
          ),

          const SizedBox(height: defaultPadding),

          // 5. Logout / Login Button (CRASH FIX HERE)
          ListTile(
            onTap: isAuthenticated ? () => _logout(context) : () {
              Navigator.pushNamed(context, logInScreenRoute);
            },
            minLeadingWidth: 24,
            // -----------------------------------------------------------
            // ✅ FIX: Use Icon() instead of SvgPicture to prevent crashes
            // -----------------------------------------------------------
            leading: Icon(
              isAuthenticated ? Icons.logout : Icons.login,
              size: 24,
              color: isAuthenticated ? errorColor : Colors.green,
            ),
            title: Text(
              isAuthenticated ? "Log Out" : "Login / Register",
              style: TextStyle(
                color: isAuthenticated ? errorColor : Colors.green,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}