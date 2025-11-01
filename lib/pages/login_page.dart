import 'package:flutter/material.dart';
import 'package:my_supabase_app/components/my_loading_circle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/my_button.dart';
import '../components/my_loading_overlay.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';

/*
LOGIN PAGE (Supabase Version)

Features:
- Login with email/password via AuthService
- Loading overlay while logging in
- Automatic session detection by AuthGate
- Toggle to RegisterPage
- No yellow overflow line during loading
*/

class LoginPage extends StatefulWidget {
  final void Function()? onTap; // Callback to switch to RegisterPage

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService(); // Auth logic
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  bool _isLoading = false; // Track overlay visibility

  /// Handles login with AuthService
  Future<void> login() async {
    showLoadingCircle(context, message: "Logging in...");
    try {
      // Use AuthService to login
      await _authService.loginEmailPassword(
        emailController.text.trim(),
        pwController.text.trim(),
      );

      // Success — AuthGate handles navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );
      }
    } catch (e) {
      // Show error dialog if login fails
      if (mounted) showErrorDialog(e.toString());
    } finally {
      hideLoadingCircle(context);
    }
  }

  /// Shows a simple error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main login UI
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Prevents full-height overflow
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(
                      Icons.lock,
                      size: 70,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      "Welcome back! Login to your account",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    MyTextField(
                      controller: emailController,
                      hintText: "Enter email",
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: pwController,
                      hintText: "Enter password",
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    MyButton(text: "Login", onTap: login),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            "Register here",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
