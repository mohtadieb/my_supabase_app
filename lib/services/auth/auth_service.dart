/*
AUTHENTICATION SERVICE (Supabase Version)

Handles all authentication logic with Supabase:
- Login
- Register
- Logout
- Delete account (requires password confirmation)
*/

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_service.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();

  /* ==================== CURRENT USER ==================== */
  User? getCurrentUser() => supabase.auth.currentUser;
  String getCurrentUid() => supabase.auth.currentUser?.id ?? '';

  /* ==================== LOGIN / REGISTER ==================== */

  /// Login using email/password
  Future<void> loginEmailPassword(String email, String password) async {
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null) {
        throw Exception("Login failed.");
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Register new user
  // Future<void> registerEmailPassword(String email, String password, String name) async {
  //   try {
  //     final res = await supabase.auth.signUp(
  //       email: email,
  //       password: password,
  //     );
  //
  //     if (res.user == null) throw Exception("Registration failed.");
  //
  //     // Save user info to Supabase profiles table
  //     await _dbService.saveUserInfo(name: name, email: email, userId: res.user!.id);
  //   } on AuthException catch (e) {
  //     throw Exception(e.message);
  //   }
  // }

  Future<void> registerEmailPassword(String email, String password, String name) async {
    try {
      // 1️⃣ Sign up user
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) throw Exception("Registration failed.");

      // 2️⃣ Save user info to 'profiles' table
      await _db.saveUserInfo(
        name: name,
        email: email, userId: res.user!.id,
      );

      // 3️⃣ Sign in automatically
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }


  /* ==================== LOGOUT ==================== */
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      print("User logged out successfully.");
    } catch (e) {
      print("Logout error: $e");
      rethrow;
    }
  }

  /* ==================== DELETE ACCOUNT WITH PASSWORD ==================== */
  Future<void> deleteAccountWithPassword(String password) async {
    final user = getCurrentUser();
    if (user == null || user.email == null) {
      throw Exception("No logged-in user.");
    }

    try {
      // 1️⃣ Re-authenticate the user using Supabase signIn
      final res = await supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      if (res.session == null) {
        throw Exception("Invalid password.");
      }

      // 2️⃣ Delete all user data via DatabaseService
      await _db.deleteUser(user.id);

      // 3️⃣ Delete Supabase auth user
      // Supabase does not provide direct deletion via client SDK
      // Workaround: Use admin API key on your backend to delete the user
      // For now, log out user
      await logout();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print("Error deleting account: $e");
      rethrow;
    }
  }
}