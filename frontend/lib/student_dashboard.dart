import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';
import 'voting_page.dart';
import 'my_votes_view.dart';
import 'view_parties.dart';
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

  String _studentName = "Loading...";
  String _studentId = "";
  String? _profilePicUrl;

  final List<String> menuItems = [
    "Dashboard",
    "Vote",
    "View Parties",
    "My Votes",
    "FAQs",
    "About Us",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); 
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

  Widget buildSidebar(bool isDesktop) {
    return Container(
      width: 250,
      color: primaryColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                  const SizedBox(height: 40),

                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage('${ApiConfig.baseUrl}/$_profilePicUrl')
                        : null,
                    child: _profilePicUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "$_studentName\nID: $_studentId",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Transform.scale(
                    scale: 0.80, 
                    child: const RealtimeClock(textColor: Colors.white, isCenterAligned: true),
                  ),
                  
                  const SizedBox(height: 20),

                  for (int i = 0; i < menuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0, 
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
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -4), 
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                          title: Text(
                            menuItems[i],
                            style: TextStyle(
                              fontSize: 13, 
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

          const Divider(color: Colors.white24, height: 1), 
          
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4), 
            leading: const Icon(Icons.logout, color: Colors.white, size: 20), 
            title: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 13)), 
            onTap: logout,
          ),
          
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'V1.2026.03126 | LNUVotingSystem',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
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
      case 4:
        return const Center(
          child: Text("FAQs", style: TextStyle(fontSize: 24, color: Colors.white)),
        );
      case 5:
        return const Center(
          child: Text("About Us", style: TextStyle(fontSize: 24, color: Colors.white)),
        );
      default:
        return const CandidatePlatformsView();
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
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              title: const Text("Student Portal", style: TextStyle(fontWeight: FontWeight.bold)),
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
// 2. CANDIDATE PLATFORMS VIEW
// ========================================================================
class CandidatePlatformsView extends StatefulWidget {
  const CandidatePlatformsView({super.key});

  @override
  State<CandidatePlatformsView> createState() => _CandidatePlatformsViewState();
}

class _CandidatePlatformsViewState extends State<CandidatePlatformsView> {
  bool _isLoading = true;
  String _errorMessage = '';

  int? _selectedPollId;
  String _pollTitle = "";
  
  Map<String, List<dynamic>> _groupedCandidates = {};

  final Color primaryColor = const Color(0xFF000B6B);

  // Standard positional order to sort the list consistently
  final List<String> standardPositions = [
    "President", "Vice President", "Secretary", "Treasurer", "Auditor", "PIO"
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode == 200) {
        final List<dynamic> allPolls = jsonDecode(pollResponse.body);
        
        // 🛠️ FILTER LOGIC: Find the FIRST published, unarchived, active poll
        var activePolls = allPolls.where((p) {
          final isPublished = p['is_published'] == 1 || p['is_published'] == true;
          final isArchived = p['is_archived'] == 1 || p['is_archived'] == true;
          
          bool isEnded = p['status'] == 'Ended';
          if (p['end_time'] != null) {
            DateTime endTime = DateTime.parse(p['end_time']);
            if (endTime.isBefore(DateTime.now())) {
              isEnded = true;
            }
          }
          
          return isPublished && !isArchived && !isEnded;
        }).toList();

        if (activePolls.isNotEmpty) {
          var activePoll = activePolls.first;
          _selectedPollId = activePoll['poll_id'];
          _pollTitle = activePoll['title'] ?? "Active Election";
          await _fetchCandidatesForPoll(_selectedPollId!);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "There are no active elections at this time.";
          });
        }
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

  Future<void> _fetchCandidatesForPoll(int pollId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$pollId'));
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch candidates");
      }

      final List<dynamic> candidates = jsonDecode(response.body);
      Map<String, List<dynamic>> grouped = {};

      for (var c in candidates) {
        String pos = c['position'] ?? 'Unknown Position';
        grouped.putIfAbsent(pos, () => []).add(c);
      }

      // Sort positions based on standard hierarchy
      var sortedGrouped = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) {
          int indexA = standardPositions.indexOf(a.key);
          int indexB = standardPositions.indexOf(b.key);
          if (indexA == -1) indexA = 999;
          if (indexB == -1) indexB = 999;
          return indexA.compareTo(indexB);
        })
      );

      setState(() {
        _groupedCandidates = sortedGrouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not fetch candidates for this poll.";
      });
    }
  }

  void _showCandidateModal(dynamic candidate) {
    String fullName = "${candidate['first_name']} ${candidate['middle_name'] ?? ''} ${candidate['last_name']}".replaceAll('  ', ' ').trim();
    String platformBio = candidate['description_platform'] ?? 'No platform provided.';
    List<dynamic> qas = candidate['qas'] ?? [];

    String formattedQA = "";
    if (qas.isEmpty) {
      formattedQA = "No Q&A responses available.";
    } else {
      for (int i = 0; i < qas.length; i++) {
        formattedQA += "${i + 1}. ${qas[i]['question']}\n${qas[i]['answer']}\n\n";
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
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
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                
                // Scrollable Body
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
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                            child: Text(platformBio, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                          ),
                          
                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 25),
                          
                          const Text("Candidate Q&A", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF000B6B))),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
                            child: Text(
                              formattedQA.trim(), 
                              style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)
                            ),
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
                    "Dashboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (_pollTitle.isNotEmpty)
                    Text(
                      _pollTitle,
                      style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Review the candidates and their platforms before casting your vote.", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                            const SizedBox(height: 10),
                            const Text("Please check back when an election begins.", style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        )
                      )
                    : _groupedCandidates.isEmpty
                        ? const Center(child: Text("No candidates assigned to this election yet.", style: TextStyle(fontSize: 20, color: Colors.white)))
                        : ListView.builder(
                            itemCount: _groupedCandidates.length,
                            itemBuilder: (context, index) {
                              String position = _groupedCandidates.keys.elementAt(index);
                              List<dynamic> candidates = _groupedCandidates[position]!;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 35.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🛠️ CHANGED: Text is now white instead of amber
                                    Text(
                                      "Running for $position",
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      height: 260, // 🛠️ INCREASED height for more info
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: candidates.length,
                                        itemBuilder: (context, cIndex) {
                                          var c = candidates[cIndex];
                                          String fullName = "${c['first_name']} ${c['last_name']}";
                                          String party = c['party_name'] ?? 'Independent';
                                          String course = c['course_year'] ?? '';

                                          return Container(
                                            width: 180, // 🛠️ INCREASED width for comfort
                                            margin: const EdgeInsets.only(right: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
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
                                                  // 🛠️ ADDED: Party Name
                                                  Text(
                                                    party.toUpperCase(),
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade700, letterSpacing: 0.5),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  // 🛠️ ADDED: Course and Year
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
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        elevation: 0,
                                                      ),
                                                      onPressed: () => _showCandidateModal(c),
                                                      child: const Text("See More", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                            },
                          ),
          ),
        ],
      ),
    );
  }
}