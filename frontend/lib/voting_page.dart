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

  // Constant for Abstain logic
  static const int ABSTAIN_ID = -1;

  // Computes if ALL positions have a selected candidate (or Abstain)
  bool get _hasSelectedAll {
    if (_positionNames.isEmpty) return false;
    for (String pos in _positionNames) {
      if (_selectedCandidates[pos] == null) return false; 
    }
    return true; 
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
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load voting data.";
      });
    }
  }

  // --- SUBMISSION LOGIC ---
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
                
                ..._positionNames.map((position) {
                  final candidateId = _selectedCandidates[position];
                  String displayName = "Abstain"; // Default text

                  if (candidateId != ABSTAIN_ID) {
                    final candidate = _candidatesByPosition[position]?.firstWhere(
                      (c) => c['candidate_id'] == candidateId, 
                      orElse: () => null
                    );
                    displayName = candidate?['name'] ?? 'Unknown';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('• $position: $displayName', style: TextStyle(color: candidateId == ABSTAIN_ID ? Colors.grey : Colors.black87)),
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
    setState(() => _isLoading = true);

    try {
      // Strip out the "Abstain" (-1) votes before sending to the database
      Map<String, int> finalValidVotes = {};
      
      _selectedCandidates.forEach((position, candidateId) {
        if (candidateId != null && candidateId != ABSTAIN_ID) {
          finalValidVotes[position] = candidateId;
        }
      });

      await ApiService.submitVote(_activePollId!, finalValidVotes);

      if (!mounted) return;
      setState(() {
        _isJustSubmitted = true;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not submit vote. You might have already voted.')),
      );
    }
  }

  // View Bio Modal
  void _showCandidateBio(dynamic candidate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.all(25),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                child: candidate['photo_url'] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
              ),
              const SizedBox(height: 15),
              Text(candidate['name'] ?? 'Unknown Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: primaryColor), textAlign: TextAlign.center),
              Text(candidate['party_name'] ?? 'Independent', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text("Platform / Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    candidate['description_platform'] ?? candidate['bio'] ?? 'No bio or platform provided.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      }
    );
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 18)));

    // Status 1: Expired
    if (_isExpired) {
      return _buildStatusScreen(Icons.timer_off, Colors.red, "This ballot has expired.", "Voting is no longer allowed for this election.");
    }

    // Status 2: Already Voted
    if (_hasAlreadyVoted && !_isJustSubmitted) {
      return _buildStatusScreen(Icons.how_to_vote, primaryColor, "Already Voted", "You have already successfully cast your ballot for:\n$_activePollTitle", showBackButton: true);
    }

    // Status 3: Just Finished Voting
    if (_isJustSubmitted) {
      return _buildStatusScreen(Icons.check_circle, Colors.green, "Thank You For Voting!", "Your ballot has been successfully recorded.", showBackButton: true);
    }

    // Status 4: Empty Ballot
    if (_positionNames.isEmpty) {
      return _buildStatusScreen(Icons.ballot_outlined, Colors.grey, "No Candidates Available", "Candidates have not been added to this election yet.");
    }

    // --- MAIN GOOGLE-FORM VOTING UI ---
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Keeps it from getting too wide on Desktop
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Official Ballot", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                    Text(_activePollTitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _positionNames.length,
                  itemBuilder: (context, index) {
                    final positionName = _positionNames[index];
                    final candidates = _candidatesByPosition[positionName] ?? [];
                    
                    // Add padding to the very last card so the FloatingActionButton doesn't cover it
                    double bottomMargin = (index == _positionNames.length - 1) ? 100 : 25;

                    return Card(
                      margin: EdgeInsets.only(bottom: bottomMargin),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              positionName.toUpperCase(), 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)
                            ),
                            const Divider(height: 30),
                            
                            ...candidates.map((candidate) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCandidates[positionName] == candidate['candidate_id'] 
                                      ? primaryColor.withOpacity(0.05) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedCandidates[positionName] == candidate['candidate_id'] 
                                        ? primaryColor.withOpacity(0.3) 
                                        : Colors.transparent
                                  )
                                ),
                                child: RadioListTile<int>(
                                  activeColor: primaryColor,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  
                                  // --- CHANGE: Photo and Info Icon placed here to show on LEFT ---
                                  secondary: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                                        child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: Colors.grey),
                                        tooltip: "View Platform",
                                        onPressed: () => _showCandidateBio(candidate),
                                      ),
                                    ],
                                  ),
                                  
                                  // --- CHANGE: Places Radio Button on the RIGHT ---
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  
                                  title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${candidate['party_name'] ?? 'Independent'} • ${candidate['course_year'] ?? ''}'),
                                  
                                  value: candidate['candidate_id'],
                                  groupValue: _selectedCandidates[positionName],
                                  onChanged: (val) {
                                    setState(() => _selectedCandidates[positionName] = val);
                                  },
                                ),
                              );
                            }),

                            // --- Abstain Option ---
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: _selectedCandidates[positionName] == ABSTAIN_ID 
                                      ? Colors.grey.withOpacity(0.1) 
                                      : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: RadioListTile<int>(
                                activeColor: Colors.grey,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                
                                // Leading Spacer to match candidate alignment
                                secondary: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(backgroundColor: Colors.transparent, child: Icon(Icons.do_not_disturb, color: Colors.grey)),
                                    SizedBox(width: 48), // Matches the width of the info IconButton to align text perfectly
                                  ],
                                ),
                                
                                // Radio on the right
                                controlAffinity: ListTileControlAffinity.trailing,
                                
                                title: const Text("Abstain", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                subtitle: const Text("Skip voting for this position", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                value: ABSTAIN_ID,
                                groupValue: _selectedCandidates[positionName],
                                onChanged: (val) {
                                  setState(() => _selectedCandidates[positionName] = val);
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      // --- FLOATING SUBMIT BUTTON ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _hasSelectedAll 
          ? FloatingActionButton.extended(
              onPressed: _showVoteConfirmationDialog,
              backgroundColor: Colors.green,
              elevation: 4,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text("SUBMIT BALLOT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            )
          : null,
    );
  }

  // Reusable widget for Status Screens (Expired, Finished, Empty)
  Widget _buildStatusScreen(IconData icon, Color color, String title, String subtitle, {bool showBackButton = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          if (showBackButton) ...[
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: widget.onReturnToDashboard,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go back to dashboard"),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            )
          ]
        ],
      ),
    );
  }
}