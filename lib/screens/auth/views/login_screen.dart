import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/route/route_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ✅ Import Custom Bottom Bar
import '../../../../components/common/CustomBottomNavigationBar.dart';

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
      // 1. If Cart, push the Cart Screen on top
      Navigator.pushNamed(context, cartScreenRoute);
    } else {
      // 2. For Home (0), Search (1), Shop (2), Profile (4)
      // We navigate to EntryPoint and pass the index as an argument
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
            (route) => false, // This removes all previous routes (clears stack)
        arguments: index, // <--- We pass the selected index here
      );
    }
  }

  // ✅ CUSTOM NOTIFICATION
  void _showCustomNotification(BuildContext context, String message, bool isSuccess) {
    final tr = AppLocalizations.of(context)!;
    final topMargin = MediaQuery.of(context).size.height - 230;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
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
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final tr = AppLocalizations.of(context)!;

    bool success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.token != null) {
        cartProvider.setAuthToken(authProvider.token);
        await cartProvider.mergeLocalCartToAccount(authProvider.token!);
      }
      _showCustomNotification(context, tr.loginSuccess, true);
      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (route) => false);
    } else {
      _showCustomNotification(context, tr.loginFailed, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(tr.login, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, entryPointScreenRoute);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, cartScreenRoute),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 4, onTap: _onBottomNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  tr.welcome,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),

                Text(tr.signInPrompt, style: const TextStyle(color: Colors.grey)), // ✅ Translated

                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty) ? tr.validEmail : null, // ✅ Translated
                  decoration: InputDecoration(
                    labelText: tr.email,
                    hintText: tr.enterEmail, // ✅ Translated "Enter your email"
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: const Padding(padding: EdgeInsets.fromLTRB(0, 12, 12, 12), child: Icon(Icons.email_outlined)),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  validator: (value) => (value == null || value.isEmpty) ? tr.minPassword : null, // ✅ Translated
                  decoration: InputDecoration(
                    labelText: tr.password,
                    hintText: tr.enterPassword, // ✅ Translated "Enter your password"
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
                        : Text(tr.login, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr.noAccount, style: const TextStyle(color: Colors.grey)), // ✅ Translated
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, signUpScreenRoute),
                      child: Text(tr.signUp, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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