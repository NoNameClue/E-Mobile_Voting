import 'package:flutter/material.dart';
import 'package:frontend/manage_candidates.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'api_service.dart';
import 'responsive_screen.dart';

class VotingPage extends StatefulWidget {
  final VoidCallback onReturnToDashboard;

  const VotingPage({super.key, required this.onReturnToDashboard});

  @override
  State<VotingPage> createState() => _VotingPageState();
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScreen(
        child: Center(
          child: Column(
            children: [
            Text("Vote for Candidates"),
            ManageCandidates(),
            ],
          )
        )
      ),
    );
  }
}

class _VotingPageState extends State<VotingPage> {
  int currentPositionIndex = 0;
  Map<String, int?> selections = {};
  Map<String, List<dynamic>> candidatesByPosition = {};
  List<String> positions = [];
  
  bool isLoading = true;
  String? errorMessage;
  
  // New States for our logic
  int? activePollId;
  String activePollTitle = "";
  bool hasAlreadyVoted = false;
  bool isJustSubmitted = false; 
  bool isExpired = false; // <--- NEW STATE ADDED

  @override
  void initState() {
    super.initState();
    _initializeVotingSession();
  }

  // THE NEW LOGIC FLOW:
  Future<void> _initializeVotingSession() async {
    try {
      // 1. Find the Active Published Poll
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode != 200) throw Exception("Failed to fetch polls");
      
      final List<dynamic> polls = jsonDecode(pollResponse.body);
      final publishedPoll = polls.firstWhere(
        (p) => p['is_published'] == true || p['is_published'] == 1,
        orElse: () => null,
      );

      if (publishedPoll == null) {
        setState(() { isLoading = false; errorMessage = "No active elections right now."; });
        return;
      }

      activePollId = publishedPoll['poll_id'];
      activePollTitle = publishedPoll['title']; 
      
      // CHECK IF POLL IS EXPIRED
      if (publishedPoll['status'] == 'Ended') {
        setState(() {
          isExpired = true;
          isLoading = false;
        });
        return; // Stop here, no need to load candidates or check vote status
      }

      // 2. CHECK IF USER HAS ALREADY VOTED
      bool voted = await ApiService.checkVoteStatus(activePollId!);
      
      if (voted) {
        // If they voted, stop here and show the locked screen!
        setState(() {
          hasAlreadyVoted = true;
          isLoading = false;
        });
        return; 
      }

      // 3. IF NOT VOTED AND NOT EXPIRED, LOAD CANDIDATES
      List candidates = await ApiService.fetchCandidates(activePollId!);
      Map<String, List<dynamic>> grouped = {};

      for (var candidate in candidates) {
        String position = candidate["position"];
        if (!grouped.containsKey(position)) {
          grouped[position] = [];
        }
        grouped[position]!.add(candidate);
      }

      setState(() {
        candidatesByPosition = grouped;
        positions = grouped.keys.toList();
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load voting data.";
      });
    }
  }

  void nextPosition() {
    if (currentPositionIndex < positions.length - 1) {
      setState(() {
        currentPositionIndex++;
      });
    } else {
      submitBallot();
    }
  }

  void submitBallot() async {
    try {
      await ApiService.submitVote(activePollId!, selections);

      if (!mounted) return;
      setState(() {
        isJustSubmitted = true;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not submit vote.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF000B6B)));
    if (errorMessage != null) return Center(child: Text(errorMessage!, style: const TextStyle(fontSize: 18)));

    // --- STATE 1: EXPIRED POLL ---
    if (isExpired) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text("This ballot has expired/ended.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Voting is no longer allowed for this election.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // --- STATE 2: ALREADY VOTED ---
    if (hasAlreadyVoted && !isJustSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote, size: 80, color: Color(0xFF000B6B)),
            const SizedBox(height: 20),
            const Text(
              "Already Voted",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "You have already successfully cast your ballot for:\n$activePollTitle",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: widget.onReturnToDashboard,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go back to dashboard"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            )
          ],
        ),
      );
    }

    // --- STATE 3: THANK YOU PAGE (JUST SUBMITTED) ---
    if (isJustSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Thank You For Voting!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your ballot has been successfully recorded.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: widget.onReturnToDashboard, 
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go back to dashboard"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            )
          ],
        ),
      );
    }

    // --- STATE 4: NORMAL VOTING BALLOT ---
    if (positions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              Icons.ballot_outlined,
              size: 90,
              color: Colors.grey,
            ),

            SizedBox(height: 20),

            Text(
              "No Candidates Available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 10),

            Text(
              "Candidates have not been added to this election yet.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      );
    }

    String currentPosition = positions[currentPositionIndex];
    List candidates = candidatesByPosition[currentPosition]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("Vote for $currentPosition", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              var candidate = candidates[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: RadioListTile<int>(
                  contentPadding: const EdgeInsets.all(12),
                  activeColor: const Color(0xFF000B6B),
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: candidate["photo"] != null ? NetworkImage(candidate["photo"]) : null,
                        child: candidate["photo"] == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(candidate["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(candidate["party"] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (candidate["bio"] != null) ...[
                              const SizedBox(height: 5),
                              Text(candidate["bio"], style: const TextStyle(fontSize: 12)),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: candidate["candidate_id"],
                  groupValue: selections[currentPosition],
                  onChanged: (value) {
                    setState(() {
                      selections[currentPosition] = value;
                    });
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selections[currentPosition] == null ? null : nextPosition,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000B6B),
                foregroundColor: Colors.white,
              ),
              child: Text(currentPositionIndex == positions.length - 1 ? "Submit Ballot" : "Next Position"),
            ),
          ),
        ),
      ],
    );
  }
}