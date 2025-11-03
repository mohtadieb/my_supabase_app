import 'package:flutter/material.dart';
import 'package:my_supabase_app/components/my_loading_circle.dart';
import 'package:my_supabase_app/services/database/database_service.dart';
import '../components/my_button.dart';
import '../components/my_text_field.dart';
import '../services/auth/auth_service.dart';

/*
REGISTER PAGE (Supabase Version)

This page allows a new user to create an account using Supabase authentication.
We need:

- Name
- Email
- Password
- Confirm Password

--------------------------------------------------------------------------------

Once the user successfully created an account they will be redirected to home page.

Also, if user already has an account, they can go to login page from here.

*/

class RegisterPage extends StatefulWidget {
  final void Function()? onTap; // Callback to switch to LoginPage

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  /// Register user
  Future<void> register() async {

    // Password check
    if (pwController.text != confirmPwController.text) {
      showErrorDialog("Passwords don't match");
      return;
    }
    // loading
    showLoadingCircle(context, message: "Registering...");

    try {
      await _auth.registerEmailPassword(
        emailController.text.trim(),
        pwController.text.trim(),
      );

      // save info in databsae
      await _db.saveUserInDatabase(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        hideLoadingCircle(context);
      }
    } catch (e) {
      if (mounted) {
        hideLoadingCircle(context);
        // Show error dialog if register fails
        showErrorDialog(e.toString());
      }
    }
  }

  /// Error dialog
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

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // SCAFFOLD
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const SizedBox(height: 56),

                      // ICON
                      Icon(
                        Icons.lock_open_rounded,
                        size: 70,
                        color: Theme.of(context).colorScheme.primary,
                      ),

                      const SizedBox(height: 56),

                      //TEXT
                      Text(
                        "Let's create an account for you",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Name Text Field
                      MyTextField(
                        controller: nameController,
                        hintText: "Enter name",
                        obscureText: false,
                      ),

                      const SizedBox(height: 7),

                      //Email Text Field
                      MyTextField(
                        controller: emailController,
                        hintText: "Enter email",
                        obscureText: false,
                      ),

                      const SizedBox(height: 7),

                      //Password Text Field
                      MyTextField(
                        controller: pwController,
                        hintText: "Enter password",
                        obscureText: true,
                      ),

                      const SizedBox(height: 7),

                      // Confirm password text field
                      MyTextField(
                        controller: confirmPwController,
                        hintText: "Confirm password",
                        obscureText: true,
                      ),

                      const SizedBox(height: 28),

                      // Register button
                      MyButton(text: "Register", onTap: register),

                      const SizedBox(height: 56),

                      // Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already a member? ",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          const SizedBox(width: 7),

                          // Register tap
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
