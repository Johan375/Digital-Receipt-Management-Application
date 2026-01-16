// lib/manage_users_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  final String currentAdminId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // --- LOGIC: TOGGLE BAN ---
  Future<void> _toggleBanStatus(String userId, bool currentStatus) async {
    // (Double safety check is still good to keep)
    if (userId == currentAdminId) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': !currentStatus,
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? "User Unbanned" : "User Banned"),
            backgroundColor: currentStatus ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- HELPER: CARD STYLE ---
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userId = docs[index].id;
              
              final email = data['email'] ?? 'No Email';
              final role = data['role'] ?? 'user';
              final bool isBanned = data['isBanned'] ?? false;
              
              // --- 1. IDENTIFY ADMINS ---
              final bool isTargetAdmin = (role == 'admin');
              final bool isCurrentUser = (userId == currentAdminId);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  
                  // Leading Icon
                  leading: CircleAvatar(
                    backgroundColor: isBanned 
                        ? Colors.red.withOpacity(0.1) 
                        : (isTargetAdmin ? Colors.orange.withOpacity(0.1) : primaryColor.withOpacity(0.1)),
                    child: Icon(
                      isBanned ? Icons.block : (isTargetAdmin ? Icons.shield : Icons.person),
                      color: isBanned ? Colors.red : (isTargetAdmin ? Colors.orange : primaryColor),
                    ),
                  ),
                  
                  // Title & Subtitle
                  title: Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: isBanned ? TextDecoration.lineThrough : null,
                      color: isBanned ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    isCurrentUser ? "Role: $role (You)" : "Role: $role",
                    style: TextStyle(
                      fontSize: 12, 
                      color: isTargetAdmin ? Colors.orange[800] : Colors.grey[600],
                      fontWeight: isTargetAdmin ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  
                  // --- 2. LOCK THE SWITCH ---
                  // If they are an admin, show a 'Locked' icon or Badge.
                  // If they are a regular user, show the Switch.
                  trailing: isTargetAdmin 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withOpacity(0.3))
                        ),
                        child: const Text(
                          "Admin", 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      )
                    : Switch(
                        value: !isBanned, // Switch ON = Allowed
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.withOpacity(0.2),
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red.withOpacity(0.2),
                        onChanged: (val) => _toggleBanStatus(userId, isBanned),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}