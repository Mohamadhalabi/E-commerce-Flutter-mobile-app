import 'package:flutter/material.dart';
import 'package:shop/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;
  //
  // Future<void> _register() async {
  //   setState(() {
  //     isLoading = true;
  //     error = null;
  //   });
  //
  //   final success = await AuthService.register(
  //     nameController.text,
  //     emailController.text,
  //     passwordController.text,
  //   );
  //
  //   setState(() => isLoading = false);
  //
  //   if (success) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //     );
  //   } else {
  //     setState(() => error = 'Registration failed.');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
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
            // ElevatedButton(
            //   onPressed: isLoading ? null : _register,
            //   child: isLoading ? const CircularProgressIndicator() : const Text("Register"),
            // ),
          ],
        ),
      ),
    );
  }
}