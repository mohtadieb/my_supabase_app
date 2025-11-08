import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_supabase_app/layouts/main_layout.dart';
import 'package:my_supabase_app/services/auth/login_or_register.dart';

/*
AUTH GATE (Supabase Version)

Checks if the user is logged in or not:

- logged in  -> MainLayout
- not logged in -> LoginOrRegister
*/

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: _auth.onAuthStateChange,
      builder: (context, _) {
        final session = _auth.currentSession;

        // Choose which screen to show
        final Widget currentScreen = session != null
            // User logged in
            ? const MainLayout()

            // User not logged in
            : const LoginOrRegister();

        // Wrap with AnimatedSwitcher for a smooth fade transition
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: currentScreen,
        );
      },
    );
  }
}
