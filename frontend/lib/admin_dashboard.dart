import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'widgets/realtime_clock.dart';
import 'widgets/system_background.dart';

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
  String? _selectedMenuString = "Dashboard";

  int _totalStudents = 0;
  int _activeStudents = 0;
  int _deactivatedStudents = 0;
  bool _isLoadingStats = true;

  String _userRole = "Admin";
  List<String> _userPermissions = [];
  String _userName = "Loading...";
  String _userId = "";
  String? _profilePicUrl;

  final List<String> _masterMenuItems = [
    "Dashboard",
    "Users / Account Control",
    "Manage Election Staff", // 🛠️ Fixed exact string
    "Manage Polls",
    "Manage Candidates",
    "Manage Parties",
    "Registration for Candidates",
    "Live Scoreboard",
    "Election Result",
  ];

  List<String> displayMenuItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserAccess();
    _fetchUserProfile(); 
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
          if (item == "Manage Election Staff") return false; // 🛠️ Staff cannot manage other staff
          if (item == "Dashboard") return true; 
          // Note: If old database records say "Manage Election Officers", we map it safely
          if (_userPermissions.contains("Manage Election Officers") && item == "Manage Election Staff") return true;
          return _userPermissions.contains(item);
        }).toList();
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['full_name'] ?? (_userRole == 'Admin' ? 'Admin' : 'Staff');
            _userId = data['student_number'] ?? '';
            _profilePicUrl = data['profile_pic_url'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = _userRole;
        });
      }
    }
  }

  Future<void> _fetchUserCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? ''; 

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
          if (user['role'] == 'Student') {
            total++;
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
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); 
    await prefs.remove('role'); 
    await prefs.remove('permissions'); 
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildSidebar(bool isDesktop) {
    return Container(
      width: 250,
      color: const Color(0xFF000B6B),
      child: Column(
        children: [
          const SizedBox(height: 30),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            child: Row(
              children: [
                Container(
                  width: 50, 
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/lnu_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leyte Normal University',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(System Name)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 35),

          Text(
            _userRole == "Staff" ? "STAFF PANEL" : "ADMIN PANEL",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          
          const SizedBox(height: 35),

          Transform.scale(
            scale: 0.80, 
            child: const RealtimeClock(textColor: Colors.white, isCenterAligned: true),
          ),
          
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 1),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < displayMenuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0, 
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
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -4), 
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                          leading: Icon(
                            _getMenuIcon(displayMenuItems[i]),
                            size: 20, 
                            color: _selectedMenuString == displayMenuItems[i]
                                ? const Color(0xFF000B6B)
                                : Colors.white70,
                          ),
                          title: Text(
                            displayMenuItems[i],
                            style: TextStyle(
                              fontSize: 13, 
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

          const Divider(color: Colors.white24, height: 1),
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4), 
            leading: const Icon(Icons.logout, color: Colors.white, size: 20),
            title: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 13)),
            onTap: logout,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  IconData _getMenuIcon(String title) {
    switch (title) {
      case "Dashboard": return Icons.dashboard;
      case "Users / Account Control": return Icons.people;
      case "Manage Election Staff": return Icons.admin_panel_settings; // 🛠️ Updated Icon Mapping
      case "Manage Polls": return Icons.how_to_vote;
      case "Manage Candidates": return Icons.person_pin;
      case "Manage Parties": return Icons.flag;
      case "Registration for Candidates": return Icons.app_registration;
      case "Live Scoreboard": return Icons.bar_chart;
      case "Election Result": return Icons.assignment_turned_in;
      default: return Icons.circle;
    }
  }

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

  Widget buildQuickActionButton(
    String title,
    IconData icon,
    String navigateToTitle,
    Color color,
  ) {
    return InkWell(
      onTap: () {
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Overview of the LNU Voting System",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),

          const Text(
            "Student Demographics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.9),
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
                        style: TextStyle(color: Colors.black87, fontSize: 13),
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

  Widget buildContent() {
    switch (_selectedMenuString) {
      case "Dashboard": return buildDashboardHome();
      case "Users / Account Control": return const ManageUsers();
      case "Manage Election Staff": return const ManageStaffs(); // 🛠️ Fixed String Mapping!
      case "Manage Polls": return const ManagePolls();
      case "Manage Candidates": return const ManageCandidates();
      case "Manage Parties": return const ManageParties();
      case "Registration for Candidates": return const CandidatesRegistration();
      case "Live Scoreboard": return const AdminLiveScoreboard();
      case "Election Result": return const ElectionResultPage();
      default: return buildDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF000B6B),
              foregroundColor: Colors.white, 
              title: const Text("Admin Panel", style: TextStyle(color: Colors.white)),
            ),
      drawer: isDesktop ? null : Drawer(child: buildSidebar(false)),
      body: SystemBackground(
        opacity: 1.0,           
        darkenOverlay: 0.70,   
        isFrosted: true, 
        child: Row(
          children: [
            if (isDesktop) buildSidebar(true),
            Expanded(child: buildContent()),
          ],
        ),
      ),
    );
  }
}