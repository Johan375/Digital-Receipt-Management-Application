// lib/admin_service.dart

import 'package:firebase_auth/firebase_auth.dart';

// lib/services/admin_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  // Singleton Pattern
  static final AdminService instance = AdminService._internal();
  factory AdminService() => instance;
  AdminService._internal();

  Future<bool> checkAdminStatus() async {
    // FIX: Use FirebaseAuth.instance directly instead of _auth
    final user = FirebaseAuth.instance.currentUser;

    // 1. Check if user is logged in
    if (user == null) {
      return false;
    }

    // --- DEVELOPER OVERRIDE ---
    // Replace with your actual email
    if (user.email == "akmalhakimakmalhakim91@gmail.com") {
      return true;
    }
    // --------------------------

    try {
      final idTokenResult = await user.getIdTokenResult(true);
      final isAdminClaim = idTokenResult.claims?['admin'] ?? false;
      return isAdminClaim == true;
    } catch (e) {
      return false;
    }
  }
}