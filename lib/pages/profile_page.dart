// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/services/admin_service.dart';
import 'package:financetrack/pages/admin/admin_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  User? _currentUser;

  // --- ADMIN STATE ---
  bool _isAdmin = false;
  bool _isLoadingAdminCheck = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser; // Initialize user
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final isAdmin = await AdminService.instance.checkAdminStatus();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingAdminCheck = false;
      });
    }
  }

  // --- LOGIC: EDIT NAME ---
  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = _currentUser?.displayName ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile Name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the name you want to appear in the app:"),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Your Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  // 1. Update Firebase Auth Profile
                  await _currentUser?.updateDisplayName(newName);

                  // 2. Refresh Local State
                  await _currentUser?.reload(); // Reloads data from server
                  final updatedUser = _auth.currentUser; // Get fresh object

                  if (mounted) {
                    setState(() {
                      _currentUser = updatedUser;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Name updated successfully!")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating name: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- LOGIC: SET BUDGET ---
  void _showBudgetDialog() {
    final TextEditingController budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: primaryColor),
            const SizedBox(width: 10),
            const Text("Set Monthly Budget"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your maximum spending limit for this month:"),
            const SizedBox(height: 15),
            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: "RM ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: "e.g. 1000.00",
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              final value = double.tryParse(budgetController.text);
              if (value != null) {
                await FirestoreService().setMonthlyBudget(value);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Budget limit saved successfully!")),
                  );
                }
              }
            },
            child: const Text("Save Limit", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isLast = false,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? primaryColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[100], indent: 70, endIndent: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get display name (or fallback to email handler)
    final String email = _currentUser?.email ?? 'No Email';
    final String name = _currentUser?.displayName ?? email.split('@').first;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. PROFILE HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ]
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 30, color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Name & Edit Icon
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // EDIT BUTTON
                            InkWell(
                              onTap: _showEditNameDialog,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 14),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 2. SETTINGS MENU
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Monthly Budget',
                      subtitle: 'Set your monthly spending limit',
                      onTap: _showBudgetDialog,
                    ),

                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile Name', // Explicit Option as well
                      subtitle: 'Change your display name',
                      onTap: _showEditNameDialog,
                    ),

                    if (!_isLoadingAdminCheck && _isAdmin)
                      _buildMenuItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin Dashboard',
                        subtitle: 'Manage users & global data',
                        iconColor: Colors.orange,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
                        },
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // 3. SUPPORT MENU
                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'About FinanceTrack',
                      subtitle: 'Version 1.0.0',
                      isLast: true,
                      onTap: () {},
                    ),
                  ]),

                  // 4. LOGOUT
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                        ),
                      ),
                      onPressed: () => _auth.signOut(),
                      child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}