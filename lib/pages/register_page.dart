import 'package:flutter/material.dart';
import 'package:my_supabase_app/components/my_loading_circle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';

/*
REGISTER PAGE (Supabase Version)

This page allows a new user to create an account using Supabase authentication.
*/

class RegisterPage extends StatefulWidget {
  final void Function()? onTap; // Callback to switch to LoginPage

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;
  final AuthService authService = AuthService(); // <-- add this

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool _isLoading = false;

  /// Register user
  Future<void> register() async {
    if (pwController.text != confirmPwController.text) {
      showErrorDialog("Passwords don't match");
      return;
    }

    showLoadingCircle(context, message: "Registering...");

    try {
      await authService.registerEmailPassword(
        emailController.text.trim(),
        pwController.text.trim(),
        nameController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
    } on Exception catch (e) {
      showErrorDialog(e.toString());
    } finally {
      hideLoadingCircle(context);
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Error'),
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
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Icon(
                        Icons.lock_open_rounded,
                        size: 70,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 50),
                      Text(
                        "Let's create an account for you",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 25),
                      MyTextField(
                        controller: nameController,
                        hintText: "Enter name",
                        obscureText: false,
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      MyTextField(
                        controller: confirmPwController,
                        hintText: "Confirm password",
                        obscureText: true,
                      ),
                      const SizedBox(height: 25),
                      MyButton(text: "Register", onTap: register),
                      const SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already a member? ",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Text(
                              "Login here",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
