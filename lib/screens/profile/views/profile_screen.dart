import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isAuthenticated = false;
  Map<String, dynamic>? user;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadTheme();
  }

  Future<void> _checkAuth() async {
    try {
      final userData = await AuthService.getUserProfile();
      if (userData != null) {
        setState(() {
          isAuthenticated = true;
          user = userData;
        });
      } else {
        setState(() {
          isAuthenticated = false;
        });
      }
    } catch (_) {
      setState(() {
        isAuthenticated = false;
      });
    }
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
    // If you have a theme provider, notify it here
  }

  void _logout() async {
    await AuthService.logoutUser();
    setState(() {
      isAuthenticated = false;
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Profile card for both states
          if (isAuthenticated)
            ProfileCard(
              name: "${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}",
              email: user?['email'] ?? '',
              imageSrc: user?['avatar'] ?? "https://i.imgur.com/IXnwbLk.png",
              press: () {
                Navigator.pushNamed(context, userInfoScreenRoute);
              },
            )
          else
            ProfileCard(
              name: "Guest",
              email: "Please login or register",
              imageSrc:
              "https://cdn-icons-png.flaticon.com/512/847/847969.png", // generic avatar
              press: () {
                // Navigator.pushNamed(context, loginScreenRoute);
              },
            ),

          // Banner for logged-in users only
          if (isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding * 1.5),
              child: const AspectRatio(
                aspectRatio: 1.8,
                child: NetworkImageWithLoader("https://i.imgur.com/dz0BBom.png"),
              ),
            ),

          if (isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Text("Account",
                  style: Theme.of(context).textTheme.titleSmall),
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

          // Personalization for all users
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text("Personalization",
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ProfileMenuListTile(
            text: "Change Language",
            svgSrc: "assets/icons/Language.svg",
            press: () {
              Navigator.pushNamed(context, selectLanguageScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Change Currency",
            svgSrc: "assets/icons/card.svg",
            press: () {
              // Navigator.pushNamed(context, selectCurrencyScreenRoute);
            },
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: _toggleTheme,
            secondary: const Icon(Icons.dark_mode),
          ),

          const SizedBox(height: defaultPadding),

          // Logout or Login/Register button
          ListTile(
            onTap: isAuthenticated ? _logout : () {
              // Navigator.pushNamed(context, loginScreenRoute);
            },
            minLeadingWidth: 24,
            leading: SvgPicture.asset(
              isAuthenticated
                  ? "assets/icons/Logout.svg"
                  : "assets/icons/Login.svg",
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                isAuthenticated ? errorColor : Colors.green,
                BlendMode.srcIn,
              ),
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
