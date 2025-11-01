import 'package:flutter/material.dart';
import 'package:my_supabase_app/pages/login_page.dart';
import 'package:my_supabase_app/pages/register_page.dart';

/*

LOGIN OR REGISTER PAGE

This widget determines whether to display the LoginPage or RegisterPage
based on user interaction.

- Initially, the LoginPage is displayed.
- Users can toggle between Login and Register using the onTap callback.

This keeps your authentication flow clean and modular:
  - LoginPage handles sign-in with Supabase
  - RegisterPage handles sign-up with Supabase

*/

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Track whether the login page should be shown
  bool showLoginPage = true;

  /// Toggle between LoginPage and RegisterPage.
  ///
  /// If there is an open dialog (like a SnackBar or AlertDialog),
  /// it will be dismissed when switching pages to avoid UI conflicts.
  void togglePages() {
    if (Navigator.canPop(context)) Navigator.pop(context);

    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Display either LoginPage or RegisterPage based on `showLoginPage`
    return showLoginPage
        ? LoginPage(
      // Pass the toggle function to LoginPage so the user can switch to Register
      onTap: togglePages,
    )
        : RegisterPage(
      // Pass the toggle function to RegisterPage so the user can switch to Login
      onTap: togglePages,
    );
  }
}