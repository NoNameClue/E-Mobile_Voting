import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';

class MyVotesView extends StatefulWidget {
  const MyVotesView({super.key});

  @override
  State<MyVotesView> createState() => _MyVotesViewState();
}

class _MyVotesViewState extends State<MyVotesView> {
  final Color primaryColor = const Color(0xFF000B6B);

  List<dynamic> _polls = [];
  Map<String, dynamic>? _selectedPoll;
  bool _isLoading = true;

  // New states for the side panel
  dynamic _displayingCandidate;
  Map<String, dynamic> _candidateStats = {};
  
  // Track the user's specific vote status for the current poll
  bool _hasVotedInSelectedPoll = false;
  List<dynamic> _userVotedCandidates = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      // 1. Fetch All Polls
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode == 200) {
        final List<dynamic> allPolls = jsonDecode(pollResponse.body);
        
        // Only show published & non-archived polls in the dropdown
        _polls = allPolls.where((p) => 
          (p['is_published'] == 1 || p['is_published'] == true) && 
          (p['is_archived'] == 0 || p['is_archived'] == false)
        ).toList();

        if (_polls.isNotEmpty) {
          // Default to the first active poll if possible
          _selectedPoll = _polls.firstWhere((p) => p['status'] != 'Ended', orElse: () => _polls.first);
        }
      }

      if (_selectedPoll != null) {
        await _loadPollDetails(_selectedPoll!);
      } else {
        setState(() => _isLoading = false);
      }

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPollDetails(Map<String, dynamic> poll) async {
    setState(() => _isLoading = true);
    try {
      int pollId = poll['poll_id'];
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      // 1. Fetch the user's personal vote history
      final votesResponse = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me/votes"),
        headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      );

      bool foundVote = false;
      List<dynamic> candidatesVotedFor = [];

      if (votesResponse.statusCode == 200) {
        List<dynamic> userVoteHistory = jsonDecode(votesResponse.body);
        // Find if this specific poll exists in their vote history
        for (var history in userVoteHistory) {
          if (history['poll_id'] == pollId) {
            foundVote = true;
            candidatesVotedFor = history['candidates'];
            break;
          }
        }
      }

      // 2. Fetch the live stats for the poll
      final statsResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/results'));
      Map<String, dynamic> stats = {};
      
      if (statsResponse.statusCode == 200) {
        final List<dynamic> results = jsonDecode(statsResponse.body);
        for (var c in results) {
          stats[c['name']] = {
            'votes': c['votes'],
            'percentage': c['percentage'],
          };
        }
      }

      setState(() {
        _hasVotedInSelectedPoll = foundVote;
        _userVotedCandidates = candidatesVotedFor;
        _candidateStats = stats;
        
        // Auto-select the first candidate they voted for to populate the side panel
        if (foundVote && candidatesVotedFor.isNotEmpty) {
          _displayingCandidate = candidatesVotedFor[0];
        } else {
          _displayingCandidate = null;
        }
        
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onPollChanged(Map<String, dynamic>? newPoll) {
    if (newPoll != null && newPoll['poll_id'] != _selectedPoll?['poll_id']) {
      setState(() {
        _selectedPoll = newPoll;
      });
      _loadPollDetails(newPoll);
    }
  }

  void _setDisplayingCandidate(dynamic candidate) {
    setState(() {
      _displayingCandidate = candidate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    bool isMobile = MediaQuery.of(context).size.width < 900;

    // --- MAIN CONTENT AREA (Left Side) ---
    Widget mainContent;

    if (_polls.isEmpty) {
      mainContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote_outlined, size: 90, color: Colors.grey),
            SizedBox(height: 20),
            Text("No Elections Found", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey)),
            SizedBox(height: 10),
            Text("There are no published elections available right now.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    } else if (!_hasVotedInSelectedPoll) {
      bool isEnded = _selectedPoll!['status'] == 'Ended';
      mainContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEnded ? Icons.timer_off : Icons.pending_actions, size: 90, color: isEnded ? Colors.redAccent : Colors.grey),
            const SizedBox(height: 20),
            Text(
              isEnded ? "Election Ended" : "No Ballot Cast",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isEnded ? Colors.redAccent : Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              isEnded 
                  ? "This election has ended. You did not participate." 
                  : "You have not voted in this election yet. Go to the Vote tab to cast your ballot!",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Show the list of candidates they voted for
      mainContent = ListView.separated(
        itemCount: _userVotedCandidates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          var candidate = _userVotedCandidates[index];
          final isDisplaying = _displayingCandidate?['name'] == candidate['name'];

          return InkWell(
            onTap: () => _setDisplayingCandidate(candidate),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDisplaying
                    ? Border.all(color: primaryColor, width: 2)
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  if (isDisplaying)
                    BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: candidate["photo"] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate["photo"]}') : null,
                    child: candidate["photo"] == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(candidate["position"] ?? "Position", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(candidate["name"] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(candidate["party"] ?? "Independent", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // --- FULL PAGE LAYOUT ---
    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Votes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              if (_polls.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      value: _selectedPoll,
                      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                      items: _polls.map((poll) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: poll as Map<String, dynamic>,
                          child: Text(poll["title"] ?? "Election", style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _onPollChanged,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      Expanded(flex: 3, child: mainContent),
                      if (_displayingCandidate != null && _hasVotedInSelectedPoll)
                        Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(top: 15), child: _buildDetailPanel())),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: mainContent),
                      if (_hasVotedInSelectedPoll)
                        Container(width: 350, margin: const EdgeInsets.only(left: 30), child: _buildDetailPanel()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- RIGHT SIDE DETAIL & STATS PANEL ---
  Widget _buildDetailPanel() {
    if (_displayingCandidate == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: const Center(child: Text("Select a candidate to view stats.", style: TextStyle(color: Colors.grey))),
      );
    }

    final candidate = _displayingCandidate;
    final candidateName = candidate['name'] ?? '';

    final stats = _candidateStats[candidateName] ?? {'votes': 0, 'percentage': 0.0};
    final int totalVotes = stats['votes'];
    final double percentage = (stats['percentage'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: candidate["photo"] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate["photo"]}') : null,
              child: candidate["photo"] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
            ),
            const SizedBox(height: 20),

            Text(
              candidate['name'] ?? 'Unknown Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text((candidate['position'] ?? 'POSITION').toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(candidate['party'] ?? 'Independent', style: const TextStyle(fontSize: 14, color: Colors.grey)),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            const Align(alignment: Alignment.centerLeft, child: Text("Live Election Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Icon(Icons.how_to_vote, color: primaryColor, size: 28),
                        const SizedBox(height: 10),
                        Text(totalVotes.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                        const Text("Total Votes", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart, color: primaryColor, size: 28),
                        const SizedBox(height: 10),
                        Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                        const Text("Vote Share", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}