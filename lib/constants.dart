import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String apiKey = dotenv.env['API_KEY'] ?? '';
  static final String secretKey = dotenv.env['SECRET_KEY'] ?? '';
}

// Just for demo
const productDemoImg1 = "";
const productDemoImg2 = "";
const productDemoImg3 = "";
const productDemoImg4 = "";
const productDemoImg5 = "";
const productDemoImg6 = "";
// End For demo

const grandisExtendedFont = "Poppins";

const double defaultBorderRadius = 12.0;

// ---------------------------------------------------------------------------
// BRAND — one red family, used everywhere (no more purple accents)
// ---------------------------------------------------------------------------
const Color primaryColor = Color(0xFFDC2626);
const Color primaryDarkColor = Color(0xFFB91C1C);
const Color primaryDeepColor = Color(0xFF991B1B);
const Color primarySoftColor = Color(0xFFFEF2F2);

// Swatch now matches primaryColor (the old 500 was 0xFFA51517, a different red)
const MaterialColor primaryMaterialColor = MaterialColor(
  0xFFDC2626,
  <int, Color>{
    50: Color(0xFFFEF2F2),
    100: Color(0xFFFEE2E2),
    200: Color(0xFFFECACA),
    300: Color(0xFFFCA5A5),
    400: Color(0xFFF87171),
    500: Color(0xFFEF4444),
    600: Color(0xFFDC2626),
    700: Color(0xFFB91C1C),
    800: Color(0xFF991B1B),
    900: Color(0xFF7F1D1D),
  },
);

const Color blackColor = Color(0xFF16161E);
const Color blackColor80 = Color(0xFF45454B);
const Color blackColor60 = Color(0xFF737378);
const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor20 = Color(0xFFD0D0D2);
const Color blackColor10 = Color(0xFFE8E8E9);
const Color blackColor5 = Color(0xFFF3F3F4);

const Color whiteColor = Colors.white;
const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);

const Color greyColor = Color(0xFFB8B5C3);
const Color lightGreyColor = Color(0xFFF8F8F9);
const Color darkGreyColor = Color(0xFF1C1C25);

const Color greenColor = Color(0xFF1B5E20);
const Color redColor = Color(0xFFD32F2F);

// Kept so existing screens still compile — avoid using it for new UI.
const Color purpleColor = Color(0xFF7B61FF);
const Color successColor = Color(0xFF2ED573);
const Color warningColor = Color(0xFFFFBE21);
const Color errorColor = Color(0xFFEA5B5B);

// ---------------------------------------------------------------------------
// SURFACES
// ---------------------------------------------------------------------------
const Color lightSurfaceColor = Color(0xFFF6F6F8);
const Color darkSurfaceColor = Color(0xFF0F0F14);
const Color darkCardColor = Color(0xFF1A1A22);
const Color darkCardElevatedColor = Color(0xFF24242E);

// ---------------------------------------------------------------------------
// SIZES
// ---------------------------------------------------------------------------
const double defaultPadding = 16.0;
const double defaultBorderRadious = 12.0;
const double cardRadius = 16.0;
const double navBarHeight = 68.0;
const Duration defaultDuration = Duration(milliseconds: 300);

/// Theme-aware colors so widgets stop hardcoding light/dark pairs.
class AppPalette {
  AppPalette._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color card(BuildContext c) => isDark(c) ? darkCardColor : Colors.white;
  static Color cardElevated(BuildContext c) =>
      isDark(c) ? darkCardElevatedColor : blackColor5;
  static Color text(BuildContext c) => isDark(c) ? Colors.white : blackColor;
  static Color textMuted(BuildContext c) =>
      isDark(c) ? Colors.white60 : blackColor60;
  static Color border(BuildContext c) =>
      isDark(c) ? Colors.white10 : blackColor10;
}

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])',
      errorText: 'passwords must have at least one special character')
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";