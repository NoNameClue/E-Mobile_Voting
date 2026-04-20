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

  PositionRanking({required this.positionName, required this.candidates});
}

// ========================================================================
// 2. MAIN STUDENT DASHBOARD SHELL
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

  // 🛠️ UPDATED SIDEBAR: Matches Admin sizing exactly
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
                  const SizedBox(height: 30), // Match Admin top spacing
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                    child: Row(
                      children: [
                        // 🛠️ Match Admin Logo Size (50x50)
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
                        const SizedBox(width: 10), // Match Admin spacing
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leyte Normal University',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12, // Match Admin University text size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '(System Name)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10, // Match Admin System Name text size
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 🛡️ UNTOUCHED PROFILE AVATAR
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

                  // 🛠️ Match Admin Name text size and weight
                  Text(
                    "$_studentName\nID: $_studentId",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15, // Match Admin size
                      fontWeight: FontWeight.bold, // Match Admin weight
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🛠️ Match Admin Clock size exactly using the scale transform
                  Transform.scale(
                    scale: 0.80, 
                    child: const RealtimeClock(textColor: Colors.white, isCenterAligned: true),
                  ),
                  
                  const SizedBox(height: 20),

                  // 🛠️ COMPRESSED MENU LIST (Matches Admin exactly)
                  for (int i = 0; i < menuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 0, // Removed vertical padding
                        horizontal: 10, // Match Admin horizontal padding
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedIndex == i
                              ? Colors.amber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5), // Match Admin border radius
                        ),
                        child: ListTile(
                          dense: true, 
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -4), // MAXIMUM COMPRESSION
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                          title: Text(
                            menuItems[i],
                            style: TextStyle(
                              fontSize: 13, // Match Admin font size
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

          const Divider(color: Colors.white24, height: 1), // Match Admin divider
          
          // 🛠️ COMPRESSED LOGOUT BUTTON (Matches Admin exactly)
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4), // MAXIMUM COMPRESSION
            leading: const Icon(Icons.logout, color: Colors.white, size: 20), // Match Admin icon size
            title: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 13)), // Match Admin font size
            onTap: logout,
          ),
          
          // 🛡️ UNTOUCHED WATERMARK
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
      case 0: return const LiveScoreboardView();
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
        return const LiveScoreboardView();
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
        isFrosted: true, // 🛡️ Frosted background kept
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
// 3. LIVE SCOREBOARD VIEW (STUDENT DASHBOARD CONTENT)
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

  List<dynamic> _availablePolls = [];
  int? _selectedPollId;

  final Color primaryColor = const Color(0xFF000B6B);

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
        
        _availablePolls = allPolls.where((p) {
          final isPublished = p['is_published'] == 1 || p['is_published'] == true;
          final isArchived = p['is_archived'] == 1 || p['is_archived'] == true;
          
          return isPublished && !isArchived;
        }).toList();

        if (_availablePolls.isNotEmpty) {
          var activePoll = _availablePolls.first;
          _selectedPollId = activePoll['poll_id'];
          
          await _fetchResultsForPoll(_selectedPollId!);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "No active elections right now.";
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

  Future<void> _fetchResultsForPoll(int pollId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final resultsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/results'),
      );
      if (resultsResponse.statusCode != 200) {
        throw Exception("Failed to fetch results");
      }

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
              photoUrl: c['photo_url'], 
              votes: c['votes'],
              percentage: c['percentage'],
            ),
          );
        }
      }

      List<PositionRanking> formattedRankings = [];
      groupedData.forEach((position, candidatesList) {
        candidatesList.sort((a, b) => b.votes.compareTo(a.votes));
        formattedRankings.add(
          PositionRanking(positionName: position, candidates: candidatesList),
        );
      });

      setState(() {
        _rankingsData = formattedRankings;
        _currentPositionIndex = 0; 
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not fetch results for this poll.";
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(candidate.name, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${candidate.percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Current vote share in ${_rankingsData[_currentPositionIndex].positionName} race.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    Widget headerRow = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 15,
      runSpacing: 15,
      children: [
        const Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_availablePolls.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedPollId,
                icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                items: _availablePolls.map((poll) {
                  bool isExpired = false;
                  if (poll['end_time'] != null) {
                    DateTime endTime = DateTime.parse(poll['end_time']);
                    isExpired = endTime.isBefore(DateTime.now());
                  }
                  String displayTitle = poll["title"] ?? "Election";
                  if (isExpired || poll['status'] == 'Ended') {
                    displayTitle = "$displayTitle (Ended)";
                  }

                  return DropdownMenuItem<int>(
                    value: poll['poll_id'],
                    child: Text(displayTitle, style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newPollId) {
                  if (newPollId != null && newPollId != _selectedPollId) {
                    setState(() => _selectedPollId = newPollId);
                    _fetchResultsForPoll(newPollId);
                  }
                },
              ),
            ),
          ),
      ],
    );

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator(color: Colors.white)); 
    } else if (_errorMessage.isNotEmpty) {
      bodyContent = Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(fontSize: 20, color: Colors.white), 
        ),
      );
    } else if (_rankingsData.isEmpty) {
      bodyContent = const Center(
        child: Text(
          "No data available for this poll.",
          style: TextStyle(fontSize: 20, color: Colors.white), 
        ),
      );
    } else {
      final currentRanking = _rankingsData[_currentPositionIndex];
      final candidates = currentRanking.candidates;

      Widget podiumSection = Column(
        children: [
          Container(
            width: isMobile ? double.infinity : 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: _currentPositionIndex == 0 ? null : _goToPreviousPosition,
                ),
                Flexible(
                  child: Text(
                    currentRanking.positionName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: _currentPositionIndex == _rankingsData.length - 1 ? null : _goToNextPosition,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (candidates.length >= 2) _buildPodiumPerson(candidates[1], 2, isMobile),
                        if (candidates.isNotEmpty) _buildPodiumPerson(candidates[0], 1, isMobile),
                        if (candidates.length >= 3) _buildPodiumPerson(candidates[2], 3, isMobile),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "top 3 candidates for the\nposition",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70), 
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

      Widget otherCandidatesSection = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "other candidates for the position",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
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

      if (candidates.isEmpty) {
        bodyContent = const Center(
          child: Text(
            "No candidates assigned to this position yet.",
            style: TextStyle(fontSize: 18, color: Colors.white), 
          ),
        );
      } else if (isMobile) {
        bodyContent = Column(
          children: [
            Expanded(flex: 5, child: podiumSection), 
            const SizedBox(height: 20),
            Expanded(flex: 4, child: otherCandidatesSection),
          ],
        );
      } else {
        bodyContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: podiumSection),
            const SizedBox(width: 40),
            Expanded(flex: 1, child: otherCandidatesSection),
          ],
        );
      }
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const SizedBox(height: 30),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildPodiumPerson(
    CandidateResult candidate,
    int rank,
    bool isMobile,
  ) {
    double avatarRadius = rank == 1
        ? (isMobile ? 50 : 60)
        : (isMobile ? 40 : 50);
    double iconSize = rank == 1 ? (isMobile ? 60 : 80) : (isMobile ? 50 : 60);

    return GestureDetector(
      onTap: () => _showPercentagePopup(candidate),
      child: Column(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            backgroundImage: candidate.photoUrl != null
                ? NetworkImage('${ApiConfig.baseUrl}/${candidate.photoUrl}')
                : null,
            child: candidate.photoUrl == null
                ? Icon(Icons.person, size: iconSize, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            candidate.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
              color: Colors.white, 
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            candidate.party,
            style: TextStyle(
              color: Colors.white70, 
              fontSize: isMobile ? 10 : 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${candidate.votes} Votes",
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherCandidateListTile(CandidateResult candidate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25, 
            backgroundColor: Colors.grey,
            backgroundImage: candidate.photoUrl != null
                ? NetworkImage('${ApiConfig.baseUrl}/${candidate.photoUrl}')
                : null,
            child: candidate.photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${candidate.name.toUpperCase()} AND ${candidate.party.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 20,
                    width: candidate.percentage > 0
                        ? (candidate.percentage / 100) * 200
                        : 0,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: candidate.percentage > 0
                        ? Text(
                            "${candidate.percentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}