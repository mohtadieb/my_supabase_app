/*
AUTHENTICATION SERVICE (Supabase Version)

Handles all authentication logic with Supabase:
- Login
- Register
- Logout
- Delete account (requires password confirmation)
*/

import 'package:my_supabase_app/services/database/database_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_service.dart';

class AuthService {
  final _auth = Supabase.instance.client.auth;
  final DatabaseService _db = DatabaseService(); // ✅ Use service, not provider

  /* ==================== CURRENT USER ==================== */
  User? getCurrentUser() => _auth.currentUser;
  String getCurrentUserId() => _auth.currentUser!.id;

  /* ==================== LOGIN / REGISTER ==================== */

  /// Login using email/password
  Future<AuthResponse> loginEmailPassword(String email, String password) async {

    // Attempt login
    try {
      final authResponse = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.session == null) {
        throw Exception("Login failed.");
      }
      return authResponse;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Register new user
  Future<AuthResponse> registerEmailPassword(String email, String password) async {
    try {
      // 1️⃣ Sign up user
      final authResponse = await _auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) throw Exception("Registration failed.");


      // // 3️⃣ Sign in automatically
      // await _auth.signInWithPassword(
      //   email: email,
      //   password: password,
      // );

      return authResponse;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }


  /* ==================== LOGOUT ==================== */
  Future<void> logout() async {
    try {
      await _auth.signOut();
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
      final res = await _auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      if (res.session == null) {
        throw Exception("Invalid password.");
      }

      // 2️⃣ Delete all user data
      await _db.deleteUser(user.id);
      // await user.delete();

      // 3️⃣ Delete Supabase auth user
      // Supabase does not provide direct deletion via client SDK
      // Workaround: Use admin API key on your backend to delete the user
      // For now, log out user
      // await logout();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print("Error deleting account: $e");
      rethrow;
    }
  }
}