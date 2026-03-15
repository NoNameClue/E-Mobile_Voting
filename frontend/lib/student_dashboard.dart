import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ADDED
import 'dart:convert';
import 'api_config.dart'; 
import 'voting_page.dart';
import 'my_votes_view.dart';
import 'view_parties.dart';
// import 'responsive_screen.dart';

// ========================================================================
// 1. DATA MODELS 
// ========================================================================
class CandidateResult {
  final int id;
  final String name;
  final String party;
  final String? photoUrl;
  final int votes;
  final double percentage; 

  CandidateResult({
    required this.id,
    required this.name,
    required this.party,
    this.photoUrl,
    required this.votes,
    required this.percentage,
  });
}

class PositionRanking {
  final String positionName;
  final List<CandidateResult> candidates; 

  PositionRanking({
    required this.positionName,
    required this.candidates,
  });
}

// ========================================================================
// 2. MAIN STUDENT DASHBOARD SHELL 
// ========================================================================
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: ResponsiveScreen(
  //       child: Column(
  //         children: [
  //           Text("Student Dashboard", style: TextStyle(fontSize: 24)),
  //           StudentDashboard(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class _StudentDashboardState extends State<StudentDashboard> {
  int selectedIndex = 0;
  final Color primaryColor = const Color(0xFF000B6B);

  // Profile States
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
    _fetchUserProfile(); // Fetch user data on load
  }

  // Fetch the logged-in user's profile
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
    await prefs.clear(); // Clear token on logout
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildSidebar(bool isDesktop) {
    return Container(
      width: 250,
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Text('Logo', style: TextStyle(color: Colors.black, fontSize: 10))),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Leyte Normal University\n(System Name)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // DYNAMIC PROFILE PICTURE
          CircleAvatar(
            radius: 30, 
            backgroundColor: Colors.white, 
            backgroundImage: _profilePicUrl != null 
                ? NetworkImage('${ApiConfig.baseUrl}/$_profilePicUrl') 
                : null,
            child: _profilePicUrl == null 
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 10),
          
          // DYNAMIC NAME & ID
          Text(
            "$_studentName\nID: $_studentId", 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.white)
          ),
          const SizedBox(height: 40),

          for (int i = 0; i < menuItems.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  // THE HIGHLIGHT BAR: If selected, show amber background
                  color: selectedIndex == i ? Colors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    menuItems[i],
                    style: TextStyle(
                      // Text turns dark blue on amber background for high contrast
                      color: selectedIndex == i ? const Color(0xFF000B6B) : Colors.white,
                      fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => selectedIndex = i);
                    if (!isDesktop) Navigator.pop(context); 
                  },
                ),
              ),
            ),

          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: logout,
          ),
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text('V1.2026.03126 | LNUVotingSystem', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return const LiveScoreboardView(); 
      case 1:
        return VotingPage(
          onReturnToDashboard: () {
            setState(() {
              selectedIndex = 0; 
            });
          },
        );
      case 2:
        return const ViewParties();
      case 3:
        return const MyVotesView();
      case 4:
        return const Center(child: Text("FAQs", style: TextStyle(fontSize: 24)));
      case 5:
        return const Center(child: Text("About Us", style: TextStyle(fontSize: 24)));
      default:
        return const LiveScoreboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: isDesktop 
          ? null 
          : AppBar(backgroundColor: primaryColor, title: const Text("Student Portal")),
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

// ========================================================================
// 3. LIVE SCOREBOARD WIDGET 
// ========================================================================
class LiveScoreboardView extends StatefulWidget {
  const LiveScoreboardView({super.key});

  @override
  State<LiveScoreboardView> createState() => _LiveScoreboardViewState();
}

class _LiveScoreboardViewState extends State<LiveScoreboardView> {
  int _currentPositionIndex = 0; 
  List<PositionRanking> _rankingsData = []; 
  bool _isLoading = true;
  String _errorMessage = '';

  final Color primaryColor = const Color(0xFF000B6B);

  @override
  void initState() {
    super.initState();
    _fetchLiveResults(); 
  }

  Future<void> _fetchLiveResults() async {
    try {
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode != 200) throw Exception("Failed to fetch polls");
      
      final List<dynamic> polls = jsonDecode(pollResponse.body);
      
      final publishedPoll = polls.firstWhere(
        (p) => p['is_published'] == true || p['is_published'] == 1,
        orElse: () => null,
      );

      if (publishedPoll == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No active elections right now.";
        });
        return;
      }

      int activePollId = publishedPoll['poll_id'];

      final resultsResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$activePollId/results'));
      if (resultsResponse.statusCode != 200) throw Exception("Failed to fetch results");
      
      final List<dynamic> liveResults = jsonDecode(resultsResponse.body);

      Map<String, List<CandidateResult>> groupedData = {
        "President": [],
        "Vice President": [],
        "Secretary": [],
        "Treasurer": [],
        "Auditor": [],
        "PIO": [],
      };

      for (var c in liveResults) {
        String pos = c['position'];
        if (groupedData.containsKey(pos)) {
          groupedData[pos]!.add(
            CandidateResult(
              id: c['candidate_id'],
              name: c['name'],
              party: c['party_name'] ?? 'Independent',
              votes: c['votes'], 
              percentage: c['percentage'] 
            )
          );
        }
      }

      List<PositionRanking> formattedRankings = [];
      groupedData.forEach((position, candidatesList) {
        candidatesList.sort((a, b) => b.votes.compareTo(a.votes));
        formattedRankings.add(PositionRanking(positionName: position, candidates: candidatesList));
      });

      setState(() {
        _rankingsData = formattedRankings;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not connect to the server.";
      });
    }
  }

  void _goToPreviousPosition() {
    if (_currentPositionIndex > 0) {
      setState(() => _currentPositionIndex--);
    }
  }

  void _goToNextPosition() {
    if (_currentPositionIndex < _rankingsData.length - 1) {
      setState(() => _currentPositionIndex++);
    }
  }

  void _showPercentagePopup(CandidateResult candidate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(candidate.name, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${candidate.percentage.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 10),
              Text("Current vote share in ${_rankingsData[_currentPositionIndex].positionName} race.", textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));
    
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(fontSize: 20, color: Colors.grey)));
    }

    final currentRanking = _rankingsData[_currentPositionIndex];
    final candidates = currentRanking.candidates;

    // --- RESPONSIVE CHECK ---
    bool isMobile = MediaQuery.of(context).size.width < 900;

   // UI SECTION 1: PODIUM
    Widget podiumSection = Column(
      mainAxisAlignment: MainAxisAlignment.start, 
      children: [
        Container(
          width: isMobile ? double.infinity : 350,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: _currentPositionIndex == 0 ? null : _goToPreviousPosition,
              ),
              Flexible(child: Text(currentRanking.positionName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: _currentPositionIndex == _rankingsData.length - 1 ? null : _goToNextPosition,
              ),
            ],
          ),
        ),
        
        // --- THE FIX: Increased the spacing here to push the avatars down ---
        // On desktop it pushes down 150 pixels, on mobile it stays at 50
        SizedBox(height: isMobile ? 50 : 150), 
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (candidates.length >= 2) _buildPodiumPerson(candidates[1], 2, isMobile),
            if (candidates.isNotEmpty) _buildPodiumPerson(candidates[0], 1, isMobile),
            if (candidates.length >= 3) _buildPodiumPerson(candidates[2], 3, isMobile),
          ],
        ),
        const SizedBox(height: 20),
        const Text("top 3 candidates for the\nposition", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );

    // UI SECTION 2: OTHER CANDIDATES LIST
    Widget otherCandidatesSection = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("other candidates for the position", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length > 3 ? candidates.length - 3 : 0,
              itemBuilder: (context, index) {
                final candidate = candidates[index + 3];
                return _buildOtherCandidateListTile(candidate);
              },
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 30),

          Expanded(
            child: candidates.isEmpty
                ? const Center(
                    child: Text("No candidates assigned to this position yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  )
                : isMobile
                    ? Column(
                        children: [
                          podiumSection,
                          const SizedBox(height: 30),
                          Expanded(child: otherCandidatesSection),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: podiumSection),
                          const SizedBox(width: 40),
                          Expanded(flex: 1, child: otherCandidatesSection),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // --- PASS isMobile TO ADJUST AVATAR SIZES FOR SMALL SCREENS ---
  Widget _buildPodiumPerson(CandidateResult candidate, int rank, bool isMobile) {
    // Slightly smaller avatars on mobile so they don't squish
    double avatarRadius = rank == 1 ? (isMobile ? 50 : 60) : (isMobile ? 40 : 50);
    double iconSize = rank == 1 ? (isMobile ? 60 : 80) : (isMobile ? 50 : 60);

    return GestureDetector(
      onTap: () => _showPercentagePopup(candidate),
      child: Column(
        children: [
          CircleAvatar(
            radius: avatarRadius, 
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: iconSize, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Text(
            candidate.name, 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
            textAlign: TextAlign.center,
          ),
          Text(
            candidate.party, 
            style: TextStyle(color: Colors.black54, fontSize: isMobile ? 10 : 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text("${candidate.votes} Votes", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildOtherCandidateListTile(CandidateResult candidate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${candidate.name.toUpperCase()} AND ${candidate.party.toUpperCase()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 20,
                    width: candidate.percentage > 0 ? (candidate.percentage / 100) * 200 : 0, 
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: candidate.percentage > 0 
                      ? Text("${candidate.percentage.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                      : null,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}