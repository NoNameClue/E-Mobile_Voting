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
  bool _shownLoginSnack = false;

  final List<String> menuItems = [
    "Home", 
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
      case "Home": return Icons.home_rounded;
      case "Vote": return Icons.how_to_vote_rounded;
      case "View Parties": return Icons.flag_rounded;
      case "My Votes": return Icons.fact_check_rounded;
      case "FAQs": return Icons.help_outline_rounded;
      case "About Us": return Icons.info_outline_rounded;
      default: return Icons.circle;
    }
  }

  Widget buildSidebar(bool isDesktop) {
    double sidebarWidth = isDesktop ? 280.0 : 250.0;
    double menuFontSize = isDesktop ? 15.0 : 13.0;
    double menuIconSize = isDesktop ? 22.0 : 20.0;

    return Container(
      width: sidebarWidth,
      color: primaryColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20), 
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                    child: Row(
                      children: [
                        Container(
                          width: 70, 
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/lnu_logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), 
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leyte Normal University',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 14 : 12, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '(eMobile Voting)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 11 : 10, 
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), 

                  CircleAvatar(
                    radius: isDesktop ? 45 : 40,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage('${ApiConfig.baseUrl}/$_profilePicUrl')
                        : null,
                    child: _profilePicUrl == null
                        ? Icon(Icons.person, size: isDesktop ? 50 : 45, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "$_studentName\nID: $_studentId",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 16 : 14, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 15), 

                  Transform.scale(
                    scale: isDesktop ? 0.90 : 0.80, 
                    child: const RealtimeClock(textColor: Colors.white, isCenterAligned: true),
                  ),
                  
                  const SizedBox(height: 15),

                  for (int i = 0; i < menuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4, 
                        horizontal: 15, 
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedIndex == i
                              ? Colors.amber
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16), 
                        ),
                        child: ListTile(
                          dense: true, 
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -2), 
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                          leading: Icon(
                            _getStudentMenuIcon(menuItems[i]),
                            size: menuIconSize,
                            color: selectedIndex == i ? const Color(0xFF000B6B) : Colors.white70,
                          ),
                          title: Text(
                            menuItems[i],
                            style: TextStyle(
                              fontSize: menuFontSize, 
                              color: selectedIndex == i
                                  ? const Color(0xFF000B6B)
                                  : Colors.white,
                              fontWeight: selectedIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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
            leading: Icon(Icons.logout, color: Colors.white, size: menuIconSize), 
            title: Text("Logout", style: TextStyle(color: Colors.white, fontSize: menuFontSize)), 
            onTap: logout,
          ),
          
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'V1.0.1 | LNUVotingSystem',
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
      case 4: return const FAQsView();
      case 5: return const AboutUsView();
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
              backgroundColor: primaryColor,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                          
                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 25),
                          
                          const Text("Candidate Q&A", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF000B6B))),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
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
                    "Home",
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
                                    Text(
                                      "Running for $position",
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
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
                                                    child: const Text("See More", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                    "Yes! The system encrypts all ballot submissions. Election administrators can see that you have submitted a vote, but they can never see who you voted for."
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