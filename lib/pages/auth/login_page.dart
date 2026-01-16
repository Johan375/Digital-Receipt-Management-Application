// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. IMPORT FIRESTORE
import 'register_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance; // 2. FIRESTORE INSTANCE
  bool _isLoading = false;

  // --- VALIDATION LOGIC ---
  static const List<String> _disposableDomains = [
    'mailinator.com', 'tempmail.com', '10minutemail.com',
    'yopmail.com', 'fake-email.com', 'binkmail.com',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email.';
    final email = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email format.';
    
    final domain = email.substring(email.indexOf('@') + 1).toLowerCase();
    if (_disposableDomains.contains(domain)) return 'Disposable emails not allowed.';
    
    return null; 
  }

  // --- AUTH ACTIONS ---
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      // 1. Attempt Standard Login
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      User? user = userCredential.user;

      if (user != null) {
        // 2. IMPORTANT: Reload user to get the freshest 'emailVerified' status
        await user.reload();
        user = _auth.currentUser; // Update the local user object

        if (user == null) return; // Safety check

        // 3. CHECK IF USER IS BANNED
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final bool isBanned = userData['isBanned'] ?? false;

          if (isBanned) {
            await _auth.signOut();
            _showSnackbar('Access Denied: Your account has been banned.', color: Colors.red);
            return; 
          }
        }

        // 4. CHECK EMAIL VERIFICATION WITH 5-MINUTE TIMER
        if (!user.emailVerified) {
          
          // Calculate time since registration
          final creationTime = user.metadata.creationTime ?? DateTime.now();
          final timeDifference = DateTime.now().difference(creationTime);
          final minutesPassed = timeDifference.inMinutes;

          if (minutesPassed >= 5) {
            // --- SCENARIO A: TIME EXPIRED (Delete Account) ---
            
            // Delete Firestore Data first (while we still have permission)
            if (userDoc.exists) {
              await _firestore.collection('users').doc(user.uid).delete();
            }
            
            // Delete Auth Account
            await user.delete();
            await _auth.signOut();

            _showSnackbar(
              'Verification timed out (5 min limit). Account deleted. Please register again.', 
              color: Colors.red
            );
            return;

          } else {
            // --- SCENARIO B: STILL HAS TIME ---
            await _auth.signOut();
            final minutesLeft = 5 - minutesPassed;
            _showSnackbar(
              'Email not verified. You have $minutesLeft minutes left to verify.', 
              color: Colors.orange
            );
            return;
          }
        }
      }

      // If we get here: User is Valid, Not Banned, and Verified.
      // Navigation is handled by StreamBuilder in main.dart
      
    } on FirebaseAuthException catch (e) {
      String message = (e.code == 'user-not-found' || e.code == 'wrong-password')
          ? 'Invalid email or password.'
          : e.message ?? 'Login failed.';
      _showSnackbar(message);
    } catch (e) {
      _showSnackbar('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController recoveryEmailController = TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Reset Password'),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a reset link.'),
              const SizedBox(height: 15),
              TextFormField(
                controller: recoveryEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration('Email', Icons.email),
                validator: _emailValidator,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                final email = recoveryEmailController.text.trim();
                Navigator.pop(dialogContext);
                try {
                  await _auth.sendPasswordResetEmail(email: email);
                  _showSnackbar('Reset link sent to $email', color: Colors.green);
                } on FirebaseAuthException catch (e) {
                  _showSnackbar(e.message ?? 'Failed to send email.');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: Matches Dashboard Inputs ---
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.grey[50], // Soft gray background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('FinanceTrack', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Hero(
                tag: 'logo', // Use a Hero tag for a smooth transition from splash
                child: Image.asset(
                  'assets/logo.png',
                  height: 100, // Adjust size as needed
                ),
              ),
              
              const SizedBox(height: 20), // Space between logo and text

              // Header Text
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w800, 
                  color: primaryColor,
                  letterSpacing: 0.5
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your receipts',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 30),
              
              // Login Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _buildInputDecoration('Password', Icons.lock_outline),
                        validator: (value) => (value == null || value.isEmpty) 
                            ? 'Please enter your password.' : null,
                      ),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: _navigateToRegister,
                    child: Text(
                      'Create One',
                      style: TextStyle(
                        color: primaryColor, 
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}