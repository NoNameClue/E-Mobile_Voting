import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';
import 'voting_page.dart';
import 'my_votes_view.dart';
import 'view_parties.dart';
import 'apply_staff.dart'; 
import 'widgets/realtime_clock.dart';
import 'widgets/system_background.dart';

// ========================================================================
// 1. MAIN STUDENT DASHBOARD SHELL
// ========================================================================
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int selectedIndex = 0;
  final Color primaryColor = const Color(0xFF000B6B);
  final Color sidebarBgColor = const Color(0xFF000B6B); // LNU Blue

  String _studentName = "Loading...";
  String _studentId = "";
  String? _profilePicUrl;
  bool _shownLoginSnack = false;
  
  // Sidebar State
  bool _isSidebarExpanded = true;

  final List<String> menuItems = [
    "Home", 
    "Vote",
    "View Parties",
    "My Votes",
    "Apply for Staff", 
    "FAQs",
    "About Us",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); 
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
            _studentName = data['full_name'] ?? 'Student';
            _studentId = data['student_number'] ?? '';
            _profilePicUrl = data['profile_pic_url'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentName = "Student";
        });
      }
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  IconData _getStudentMenuIcon(String title) {
    switch (title) {
      case "Home": return Icons.dashboard; 
      case "Vote": return Icons.how_to_vote;
      case "View Parties": return Icons.groups;
      case "My Votes": return Icons.fact_check;
      case "Apply for Staff": return Icons.assignment_ind; 
      case "FAQs": return Icons.help_outline;
      case "About Us": return Icons.info_outline;
      default: return Icons.circle;
    }
  }

  String _getCategory(String menu) {
    if (["Home", "Vote"].contains(menu)) return "Main Menu";
    if (["View Parties", "My Votes", "Apply for Staff"].contains(menu)) return "General";
    if (["FAQs", "About Us"].contains(menu)) return "System";
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), // Reduced padding to fit screen
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 15 : 0, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : Colors.transparent, // LNU Yellow active state
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? primaryColor : Colors.white70,
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? primaryColor : Colors.white,
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
              height: 70, // Reduced height
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
                        "LNU Voting",
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

                    for (int i = 0; i < menuItems.length; i++) {
                      String category = _getCategory(menuItems[i]);
                      if (category != currentCategory) {
                        widgets.add(_buildCategoryHeader(category));
                        currentCategory = category;
                      }
                      widgets.add(_buildMenuItem(
                        menuItems[i],
                        _getStudentMenuIcon(menuItems[i]),
                        selectedIndex == i,
                        () {
                          setState(() => selectedIndex = i);
                          if (!isDesktop) Navigator.pop(context);
                        },
                      ));
                    }
                    
                    // Add Logout at bottom of lists
                    widgets.add(_buildCategoryHeader("Account"));
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
                          _studentName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Student",
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

  Widget buildContent() {
    switch (selectedIndex) {
      case 0: return const CandidatePlatformsView(); 
      case 1:
        return VotingPage(
          onReturnToDashboard: () {
            setState(() {
              selectedIndex = 0;
            });
          },
        );
      case 2: return const ViewParties();
      case 3: return const MyVotesView();
      case 4: return const ApplyStaffScreen(); 
      case 5: return const FAQsView();
      case 6: return const AboutUsView();
      default: return const CandidatePlatformsView();
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
              title: Text(menuItems[selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
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

// ========================================================================
// 2. CANDIDATE PLATFORMS VIEW (HOME PAGE WITH POLL FEED)
// ========================================================================
class CandidatePlatformsView extends StatefulWidget {
  const CandidatePlatformsView({super.key});

  @override
  State<CandidatePlatformsView> createState() => _CandidatePlatformsViewState();
}

class _CandidatePlatformsViewState extends State<CandidatePlatformsView> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _polls = [];

  final Color primaryColor = const Color(0xFF000B6B);
  final List<String> standardPositions = [
    "President", "Vice President", "Secretary", "Treasurer", "Auditor", "PIO"
  ];

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  bool _checkIfEnded(dynamic p) {
    bool isEnded = p['status'] == 'Ended' || p['is_archived'] == 1 || p['is_archived'] == true;
    if (p['end_time'] != null) {
      DateTime endTime = DateTime.parse(p['end_time']);
      if (endTime.isBefore(DateTime.now())) {
        isEnded = true;
      }
    }
    return isEnded;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown Date";
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return "Unknown Date";
    }
  }

  Future<void> _fetchPolls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final List<dynamic> allPolls = jsonDecode(response.body);
        
        var validPolls = allPolls.where((p) => p['is_published'] == 1 || p['is_published'] == true).toList();
        
        validPolls.sort((a, b) {
          bool aEnded = _checkIfEnded(a);
          bool bEnded = _checkIfEnded(b);
          if (aEnded == bEnded) {
            DateTime dateA = a['start_time'] != null ? DateTime.parse(a['start_time']) : DateTime(2000);
            DateTime dateB = b['start_time'] != null ? DateTime.parse(b['start_time']) : DateTime(2000);
            return dateB.compareTo(dateA);
          }
          return aEnded ? 1 : -1; 
        });

        setState(() {
          _polls = validPolls;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch polls");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not connect to the server.";
      });
    }
  }

  // --- FETCH CANDIDATES LOGIC (FOR ACTIVE POLLS) ---
  Future<void> _openCandidatesPopup(int pollId, String pollTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$pollId'));
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final List<dynamic> allCandidates = jsonDecode(response.body);
        Map<String, List<dynamic>> grouped = {};

        for (var c in allCandidates) {
          bool isWithdrawn = c['is_withdrawn'] == 1 || c['is_withdrawn'] == true;
          if (isWithdrawn) continue; 
          String pos = c['position'] ?? 'Unknown Position';
          grouped.putIfAbsent(pos, () => []).add(c);
        }

        var sortedGrouped = Map.fromEntries(
          grouped.entries.toList()..sort((a, b) {
            int indexA = standardPositions.indexOf(a.key);
            int indexB = standardPositions.indexOf(b.key);
            if (indexA == -1) indexA = 999;
            if (indexB == -1) indexB = 999;
            return indexA.compareTo(indexB);
          })
        );

        _showCandidatesModal(pollTitle, sortedGrouped);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load candidates.')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Cannot fetch candidates.')));
    }
  }

  // --- FETCH WINNERS LOGIC (FOR ENDED POLLS) ---
  Future<void> _openWinnersPopup(int pollId, String pollTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final candRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$pollId'));
      final repRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/report'));

      if (!mounted) return;
      Navigator.pop(context);

      if (candRes.statusCode == 200 && repRes.statusCode == 200) {
        final List<dynamic> allCandidates = jsonDecode(candRes.body);
        final Map<String, dynamic> reportData = jsonDecode(repRes.body);

        String normalizeName(String name) => name.replaceAll('.', '').replaceAll(' ', '').toLowerCase();
        
        Set<String> normalizedWinnerNames = {};

        if (reportData['results'] != null) {
          for (var posData in reportData['results']) {
            if (posData['candidates'] != null) {
              for (var c in posData['candidates']) {
                if (c['is_winner'] == true && c['name'] != null) {
                  normalizedWinnerNames.add(normalizeName(c['name'].toString()));
                }
              }
            }
          }
        }

        Map<String, List<dynamic>> groupedWinners = {};

        for (var c in allCandidates) {
          bool isWithdrawn = c['is_withdrawn'] == 1 || c['is_withdrawn'] == true;
          if (isWithdrawn) continue; 
          
          String firstLast = normalizeName("${c['first_name']}${c['last_name']}");
          String full = normalizeName("${c['first_name']}${c['middle_name'] ?? ''}${c['last_name']}");

          if (normalizedWinnerNames.contains(firstLast) || normalizedWinnerNames.contains(full)) {
            String pos = c['position'] ?? 'Unknown Position';
            groupedWinners.putIfAbsent(pos, () => []).add(c);
          }
        }

        var sortedGrouped = Map.fromEntries(
          groupedWinners.entries.toList()..sort((a, b) {
            int indexA = standardPositions.indexOf(a.key);
            int indexB = standardPositions.indexOf(b.key);
            if (indexA == -1) indexA = 999;
            if (indexB == -1) indexB = 999;
            return indexA.compareTo(indexB);
          })
        );

        _showWinnersModal(pollTitle, sortedGrouped);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load election winners.')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Cannot fetch winners.')));
    }
  }

  void _showWinnersModal(String pollTitle, Map<String, List<dynamic>> groupedWinners) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(isMobile ? 15 : 40),
          child: Container(
            width: 800, 
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFF000B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Election Winners", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(pollTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: groupedWinners.isEmpty
                    ? const Center(child: Text("Winners data is currently unavailable.", style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(25),
                        itemCount: groupedWinners.length,
                        itemBuilder: (context, index) {
                          String position = groupedWinners.keys.elementAt(index);
                          List<dynamic> winners = groupedWinners[position]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  position.toUpperCase(),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF000B6B), letterSpacing: 0.5),
                                ),
                                const Divider(),
                                ...winners.map((w) {
                                  String fullName = "${w['first_name']} ${w['middle_name'] ?? ''} ${w['last_name']}".replaceAll('  ', ' ').trim();
                                  String party = w['party_name'] ?? 'Independent';
                                  String course = w['course_year'] ?? 'N/A';
                                  String bio = w['description_platform'] ?? 'No platform provided.';

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(top: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: w['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${w['photo_url']}') : null,
                                            child: w['photo_url'] == null ? Icon(Icons.person, size: 45, color: Colors.grey.shade400) : null,
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(height: 2),
                                                Text("$party • $course", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                                                const SizedBox(height: 15),
                                                Text("Platform & Bio:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                                                const SizedBox(height: 5),
                                                Text(bio, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCandidatesModal(String pollTitle, Map<String, List<dynamic>> groupedCandidates) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.all(isMobile ? 15 : 40),
          child: Container(
            width: 1000, 
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFF000B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Active Candidates List", style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(pollTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: groupedCandidates.isEmpty
                    ? const Center(child: Text("No candidates assigned to this election yet.", style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(25),
                        itemCount: groupedCandidates.length,
                        itemBuilder: (context, index) {
                          String position = groupedCandidates.keys.elementAt(index);
                          List<dynamic> candidates = groupedCandidates[position]!;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 35.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Running for $position",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF000B6B), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 20, 
                                  runSpacing: 20, 
                                  children: candidates.map<Widget>((c) {
                                    String fullName = "${c['first_name']} ${c['last_name']}";
                                    String party = c['party_name'] ?? 'Independent';
                                    String course = c['course_year'] ?? '';

                                    return Container(
                                      width: 180, 
                                      height: 260,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundColor: Colors.grey.shade200,
                                              backgroundImage: c['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${c['photo_url']}') : null,
                                              child: c['photo_url'] == null ? Icon(Icons.person, size: 45, color: Colors.grey.shade400) : null,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              fullName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF000B6B)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              party.toUpperCase(),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade700, letterSpacing: 0.5),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            if (course.isNotEmpty)
                                              Text(
                                                course,
                                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            const Spacer(),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  elevation: 0,
                                                ),
                                                onPressed: () => _showCandidateModal(c),
                                                child: const Text("See Bio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCandidateModal(dynamic candidate) {
    String fullName = "${candidate['first_name']} ${candidate['middle_name'] ?? ''} ${candidate['last_name']}".replaceAll('  ', ' ').trim();
    String platformBio = candidate['description_platform'] ?? 'No platform provided.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: primaryColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                        child: candidate['photo_url'] == null ? Icon(Icons.person, size: 50, color: Colors.grey.shade400) : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("Running for ${candidate['position']}", style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text("${candidate['party_name'] ?? 'Independent'} • ${candidate['course_year'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Platform & Bio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF000B6B))),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(platformBio, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MAIN HOME VIEW UI ---
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Home Dashboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Welcome! View active candidate platforms or review previous election winners.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy_rounded, size: 80, color: Colors.white54),
                            const SizedBox(height: 20),
                            Text(_errorMessage, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        )
                      )
                    : _polls.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 80, color: Colors.white54),
                                SizedBox(height: 20),
                                Text("No Polls Available.", style: TextStyle(fontSize: 20, color: Colors.white)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _polls.length,
                            itemBuilder: (context, index) {
                              final poll = _polls[index];
                              bool isEnded = _checkIfEnded(poll);
                              
                              String badgeText = isEnded ? "ENDED" : "ACTIVE";
                              Color badgeBg = isEnded ? Colors.red.shade100 : Colors.green.shade100;
                              Color badgeColor = isEnded ? Colors.red.shade800 : Colors.green.shade800;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                                            child: Icon(isEnded ? Icons.emoji_events : Icons.how_to_vote, size: 30, color: const Color(0xFF000B6B)),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(poll['title'] ?? 'Untitled Poll', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                                                      child: Text(
                                                        badgeText, 
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)
                                                      ),
                                                    ),
                                                    Text("Started on ${_formatDate(poll['start_time'])}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isEnded ? Colors.white : const Color(0xFF000B6B),
                                            foregroundColor: isEnded ? const Color(0xFF000B6B) : Colors.white,
                                            side: isEnded ? const BorderSide(color: Color(0xFF000B6B)) : BorderSide.none,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                          ),
                                          onPressed: () {
                                            if (isEnded) {
                                              _openWinnersPopup(poll['poll_id'], poll['title']);
                                            } else {
                                              _openCandidatesPopup(poll['poll_id'], poll['title']);
                                            }
                                          },
                                          child: Text(isEnded ? "View Winners" : "View Candidates", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// 3. ABOUT US VIEW
// ========================================================================
class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  Widget _buildProfileCard(String name, String role, IconData icon) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, size: 35, color: const Color(0xFF000B6B)),
          ),
          const SizedBox(height: 15),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF000B6B))),
          const SizedBox(height: 5),
          Text(role, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("About Us", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text("Learn more about the team behind the LNU eMobile Voting System.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000B6B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("The eMobile Voting System", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text(
                          "The Leyte Normal University (LNU) eMobile Voting System is a modern, secure, and accessible platform designed to streamline student elections. It ensures election integrity, eliminates manual tallying errors, and provides a seamless voting experience tailored for the university body.",
                          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("Meet the Team", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [                     
                      _buildProfileCard("Dorothy A. Magdaraog", "Project Manager\nUI & UX Designer\nFull Stack Developer", Icons.design_services),
                      _buildProfileCard("Carl David T. Pura", "Lead Developer\nFull-Stack\nQA Tester ", Icons.code),
                      _buildProfileCard("Jasmine T. Villaruel", "Full-Stack Developer\nDatabase Administrator", Icons.analytics),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ========================================================================
// 4. FAQS VIEW
// ========================================================================
class FAQsView extends StatelessWidget {
  const FAQsView({super.key});

  Widget _buildFaqCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF000B6B),
          collapsedIconColor: Colors.grey,
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B), fontSize: 15)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(answer, style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Frequently Asked Questions", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text("Find answers to common questions about using the voting system.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFaqCard(
                    "How do I register to vote?", 
                    "You must use your official LNU Email and Student ID to create an account on the login page. Once registered, your information is securely verified against the university database."
                  ),
                  _buildFaqCard(
                    "Is my vote strictly confidential?", 
                    "Yes! The system encrypts all ballot submissions. Election administrators can see that you have পণ্ডিত see who you voted for."
                  ),
                  _buildFaqCard(
                    "Can I change my vote after submitting?", 
                    "No. To maintain the highest level of election integrity, all submitted ballots are locked and final. Please review your choices carefully before confirming."
                  ),
                  _buildFaqCard(
                    "What happens if I forget my password?", 
                    "For security reasons, password resets are handled manually. You must contact the M.I.S or your campus IT admin to request a secure password reset."
                  ),
                  _buildFaqCard(
                    "Can I vote from off-campus?", 
                    "Absolutely. As long as you have an active internet connection and are logging in during the designated voting period, you can access the eMobile Voting system from anywhere."
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}