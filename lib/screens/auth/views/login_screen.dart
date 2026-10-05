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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
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

  // --------------------------------------------------------------------------
  // FORGOT PASSWORD (bottom sheet)
  // --------------------------------------------------------------------------
  void _showForgotPasswordSheet() {
    final tr = AppLocalizations.of(context)!;
    final emailController = TextEditingController(text: _emailController.text.trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr.forgotPassword,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your email and we'll send you a link to reset your password.",
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppPalette.textMuted(context),
                ),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                controller: emailController,
                label: tr.email,
                hint: tr.enterEmail,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofocus: emailController.text.isEmpty,
              ),
              const SizedBox(height: 18),
              AuthPrimaryButton(
                label: "Send reset link",
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) return;
                  Navigator.pop(sheetContext);

                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final ok = await auth.resetPassword(email);
                  if (!mounted) return;
                  showAuthMessage(
                    context,
                    ok
                        ? "Reset link sent. Check your inbox."
                        : "Couldn't send the link. Check the email address.",
                    success: ok,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // AUTH
  // --------------------------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tr = AppLocalizations.of(context)!;

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    _handleAuthResult(success, tr.loginSuccess, tr.loginFailed);
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

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

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
        // Builder: context inside the body, so the padding includes the nav
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
                    icon: Icons.lock_outline_rounded,
                    title: tr.welcome,
                    subtitle: tr.signInPrompt,
                  ),
                  const SizedBox(height: 28),
                  AuthTextField(
                    controller: _emailController,
                    label: tr.email,
                    hint: tr.enterEmail,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? tr.validEmail : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: tr.password,
                    hint: tr.enterPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureText,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? tr.minPassword : null,
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
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _showForgotPasswordSheet,
                      style: TextButton.styleFrom(foregroundColor: primaryColor),
                      child: Text(
                        tr.forgotPassword,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    label: tr.login,
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
                    prompt: tr.noAccount,
                    action: tr.signUp,
                    onTap: () => Navigator.pushNamed(context, signUpScreenRoute),
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