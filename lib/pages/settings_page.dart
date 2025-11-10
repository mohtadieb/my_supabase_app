import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_supabase_app/components/my_loading_circle.dart';
import 'package:provider/provider.dart';

import '../components/my_settings_tile.dart';
import '../helper/navigate_pages.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';
import '../themes/theme_provider.dart';

/*
SETTINGS PAGE (Supabase Ready)

Features:
- Dark mode toggle
- Blocked users list
- Account settings
- Logout (with loading overlay and success feedback)
- Avoids layout overflow / yellow lines
*/

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Auth Service
  final AuthService _auth = AuthService(); // Auth logic

  // Database provider
  // late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false,);

  /// Handles logout via AuthService
  Future<void> logout() async {
    showLoadingCircle(context, message: "Logging out...");

    try {
      // Logout from Supabase
      await _auth.logout();

      // if(mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);


      // Clear any cached user data in provider

      // databaseProvider.clearAllCachedData();

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );
        hideLoadingCircle(context);
      }

      // AuthGate will detect session change automatically
    } catch (e) {
      if (mounted) {
        hideLoadingCircle(context);
        // Show error dialog if logout fails
        showErrorDialog(e.toString());
      }
    }
  }

  /// Shows a simple error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Error'),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final databaseProvider = Provider.of<DatabaseProvider>(
      context,
      listen: false,
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,

          // Body
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Prevents full-height overflow
                  children: [
                    // Dark mode toggle
                    MySettingsTile(
                      title: "Dark Mode",
                      onTap: CupertinoSwitch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                      ),
                    ),

                    // Blocked users
                    MySettingsTile(
                      title: "Blocked Users",
                      onTap: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () async {
                          await databaseProvider.loadBlockedUsers();
                          goBlockedUsersPage(context);
                        },
                      ),
                    ),

                    // Account settings
                    MySettingsTile(
                      title: "Account Settings",
                      onTap: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => goAccountSettingsPage(context),
                      ),
                    ),

                    const Spacer(),

                    // Logout
                    MySettingsTile(
                      title: "Logout",
                      onTap: IconButton(
                        icon: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: logout, // Use the logout method
                      ),
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
