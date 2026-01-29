import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';
import 'package:shop/screens/auth/views/password_recovery_screen.dart';
import '../screens/auth/views/sign_up_screen.dart';
import '../screens/category/sub_category_screen.dart';
import '../screens/category/sub_category_products_screen.dart';
import '../screens/checkout/views/checkout_screen.dart';
import '../screens/profile/views/info_screens.dart';
import 'screen_export.dart' hide UserInfoScreen;
import "package:shop/controllers/locale_controller.dart";
import 'package:shop/screens/profile/views/user_info_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case onbordingScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnBordingScreen(),
      );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case productDetailsScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final int productId = settings.arguments as int;
          return ProductDetailsScreen(
            productId: productId,
            onLocaleChange: (locale) {
              LocaleController.updateLocale?.call(locale);
            },
          );
        },
      );
    case productReviewsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProductReviewsScreen(),
      );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => EntryPoint(
          initialIndex: 0,
          onLocaleChange: (locale) {
            LocaleController.updateLocale?.call(locale);
          },
        ),
      );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    case onSaleScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnSaleScreen(),
      );
    case kidsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const KidsScreen(),
      );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    case bookmarkScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookmarkScreen(),
      );
    case entryPointScreenRoute:
      final args = settings.arguments;
      int initialIndex = 0;
      if (args is int) {
        initialIndex = args;
      }
      return MaterialPageRoute(
        builder: (context) => EntryPoint(
          initialIndex: initialIndex,
          onLocaleChange: (locale) {
            LocaleController.updateLocale?.call(locale);
          },
        ),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case userInfoScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    case ordersScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    case preferencesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      );
    case emptyWalletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EmptyWalletScreen(),
      );
    case walletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const WalletScreen(),
      );
    case cartScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CartScreen(isStandalone: true),
      );
    case subCategoryScreenRoute:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => SubCategoryScreen(
          parentId: args['parentId'],
          title: args['title'],
          currentIndex: args['currentIndex'],
          user: args['user'],
          onTabChanged: args['onTabChanged'],
          onLocaleChange: args['onLocaleChange'],
        ),
      );

  // ✅ 2. ADD THIS NEW CASE
  // This handles navigation from the Drawer (Brands & Manufacturers)
    case "sub_category_products_screen":
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => SubCategoryProductsScreen(
          categorySlug: args['categorySlug'] ?? '',
          initialBrandSlug: args['initialBrandSlug'],
          initialManufacturerSlug: args['initialManufacturerSlug'],

          // ✅ Add this line
          searchQuery: args['searchQuery'],

          title: args['title'] ?? 'Products',
          currentIndex: args['currentIndex'] ?? 0,
          user: args['user'],
          onTabChanged: args['onTabChanged'],
          onLocaleChange: args['onLocaleChange'],
        ),
      );

    case addressesScreenRoute:
      return MaterialPageRoute(
        builder: (_) => const AddressesScreen(),
      );
    case aboutUsScreenRoute:
      return MaterialPageRoute(builder: (_) => const AboutUsScreen());
    case deliveryInfoScreenRoute:
      return MaterialPageRoute(builder: (_) => const DeliveryInfoScreen());
    case termsConditionScreenRoute:
      return MaterialPageRoute(builder: (_) => const TermsConditionScreen());
    case contactUsScreenRoute:
      return MaterialPageRoute(builder: (_) => const ContactUsScreen());
    case checkoutScreenRoute:
      return MaterialPageRoute(
          builder: (context) => const CheckoutScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => EntryPoint(
          initialIndex: 0,
          onLocaleChange: (locale) {
            LocaleController.updateLocale?.call(locale);
          },
        ),
      );
  }
}