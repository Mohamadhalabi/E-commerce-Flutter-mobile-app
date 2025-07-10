import 'package:flutter/material.dart';
import 'package:shop/services/auth_service.dart';
import '../../../components/common/MainScaffold.dart';
import '../../../entry_point.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final success = await AuthService.login(emailController.text, passwordController.text);

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EntryPoint(
            onLocaleChange: (locale) {
              // Optional: handle locale change after login
            },
          ),
        ),
      );
    } else {
      setState(() => error = 'Invalid email or password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4, // or 0 if you want it on home
      onTabChanged: (index) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EntryPoint(
              onLocaleChange: (locale) {
                // Optional: handle locale change after login
              },
            ),
          ),
        );
      },
      onLocaleChange: (locale) {}, // if not needed, pass a dummy function
      user: null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text("Forgot Password?"),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}