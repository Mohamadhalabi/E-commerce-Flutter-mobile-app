import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shop/components/auth/auth_widgets.dart';
import 'package:shop/components/common/CustomBottomNavigationBar.dart';
import 'package:shop/components/common/drawer.dart';
import 'package:shop/components/common/app_bar.dart';
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

  Future<void> _submit() async {
    final tr = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Returns an error message, or null on success
    final errorMessage = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      _handleAuthResult(true, tr.registerSuccess, "");
    } else {
      _handleAuthResult(false, "", errorMessage);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    _handleAuthResult(success, "Signed in with Google", "Google sign-in failed");
  }

  Future<void> _handleAppleLogin() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithApple(credential);
      if (!mounted) return;
      _handleAuthResult(success, "Signed in with Apple", "Apple sign-in failed");
    } catch (e) {
      debugPrint("Apple Sign In Error: $e");
      if (e.toString().contains('Canceled') || !mounted) return;
      showAuthMessage(context, "Apple sign-in failed", success: false);
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
      if (!mounted) return;
      showAuthMessage(context, successMsg, success: true);
      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
    } else {
      showAuthMessage(context, failMsg, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 4, onTap: _onBottomNavTap),
      body: Builder(
        builder: (bodyContext) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(bodyContext).bottom + 24,
          ),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthHeader(
                    icon: Icons.person_add_alt_1_rounded,
                    title: tr.createAccount,
                    subtitle: tr.registerPrompt,
                  ),
                  const SizedBox(height: 28),
                  AuthTextField(
                    controller: _nameController,
                    label: tr.name,
                    hint: tr.enterName,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? tr.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    label: tr.email,
                    hint: tr.enterEmail,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) =>
                    (value == null || value.isEmpty || !value.contains('@'))
                        ? tr.validEmail
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _phoneController,
                    label: tr.phoneNumber,
                    hint: tr.enterPhone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? tr.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: tr.password,
                    hint: tr.enterPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureText,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: (value) =>
                    (value == null || value.length < 8) ? tr.minPassword : null,
                    suffix: IconButton(
                      tooltip: _obscureText ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppPalette.textMuted(context),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthPrimaryButton(
                    label: tr.signUp,
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 28),
                  AuthDivider(tr.orContinueWith),
                  const SizedBox(height: 16),
                  SocialAuthButtons(
                    enabled: !isLoading,
                    onGoogle: _handleGoogleLogin,
                    onApple: _handleAppleLogin,
                  ),
                  const SizedBox(height: 24),
                  AuthFooterLink(
                    prompt: tr.alreadyHaveAccount,
                    action: tr.login,
                    onTap: () => Navigator.pop(context),
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