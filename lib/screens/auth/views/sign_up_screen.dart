import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../components/common/CustomBottomNavigationBar.dart';

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
    if (index == 4) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      String? routeName;
      switch (index) {
        case 1: routeName = searchScreenRoute; break;
        case 2: routeName = discoverScreenRoute; break;
        case 3: routeName = cartScreenRoute; break;
      }
      if (routeName != null) {
        Navigator.pushNamed(context, routeName);
      }
    }
  }

  // ✅ CUSTOM TOP NOTIFICATION
  void _showCustomNotification(BuildContext context, String message, bool isSuccess) {
    final tr = AppLocalizations.of(context)!;

    // Calculate margin to position at TOP of screen
    final topMargin = MediaQuery.of(context).size.height - 230;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isSuccess ? Colors.green : Colors.red,
                width: 6,
              ),
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
                      isSuccess ? tr.success : tr.error, // ✅ Translated Success/Error
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
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
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    bool success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.token != null) {
        cartProvider.setAuthToken(authProvider.token);
        await cartProvider.mergeLocalCartToAccount(authProvider.token!);
      }
      _showCustomNotification(context, tr.registerSuccess, true);
      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
    } else {
      _showCustomNotification(context, tr.registerFailed, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final tr = AppLocalizations.of(context)!; // ✅ Translations loaded

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr.signUp, // ✅ "Sign Up"
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, cartScreenRoute),
          ),
        ],
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
                  tr.createAccount, // ✅ "Create Account"
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ TRANSLATED SUBTITLE
                Text(
                  tr.registerPrompt, // "Enter your details to register"
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // Name
                TextFormField(
                  controller: _nameController,
                  validator: (value) => (value == null || value.isEmpty) ? tr.requiredField : null,
                  decoration: InputDecoration(
                    labelText: tr.name,
                    hintText: tr.enterName, // ✅ "Enter your full name"
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.person_outline)),
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty || !value.contains('@')) ? tr.validEmail : null,
                  decoration: InputDecoration(
                    labelText: tr.email,
                    hintText: tr.enterEmail, // ✅ "Enter your email"
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.email_outlined)),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.isEmpty) ? tr.requiredField : null,
                  decoration: InputDecoration(
                    labelText: tr.phoneNumber,
                    hintText: tr.enterPhone, // ✅ "Enter your phone number"
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.phone_android_outlined)),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  validator: (value) => (value == null || value.length < 8) ? tr.minPassword : null,
                  decoration: InputDecoration(
                    labelText: tr.password,
                    hintText: tr.enterPassword, // ✅ "Enter your password"
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
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

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ TRANSLATED "Already have an account?"
                    Text(tr.alreadyHaveAccount, style: const TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(tr.login, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)), // "Login"
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