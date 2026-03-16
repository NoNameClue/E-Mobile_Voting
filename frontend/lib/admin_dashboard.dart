import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

import 'manage_polls.dart';
import 'manage_users.dart';
import 'manage_candidates.dart';
import 'election_result.dart';
import 'admin_live_scoreboard.dart';
import 'manage_parties.dart';
import 'candidates_registration.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  // Dynamic live values
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _deactivatedStudents = 0;
  bool _isLoadingStats = true;

  final List<String> menuItems = [
    "Dashboard",
    "Users / Account Control",
    "Manage Polls",
    "Manage Candidates",
    "Manage Parties",
    "Registration for Candidates",
    "Live Scoreboard",
    "Election Result",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserCount();
  }

  // Fetches users, explicitly excludes Admins, and counts Active vs Deactivated
  Future<void> _fetchUserCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allUsers = jsonDecode(response.body);

        int total = 0;
        int active = 0;
        int deactivated = 0;

        for (var user in allUsers) {
          // ONLY count students, completely ignore Admins
          if (user['role'] == 'Student') {
            total++;
            // Check if active (handles both boolean true and integer 1)
            if (user['is_active'] == true || user['is_active'] == 1) {
              active++;
            } else {
              deactivated++;
            }
          }
        }

        setState(() {
          _totalStudents = total;
          _activeStudents = active;
          _deactivatedStudents = deactivated;
          _isLoadingStats = false;
        });
      } else {
        print("Failed to fetch users. Status: ${response.statusCode}");
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      print("Network error: $e");
      setState(() => _isLoadingStats = false);
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clear JWT
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // --- UI COMPONENTS ---

  Widget buildSidebar(bool isDesktop) {
    return Container(
      width: 250,
      color: const Color(0xFF000B6B),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "ADMIN PANEL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < menuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedIndex == i
                              ? Colors.amber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getMenuIcon(i),
                            color: selectedIndex == i
                                ? const Color(0xFF000B6B)
                                : Colors.white70,
                          ),
                          title: Text(
                            menuItems[i],
                            style: TextStyle(
                              color: selectedIndex == i
                                  ? const Color(0xFF000B6B)
                                  : Colors.white,
                              fontWeight: selectedIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() => selectedIndex = i);
                            if (!isDesktop) Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper function to assign icons to the sidebar
  IconData _getMenuIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.how_to_vote;
      case 3:
        return Icons.person_pin;
      case 4:
        return Icons.flag;
      case 5:
        return Icons.app_registration;
      case 6:
        return Icons.bar_chart;
      case 7:
        return Icons.assignment_turned_in;
      default:
        return Icons.circle;
    }
  }

  // Enhanced Stat Card with Icons and Colors
  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                _isLoadingStats
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Button Widget
  Widget buildQuickActionButton(
    String title,
    IconData icon,
    int navigateToIndex,
    Color color,
  ) {
    return InkWell(
      onTap: () => setState(() => selectedIndex = navigateToIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The main Dashboard view
  Widget buildDashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000B6B),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Overview of the LNU Voting System",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),

          // --- STATS ROW ---
          const Text(
            "Student Demographics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              buildStatCard(
                "Total Registered\nStudents",
                _totalStudents.toString(),
                Icons.groups,
                Colors.blue,
              ),
              buildStatCard(
                "Active\nAccounts",
                _activeStudents.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              buildStatCard(
                "Deactivated\nAccounts",
                _deactivatedStudents.toString(),
                Icons.block,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 30),

          // --- QUICK ACTIONS ROW ---
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              buildQuickActionButton(
                "Create New\nElection Poll",
                Icons.add_chart,
                2,
                const Color(0xFF000B6B),
              ),
              buildQuickActionButton(
                "Register\nCandidate",
                Icons.person_add,
                5,
                Colors.amber.shade700,
              ),
              buildQuickActionButton(
                "Manage\nUser Accounts",
                Icons.manage_accounts,
                1,
                Colors.teal,
              ),
              buildQuickActionButton(
                "View Live\nScoreboard",
                Icons.live_tv,
                6,
                Colors.deepPurple,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // --- SYSTEM STATUS BANNER ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "System Status: Online & Secure",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "The backend server is successfully connected. Database queries are running normally.",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page Routing
  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return buildDashboardHome();
      case 1:
        return const ManageUsers();
      case 2:
        return const ManagePolls();
      case 3:
        return const ManageCandidates();
      case 4:
        return const ManageParties();
      case 5:
        return const CandidatesRegistration();
      case 6:
        return const AdminLiveScoreboard();
      case 7:
        return const ElectionResultPage();
      default:
        return buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF000B6B),
              title: const Text("Admin Panel"),
            ),
      drawer: isDesktop ? null : Drawer(child: buildSidebar(false)),
      body: Row(
        children: [
          if (isDesktop) buildSidebar(true),
          Expanded(child: buildContent()),
        ],
      ),
    );
  }
}
