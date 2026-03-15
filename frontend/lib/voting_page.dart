import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'api_service.dart';

class VotingPage extends StatefulWidget {
  final VoidCallback onReturnToDashboard;

  const VotingPage({super.key, required this.onReturnToDashboard});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  // Navigation & UI States
  int _currentPositionIndex = 0;
  dynamic _displayingCandidate; 
  final Color primaryColor = const Color(0xFF000B6B);

  // Voting Data States
  Map<String, int?> _selectedCandidates = {}; 
  Map<String, List<dynamic>> _candidatesByPosition = {};
  List<String> _positionNames = [];
  
  // Status States
  bool _isLoading = true;
  String? _errorMessage;
  int? _activePollId;
  String _activePollTitle = "";
  bool _hasAlreadyVoted = false;
  bool _isJustSubmitted = false; 
  bool _isExpired = false; 

  // --- NEW: Computes if ALL positions have a selected candidate ---
  bool get _hasSelectedAll {
    if (_positionNames.isEmpty) return false;
    for (String pos in _positionNames) {
      if (_selectedCandidates[pos] == null) return false; // If any position is null, return false
    }
    return true; // All positions have a vote!
  }

  @override
  void initState() {
    super.initState();
    _initializeVotingSession();
  }

  // --- CORE LOGIC ---
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
        setState(() { _isLoading = false; _errorMessage = "No active elections right now."; });
        return;
      }

      _activePollId = publishedPoll['poll_id'];
      _activePollTitle = publishedPoll['title']; 
      
      // 2. Check if Poll is Expired
      if (publishedPoll['status'] == 'Ended') {
        setState(() { _isExpired = true; _isLoading = false; });
        return; 
      }

      // 3. Check if User Already Voted
      bool voted = await ApiService.checkVoteStatus(_activePollId!);
      if (voted) {
        setState(() { _hasAlreadyVoted = true; _isLoading = false; });
        return; 
      }

      // 4. Fetch and Group Candidates
      List rawCandidates = await ApiService.fetchCandidates(_activePollId!);
      Map<String, List<dynamic>> grouped = {};

      for (var candidate in rawCandidates) {
        String position = candidate["position"];
        if (!grouped.containsKey(position)) {
          grouped[position] = [];
        }
        grouped[position]!.add(candidate);
      }

      setState(() {
        _candidatesByPosition = grouped;
        _positionNames = grouped.keys.toList();
        
        // Auto-select the first candidate for the side panel view
        if (_positionNames.isNotEmpty) {
          final currentPos = _positionNames[0];
          if (_candidatesByPosition[currentPos]!.isNotEmpty) {
            _displayingCandidate = _candidatesByPosition[currentPos]![0];
          }
        }
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load voting data.";
      });
    }
  }

  // --- UI INTERACTIONS ---
  void _setDisplayingCandidate(dynamic candidate) {
    setState(() {
      _displayingCandidate = candidate;
    });
  }

  // Pop-up 1: Individual Candidate Selection
  Future<void> _confirmCandidateSelection(String position, dynamic candidate) async {
    final candidateId = candidate['candidate_id'];
    final isCurrentlySelected = _selectedCandidates[position] == candidateId;

    // If they are un-checking the circle, let them do it instantly without a popup
    if (isCurrentlySelected) {
      setState(() {
        _selectedCandidates[position] = null;
      });
      return;
    }

    // If they are voting for someone, show the confirmation popup
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Vote for ${candidate['name']}?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to select ${candidate['name']} for the position of $position?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(), 
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Yes, Select', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                setState(() {
                  _selectedCandidates[position] = candidateId; // Register the selection
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _goToNextPosition() {
    if (_currentPositionIndex < _positionNames.length - 1) {
      setState(() {
        _currentPositionIndex++;
        final nextPosition = _positionNames[_currentPositionIndex];
        if (_candidatesByPosition[nextPosition] != null && _candidatesByPosition[nextPosition]!.isNotEmpty) {
          _displayingCandidate = _candidatesByPosition[nextPosition]![0];
        } else {
          _displayingCandidate = null;
        }
      });
    }
  }

  void _goToPreviousPosition() {
    if (_currentPositionIndex > 0) {
      setState(() {
        _currentPositionIndex--;
        final prevPosition = _positionNames[_currentPositionIndex];
        if (_candidatesByPosition[prevPosition] != null && _candidatesByPosition[prevPosition]!.isNotEmpty) {
          _displayingCandidate = _candidatesByPosition[prevPosition]![0];
        } else {
          _displayingCandidate = null;
        }
      });
    }
  }

  // --- SUBMISSION LOGIC ---
  
  // Pop-up 2: Final Ballot Summary
  Future<void> _showVoteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Confirm Your Ballot', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Are you sure you want to submit your final ballot? You cannot change these votes after submitting.'),
                const SizedBox(height: 20),
                const Text('Your official selections:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // This creates the list of chosen candidates
                ..._positionNames.map((position) {
                  final candidateId = _selectedCandidates[position];
                  final candidate = _candidatesByPosition[position]?.firstWhere(
                    (c) => c['candidate_id'] == candidateId, 
                    orElse: () => null
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('• $position: ${candidate?['name'] ?? 'None'}'),
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Review Again', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(), 
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Submit Ballot', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); 
                _confirmAndSubmitVote(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndSubmitVote() async {
    try {
      await ApiService.submitVote(_activePollId!, _selectedCandidates);

      if (!mounted) return;
      setState(() {
        _isJustSubmitted = true;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not submit vote. You might have already voted.')),
      );
    }
  }

  void _attemptSubmit() {
    if (!_hasSelectedAll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a candidate for every position before submitting.')),
      );
      return;
    }
    _showVoteConfirmationDialog();
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 18)));

    // Status 1: Expired
    if (_isExpired) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text("This ballot has expired.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Voting is no longer allowed for this election.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Status 2: Already Voted
    if (_hasAlreadyVoted && !_isJustSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, size: 80, color: primaryColor),
            const SizedBox(height: 20),
            const Text("Already Voted", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("You have already successfully cast your ballot for:\n$_activePollTitle", textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: widget.onReturnToDashboard,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go back to dashboard"),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            )
          ],
        ),
      );
    }

    // Status 3: Just Finished Voting
    if (_isJustSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Thank You For Voting!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your ballot has been successfully recorded.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: widget.onReturnToDashboard, 
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go back to dashboard"),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            )
          ],
        ),
      );
    }

    // Status 4: Empty Ballot
    if (_positionNames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ballot_outlined, size: 90, color: Colors.grey),
            SizedBox(height: 20),
            Text("No Candidates Available", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey)),
            Text("Candidates have not been added to this election yet.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    // --- MAIN VOTING UI ---
    final currentPositionName = _positionNames[_currentPositionIndex];
    final candidatesForPosition = _candidatesByPosition[currentPositionName] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;

          Widget mainContent = Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- TOP POSITION BAR ---
                Container(
                  width: isMobile ? double.infinity : 350,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_left), onPressed: _currentPositionIndex == 0 ? null : _goToPreviousPosition),
                      Flexible(child: Text(currentPositionName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.arrow_right), onPressed: _currentPositionIndex == _positionNames.length - 1 ? null : _goToNextPosition),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- LIST OF CANDIDATES ---
                Expanded(
                  child: ListView.separated(
                    itemCount: candidatesForPosition.length,
                    // Give extra padding at the bottom so the last item isn't hidden behind the floating button
                    padding: const EdgeInsets.only(bottom: 80), 
                    separatorBuilder: (context, index) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final candidate = candidatesForPosition[index];
                      final isSelected = _selectedCandidates[currentPositionName] == candidate['candidate_id'];
                      final isDisplaying = _displayingCandidate?['candidate_id'] == candidate['candidate_id'];

                      return InkWell(
                        onTap: () => _setDisplayingCandidate(candidate),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isDisplaying ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.grey.shade200),
                            boxShadow: [if (isDisplaying) BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                                child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(candidate['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                    Text(candidate['party_name'] ?? 'Independent', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              // Custom Radio Button for Voting
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                                child: InkWell(
                                  onTap: () => _confirmCandidateSelection(currentPositionName, candidate),
                                  child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.grey.shade400, size: 28),
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

          // --- LAYOUT RENDERING ---
          if (isMobile) {
            return mainContent;
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: mainContent),
                Container(
                  width: 350,
                  margin: const EdgeInsets.only(top: 20, bottom: 20, right: 20),
                  child: _buildDetailPanel(),
                ),
              ],
            );
          }
        },
      ),
      
      // --- FLOATING SUBMIT BUTTON ---
      // Centers the button at the bottom of the screen
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      // Only shows the button if EVERY position has a selected candidate
      floatingActionButton: _hasSelectedAll 
          ? FloatingActionButton.extended(
              onPressed: _attemptSubmit,
              backgroundColor: primaryColor,
              icon: const Icon(Icons.how_to_vote, color: Colors.white),
              label: const Text("Submit Ballot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // --- RIGHT SIDE DETAIL PANEL ---
  Widget _buildDetailPanel() {
    if (_displayingCandidate == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: const Center(child: Text("Select a candidate to read more.", style: TextStyle(color: Colors.grey))),
      );
    }

    final candidate = _displayingCandidate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
              child: candidate['photo_url'] == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(candidate['name'] ?? 'Unknown Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: primaryColor), textAlign: TextAlign.center),
          ),
          Center(
            child: Text(candidate['party_name'] ?? 'Independent', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text("Platform / Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                candidate['description_platform'] ?? candidate['bio'] ?? 'No bio or platform provided for this candidate.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}