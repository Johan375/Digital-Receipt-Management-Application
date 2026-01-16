import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:financetrack/config/firebase_options.dart';
import 'package:financetrack/pages/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // REMOVED: await dotenv.load(fileName: ".env");
  // We no longer need this line since we removed Gemini AI.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceTrack', // Updated Title
      theme: ThemeData(
        // Updated Color Scheme to match your new branding
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E3192)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const CustomSplashScreen(),
    );
  }
}