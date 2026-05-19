import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'party_application_form.dart'; // 🛠️ ADDED: Import the new application form

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
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000B6B),
          primary: const Color(0xFF000B6B), 
          secondary: Colors.amber,          
          surface: Colors.white,            
          background: const Color(0xFFE5E5E5), 
        ),
        primaryColor: const Color(0xFF000B6B),
        scaffoldBackgroundColor: const Color(0xFFE5E5E5), 
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/student_dashboard': (context) => const StudentDashboard(),     
        '/admin_dashboard': (context) => const AdminDashboard(), 
        
        // 🛠️ ADDED: Registered the new route for the candidacy form
        '/file_party': (context) => const PartyApplicationForm(), 
      },
      debugShowCheckedModeBanner: false,
    );
  }
}