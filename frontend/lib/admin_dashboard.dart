import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel"), backgroundColor: Colors.red[900]),
      body: const Center(
        child: Text("Welcome Admin! Manage your elections here.", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}