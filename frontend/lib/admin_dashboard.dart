import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

import 'manage_staffs.dart';
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
  // Navigation State
  String? _selectedMenuString = "Dashboard";

  // Dynamic live values
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _deactivatedStudents = 0;
  bool _isLoadingStats = true;

  // RBAC State
  String _userRole = "Admin";
  List<String> _userPermissions = [];

  // Master list of all possible screens
  final List<String> _masterMenuItems = [
    "Dashboard",
    "Users / Account Control",
    "Manage Election Officers", // Master Admin Only
    "Manage Polls",
    "Manage Candidates",
    "Manage Parties",
    "Registration for Candidates",
    "Live Scoreboard",
    "Election Result",
  ];

  // The dynamically generated list shown to the user
  List<String> displayMenuItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserAccess();
    _fetchUserCount();
  }

  Future<void> _loadUserAccess() async {
    final prefs = await SharedPreferences.getInstance();
    
    _userRole = prefs.getString('role') ?? "Admin"; 
    
    String permsString = prefs.getString('permissions') ?? "[]";
    _userPermissions = List<String>.from(jsonDecode(permsString));

    setState(() {
      if (_userRole == "Admin") {
        displayMenuItems = List.from(_masterMenuItems);
      } else if (_userRole == "Staff") {
        displayMenuItems = _masterMenuItems.where((item) {
          if (item == "Manage Election Officers") return false; // Strictly restricted
          if (item == "Dashboard") return true; // Always allow dashboard view
          return _userPermissions.contains(item);
        }).toList();
      }
    });
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
          // ONLY count students, completely ignore Admins/Staff
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
          Text(
            _userRole == "Staff" ? "STAFF PANEL" : "ADMIN PANEL",
            style: const TextStyle(
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
                  for (int i = 0; i < displayMenuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedMenuString == displayMenuItems[i]
                              ? Colors.amber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getMenuIcon(displayMenuItems[i]),
                            color: _selectedMenuString == displayMenuItems[i]
                                ? const Color(0xFF000B6B)
                                : Colors.white70,
                          ),
                          title: Text(
                            displayMenuItems[i],
                            style: TextStyle(
                              color: _selectedMenuString == displayMenuItems[i]
                                  ? const Color(0xFF000B6B)
                                  : Colors.white,
                              fontWeight: _selectedMenuString == displayMenuItems[i]
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedMenuString = displayMenuItems[i]);
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

  // Changed to accept string so icons don't mix up when list is filtered
  IconData _getMenuIcon(String title) {
    switch (title) {
      case "Dashboard":
        return Icons.dashboard;
      case "Users / Account Control":
        return Icons.people;
      case "Manage Election Officers":
        return Icons.security; 
      case "Manage Polls":
        return Icons.how_to_vote;
      case "Manage Candidates":
        return Icons.person_pin;
      case "Manage Parties":
        return Icons.flag;
      case "Registration for Candidates":
        return Icons.app_registration;
      case "Live Scoreboard":
        return Icons.bar_chart;
      case "Election Result":
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
    String navigateToTitle,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // Only allow navigation if they have permission for that panel
        if (displayMenuItems.contains(navigateToTitle)) {
          setState(() => _selectedMenuString = navigateToTitle);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("You do not have permission to access this module.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
           );
        }
      },
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
                "Manage Polls",
                const Color(0xFF000B6B),
              ),
              buildQuickActionButton(
                "Register\nCandidate",
                Icons.person_add,
                "Registration for Candidates",
                Colors.amber.shade700,
              ),
              buildQuickActionButton(
                "Manage\nUser Accounts",
                Icons.manage_accounts,
                "Users / Account Control",
                Colors.teal,
              ),
              buildQuickActionButton(
                "View Live\nScoreboard",
                Icons.live_tv,
                "Live Scoreboard",
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
    switch (_selectedMenuString) {
      case "Dashboard":
        return buildDashboardHome();
      case "Users / Account Control":
        return const ManageUsers();
      case "Manage Election Officers":
        return const ManageStaffs(); 
      case "Manage Polls":
        return const ManagePolls();
      case "Manage Candidates":
        return const ManageCandidates();
      case "Manage Parties":
        return const ManageParties();
      case "Registration for Candidates":
        return const CandidatesRegistration();
      case "Live Scoreboard":
        return const AdminLiveScoreboard();
      case "Election Result":
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
              title: const Text("Admin Panel", style: TextStyle(color: Colors.white)),
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