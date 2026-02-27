import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../components/common/CustomBottomNavigationBar.dart';
import '../../../../components/common/drawer.dart';
import '../../../../components/common/app_bar.dart';
import 'package:shop/controllers/locale_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ UPDATED: Now matches LoginScreen navigation exactly
  void _onBottomNavTap(int index) {
    if (index == 3) {
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
            (route) => false,
        arguments: index,
      );
    }
  }

  void _onLocaleChange(String locale) {
    LocaleController.updateLocale?.call(locale);
    setState(() {});
  }

  void _showCustomNotification(BuildContext context, String message, bool isSuccess) {
    final tr = AppLocalizations.of(context)!;
    final topMargin = MediaQuery.of(context).size.height - 230;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF2A2A35) : Colors.white;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black87;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: isSuccess ? Colors.green : Colors.red, width: 6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSuccess ? tr.success : tr.error,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(fontSize: 13, color: subTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: topMargin, left: 20, right: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    final tr = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    _handleAuthResult(success, tr.registerSuccess, tr.registerFailed);
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    _handleAuthResult(success, "Google Login Successful", "Google Login Failed");
  }

  Future<void> _handleAppleLogin() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Call the provider method
      bool success = await authProvider.signInWithApple(credential);

      if (!mounted) return;
      _handleAuthResult(success, "Apple Login Successful", "Apple Login Failed");

    } catch (e) {
      print("Apple Sign In Error: $e");
      if (e.toString().contains('Canceled')) return;
      _showCustomNotification(context, "Apple Sign In Failed", false);
    }
  }

  Future<void> _handleAuthResult(bool success, String successMsg, String failMsg) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (success) {
      if (authProvider.token != null) {
        cartProvider.setAuthToken(authProvider.token);
        await cartProvider.mergeLocalCartToAccount(authProvider.token!);
      }
      _showCustomNotification(context, successMsg, true);
      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
    } else {
      _showCustomNotification(context, failMsg, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final tr = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey;

    final Color inputFill = isDark ? const Color(0xFF2A2A35) : Colors.grey[100]!;
    final Color inputIconColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const CustomAppBar(),
      drawer: CustomEndDrawer(
        onLocaleChange: _onLocaleChange,
        user: null,
        onTabChanged: (index) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            entryPointScreenRoute,
                (route) => false,
            arguments: index,
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 4,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  tr.createAccount,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(tr.registerPrompt, style: TextStyle(color: subTextColor)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: textColor),
                  validator: (value) => (value == null || value.isEmpty) ? tr.requiredField : null,
                  decoration: InputDecoration(
                    labelText: tr.name,
                    labelStyle: TextStyle(color: subTextColor),
                    hintText: tr.enterName,
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: inputFill,
                    suffixIcon: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.person_outline, color: inputIconColor)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? tr.validEmail : null,
                  decoration: InputDecoration(
                    labelText: tr.email,
                    labelStyle: TextStyle(color: subTextColor),
                    hintText: tr.enterEmail,
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: inputFill,
                    suffixIcon: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.email_outlined, color: inputIconColor)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textColor),
                  validator: (value) => (value == null || value.isEmpty) ? tr.requiredField : null,
                  decoration: InputDecoration(
                    labelText: tr.phoneNumber,
                    labelStyle: TextStyle(color: subTextColor),
                    hintText: tr.enterPhone,
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: inputFill,
                    suffixIcon: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.phone_android_outlined, color: inputIconColor)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  style: TextStyle(color: textColor),
                  validator: (value) => (value == null || value.length < 8) ? tr.minPassword : null,
                  decoration: InputDecoration(
                    labelText: tr.password,
                    labelStyle: TextStyle(color: subTextColor),
                    hintText: tr.enterPassword,
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: true,
                    fillColor: inputFill,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: inputIconColor),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(tr.signUp, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(color: subTextColor.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(tr.orContinueWith ?? "Or continue with", style: TextStyle(color: subTextColor)),
                    ),
                    Expanded(child: Divider(color: subTextColor.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: isLoading ? null : _handleGoogleLogin,
                      borderRadius: BorderRadius.circular(50),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark ? const Color(0xFF353545) : Colors.grey[200],
                        child: const Icon(Icons.g_mobiledata, size: 35, color: Colors.red),
                      ),
                    ),

                    const SizedBox(width: 20),

                    InkWell(
                      onTap: isLoading ? null : _handleAppleLogin,
                      borderRadius: BorderRadius.circular(50),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        child: Icon(
                            Icons.apple,
                            size: 28,
                            color: isDark ? Colors.black : Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr.alreadyHaveAccount, style: TextStyle(color: subTextColor)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(tr.login, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}