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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _selectedMenuString = "Dashboard";
  final Color sidebarBgColor = const Color(0xFF000B6B); // LNU Blue

  int _totalStudents = 0;
  int _activeStudents = 0;
  int _deactivatedStudents = 0;
  bool _isLoadingStats = true;

  String _userRole = "Admin";
  List<String> _userPermissions = [];
  String _userName = "Loading...";
  String _userId = "";
  String? _profilePicUrl;
  
  Map<String, dynamic>? _mostRecentPollData;
  bool _isLoadingRecentPoll = true; 
  bool _hasActivePoll = false;
  bool _shownLoginSnack = false;
  
  // Sidebar State
  bool _isSidebarExpanded = true;

  final List<String> _masterMenuItems = [
    "Dashboard",
    "Live Scoreboard",
    "Election Result",
    "Manage Polls",
    "Manage Candidates",
    "Manage Parties",
    "Users / Account Control",
    "Manage Election Staff", 
  ];

  List<String> displayMenuItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserAccess();
    _fetchUserProfile(); 
    _fetchUserCount();
    _fetchRecentPolls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_shownLoginSnack) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    if (args != null && args['loginSuccess'] == true) {
      _shownLoginSnack = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Successful"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  Future<void> _loadUserAccess() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('role') ?? "Admin"; 
    String permsString = prefs.getString('permissions') ?? "[]";
    _userPermissions = List<String>.from(jsonDecode(permsString));
    _updateMenu(); 
  }

  void _updateMenu() {
    if (!mounted) return;
    setState(() {
      if (_userRole == "Admin") {
        displayMenuItems = _masterMenuItems.where((item) {
          if (item == "Live Scoreboard" && !_hasActivePoll) return false;
          return true;
        }).toList();
      } else if (_userRole == "Staff") {
        displayMenuItems = _masterMenuItems.where((item) {
          if (item == "Manage Election Staff") return _userPermissions.contains("Manage Election Officers");
          if (item == "Dashboard") return true;
          if (item == "Live Scoreboard" && !_hasActivePoll) return false;
          return _userPermissions.contains(item);
        }).toList();
      }

      if (!_hasActivePoll && _selectedMenuString == "Live Scoreboard") {
        _selectedMenuString = "Dashboard";
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
      if (mounted) setState(() => _userName = _userRole);
    }
  }

  Future<void> _fetchUserCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? ''; 
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
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

  Future<void> _fetchRecentPolls() async {
    setState(() => _isLoadingRecentPoll = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final List<dynamic> allPolls = jsonDecode(response.body);
        bool hasActive = allPolls.any((poll) => poll['status'] == 'Active');
        _hasActivePoll = hasActive;
        _updateMenu();

        final recent = allPolls.where((poll) => poll['status'] == 'Ended' || poll['status'] == 'Expired').toList();
        if (recent.isNotEmpty) {
          recent.sort((a, b) {
            DateTime dateA = DateTime.tryParse(a['end_time'] ?? a['start_time'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            DateTime dateB = DateTime.tryParse(b['end_time'] ?? b['start_time'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });
          
          final latestPoll = recent.first;
          final reportRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/${latestPoll['poll_id']}/report'));
          
          if (reportRes.statusCode == 200) {
            setState(() {
              _mostRecentPollData = {'poll': latestPoll, 'report': jsonDecode(reportRes.body)};
              _isLoadingRecentPoll = false;
            });
          } else {
            setState(() => _isLoadingRecentPoll = false);
          }
        } else {
          setState(() { _mostRecentPollData = null; _isLoadingRecentPoll = false; });
        }
      } else {
        setState(() => _isLoadingRecentPoll = false);
      }
    } catch (e) {
      setState(() => _isLoadingRecentPoll = false);
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

  void _showPollDetailsDialog() {
    if (_mostRecentPollData == null) return;
    final poll = _mostRecentPollData!['poll'];
    final report = _mostRecentPollData!['report'];
    final summary = report['summary'];
    final results = report['results'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF000B6B), 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.amber, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Final Election Report", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          Text(poll['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
                              child: Column(
                                children: [
                                  const Text("Voter Turnout", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text("${summary['turnout_percentage']}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade100)),
                              child: Column(
                                children: [
                                  const Text("Total Votes Cast", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text("${summary['total_voters']} / ${summary['total_active_students']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text("Winning Margins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 10),
                      ...results.map((posData) {
                        final candidates = posData['candidates'] as List<dynamic>;
                        final winner = candidates.firstWhere((c) => c['is_winner'] == true, orElse: () => null);
                        if (winner == null) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8), 
                                decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle), 
                                child: const Icon(Icons.emoji_events, color: Colors.orange, size: 20)
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(posData['position'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    Text("${winner['name']} (${winner['party_name']})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${winner['votes']} Votes", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text("Won by +${winner['margin']}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRecentPollsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Latest Election Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        
        if (_isLoadingRecentPoll) 
          const Center(child: CircularProgressIndicator(color: Colors.amber)),
          
        if (!_isLoadingRecentPoll && _mostRecentPollData == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
            child: const Center(child: Text("No recent polls have ended yet.", style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic))),
          ),
          
        if (!_isLoadingRecentPoll && _mostRecentPollData != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
                            child: const Text("ENDED", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 8),
                          Text(_mostRecentPollData!['poll']['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      icon: const Icon(Icons.insights, size: 18),
                      label: const Text("See more details"),
                      onPressed: _showPollDetailsDialog,
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                const Text("Elected Officials Overview", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  children: (_mostRecentPollData!['report']['results'] as List<dynamic>).map((posData) {
                    final candidates = posData['candidates'] as List<dynamic>;
                    final winner = candidates.firstWhere((c) => c['is_winner'] == true, orElse: () => null);
                    if (winner == null) return const SizedBox.shrink();
                    return SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(posData['position'], style: const TextStyle(fontSize: 12, color: Colors.black)),
                                Text(winner['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getMenuIcon(String title) {
    switch (title) {
      case "Dashboard": return Icons.dashboard;
      case "Users / Account Control": return Icons.people;
      case "Manage Election Staff": return Icons.admin_panel_settings; 
      case "Manage Polls": return Icons.how_to_vote;
      case "Manage Candidates": return Icons.folder; 
      case "Manage Parties": return Icons.flag;
      case "Live Scoreboard": return Icons.insert_chart; 
      case "Election Result": return Icons.analytics;
      default: return Icons.circle;
    }
  }

  String _getCategory(String menu) {
    if (["Dashboard", "Live Scoreboard", "Election Result"].contains(menu)) return "Main Menu";
    if (["Manage Polls", "Manage Candidates", "Manage Parties"].contains(menu)) return "Management";
    if (["Users / Account Control", "Manage Election Staff"].contains(menu)) return "Account";
    return "Menu";
  }

  Widget _buildCategoryHeader(String title) {
    return _isSidebarExpanded
        ? Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, bottom: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 1, width: 30, color: Colors.white24),
          );
  }

  Widget _buildMenuItem(String title, IconData icon, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 15 : 0, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : Colors.transparent, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? sidebarBgColor : Colors.white70,
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? sidebarBgColor : Colors.white,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSidebar(bool isDesktop) {
    double currentWidth = _isSidebarExpanded ? 260.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isDesktop ? currentWidth : 260.0,
      color: sidebarBgColor,
      child: Column(
        children: [
          // 1. Logo & Toggle Header
          InkWell(
            onTap: isDesktop ? () => setState(() => _isSidebarExpanded = !_isSidebarExpanded) : null,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/lnu_logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "LNU Admin",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // 2. Menu Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  ...() {
                    List<Widget> widgets = [];
                    String currentCategory = "";

                    for (int i = 0; i < displayMenuItems.length; i++) {
                      String category = _getCategory(displayMenuItems[i]);
                      if (category != currentCategory) {
                        widgets.add(_buildCategoryHeader(category));
                        currentCategory = category;
                      }
                      widgets.add(_buildMenuItem(
                        displayMenuItems[i],
                        _getMenuIcon(displayMenuItems[i]),
                        _selectedMenuString == displayMenuItems[i],
                        () {
                          setState(() => _selectedMenuString = displayMenuItems[i]);
                          if (!isDesktop) Navigator.pop(context);
                        },
                      ));
                    }
                    
                    // Add System/Logout category at end
                    widgets.add(_buildCategoryHeader("System"));
                    widgets.add(_buildMenuItem("Logout", Icons.logout, false, logout));
                    
                    return widgets;
                  }(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. Profile Bottom Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.all(_isSidebarExpanded ? 10 : 5),
            decoration: BoxDecoration(
              color: _isSidebarExpanded ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: _isSidebarExpanded ? 18 : 20,
                  backgroundColor: _isSidebarExpanded ? Colors.white24 : Colors.white24,
                  backgroundImage: _profilePicUrl != null ? NetworkImage('${ApiConfig.baseUrl}/$_profilePicUrl') : null,
                  child: _profilePicUrl == null ? Icon(Icons.person, size: 20, color: Colors.white) : null,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _userRole == "Staff" ? "Staff Member" : "Administrator",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (_isSidebarExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Transform.scale(
                scale: 0.8,
                child: const RealtimeClock(textColor: Colors.white54, isCenterAligned: true),
              ),
            )
        ],
      ),
    );
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade200), 
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: isMobile 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
                child: Icon(icon, size: 24, color: color)
              ),
              const SizedBox(height: 10),
              _isLoadingStats 
                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2)) 
                : Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15), 
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
                child: Icon(icon, size: 30, color: color)
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    _isLoadingStats 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget buildQuickActionButton(BuildContext context, String title, IconData icon, String navigateToTitle, Color color, bool isMobile) {
    bool isLocked = navigateToTitle == "Live Scoreboard" && !_hasActivePoll;
    double cardWidth = isMobile ? (MediaQuery.of(context).size.width - 90) / 2 : 160;
    
    return InkWell(
      onTap: isLocked 
        ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No active elections available for Live Scoreboard.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange))
        : () {
            if (displayMenuItems.contains(navigateToTitle)) {
              setState(() => _selectedMenuString = navigateToTitle);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You do not have permission to access this module.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
            }
          },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: cardWidth, 
        padding: EdgeInsets.all(isMobile ? 15 : 20),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade400 : color, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [BoxShadow(color: (isLocked ? Colors.grey : color).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Column(
          children: [
            Icon(icon, size: isMobile ? 30 : 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardHome() {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "System Dashboard",
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "Online",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Overview of the LNU Voting System", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),
          
          const Text("Student Demographics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(
                child: buildStatCard(
                  "Total Registered\nStudents",
                  _totalStudents.toString(),
                  Icons.groups,
                  Colors.blue,
                  isMobile
                ),
              ),
              SizedBox(width: isMobile ? 10 : 15),

              Expanded(
                child: buildStatCard(
                  "Active\nAccounts",
                  _activeStudents.toString(),
                  Icons.check_circle,
                  Colors.green,
                  isMobile
                ),
              ),
              SizedBox(width: isMobile ? 10 : 15),

              Expanded(
                child: buildStatCard(
                  "Deactivated\nAccounts",
                  _deactivatedStudents.toString(),
                  Icons.block,
                  Colors.red,
                  isMobile
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 30),
          
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20, 
            runSpacing: 20,
            children: [
              buildQuickActionButton(context, "Create New\nElection Poll", Icons.add_chart, "Manage Polls", const Color(0xFF000B6B), isMobile),
              buildQuickActionButton(context, "Manage\nCandidates", Icons.how_to_reg, "Manage Candidates", Colors.amber.shade700, isMobile),
              buildQuickActionButton(context, "Manage\nUser Accounts", Icons.manage_accounts, "Users / Account Control", const Color(0xFF000B6B), isMobile),
              buildQuickActionButton(context, "View Live\nScoreboard", Icons.live_tv, "Live Scoreboard", Colors.amber.shade700, isMobile), 
            ],
          ),
          
          const SizedBox(height: 40),
          buildRecentPollsWidget(),
        ],
      ),
    );
  }

  Widget buildContent() {
    switch (_selectedMenuString) {
      case "Dashboard": return buildDashboardHome();
      case "Users / Account Control": return const ManageUsers();
      case "Manage Election Staff": return const ManageStaffs(); 
      case "Manage Polls": return const ManagePolls();
      case "Manage Candidates": return const ManageCandidates();
      case "Manage Parties": return const ManageParties();
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
            backgroundColor: sidebarBgColor, 
            foregroundColor: Colors.white, 
            title: const Text("Admin Panel", style: TextStyle(color: Colors.white))
          ),
      drawer: isDesktop ? null : Drawer(child: buildSidebar(false)),
      body: SystemBackground(
        opacity: 1.0, 
        darkenOverlay: 0.70, 
        isFrosted: true, 
        child: Row(
          children: [
            if (isDesktop) buildSidebar(true), 
            Expanded(child: buildContent())
          ]
        ),
      ),
    );
  }
}