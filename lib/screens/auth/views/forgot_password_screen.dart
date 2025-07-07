import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isSent = false;

  Future<void> sendReset() async {
    final res = await http.post(
      Uri.parse('${dotenv.env['API_BASE_URL']!}/forget-password'),
      headers: {
        'Accept': 'application/json',
        'API-KEY': dotenv.env['API_KEY']!,
        'SECRET-KEY': dotenv.env['SECRET_KEY']!,
      },
      body: {'email': emailController.text},
    );

    setState(() => isSent = res.statusCode == 200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isSent)
              const Text("Check your email for reset link.",
                  style: TextStyle(color: Colors.green)),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sendReset,
              child: const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}