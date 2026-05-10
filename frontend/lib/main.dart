import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

void main() {
  runApp(const LnuVotingApp());
}

class LnuVotingApp extends StatelessWidget {
  const LnuVotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LNU Voting System',
      theme: ThemeData(
        // 🛠️ TICKET 1: Enforces modern Material 3 UI globally
        useMaterial3: true, 
        
        // 🛠️ TICKET 1: Strict 5-Color LNU Palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000B6B),
          primary: const Color(0xFF000B6B), // LNU Blue
          secondary: Colors.amber,          // LNU Gold
          surface: Colors.white,            // Clean white for cards/modals
          background: const Color(0xFFE5E5E5), // Frosted/System background base
        ),
        
        primaryColor: const Color(0xFF000B6B),
        scaffoldBackgroundColor: const Color(0xFFE5E5E5), 
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/student_home': (context) => const StudentDashboard(),     
        '/admin_dashboard': (context) => const AdminDashboard(), 
      },
      debugShowCheckedModeBanner: false,
    );
  }
}