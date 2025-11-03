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


/*

FULL AUTH GATE

 */
//
//
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:my_supabase_app/layouts/main_layout.dart';
// import 'package:my_supabase_app/services/auth/login_or_register.dart';
//
// /*
// AUTH GATE (Supabase Version)
//
// Determines whether the user is signed in or not:
//
// - Logged in  -> MainLayout
// - Logged out -> LoginOrRegister
// */
//
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final supabase = Supabase.instance.client;
//
//     return Scaffold(
//       body: StreamBuilder<AuthState>(
//         stream: supabase.auth.onAuthStateChange,
//         builder: (context, snapshot) {
//           final session = supabase.auth.currentSession;
//
//           // 1️⃣ If session exists, user is logged in
//           if (session != null) {
//             return const MainLayout();
//           }
//
//           // 2️⃣ Handle stream updates (auth events)
//           if (snapshot.hasData) {
//             final event = snapshot.data!.event;
//             if (event == AuthChangeEvent.signedIn) {
//               return const MainLayout();
//             } else if (event == AuthChangeEvent.signedOut) {
//               return const LoginOrRegister();
//             }
//           }
//
//           // 3️⃣ While loading / no event yet — show spinner
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const CircularProgressIndicator(),
//                 const SizedBox(height: 14),
//                 Text(
//                   "Checking session...",
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.primary,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
