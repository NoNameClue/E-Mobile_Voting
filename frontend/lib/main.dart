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