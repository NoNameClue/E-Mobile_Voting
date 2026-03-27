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
  List<dynamic> _polls = []; // Stores all published polls for the dropdown
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

  // --- 1. FETCH ALL POLLS & START SESSION ---
  Future<void> _initializeVotingSession() async {
    try {
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode != 200) throw Exception("Failed to fetch polls");
      
      final List<dynamic> allPolls = jsonDecode(pollResponse.body);
      
      // Filter out only published polls for the dropdown
      _polls = allPolls.where((p) => p['is_published'] == true || p['is_published'] == 1).toList();
      
      if (_polls.isEmpty) {
        setState(() { _isLoading = false; _errorMessage = "No active elections right now."; });
        return;
      }

      // Automatically select the first poll that hasn't ended (or just the first one if all are ended)
      final defaultPoll = _polls.firstWhere(
        (p) => p['status'] != 'Ended',
        orElse: () => _polls.first,
      );

      await _loadPollData(defaultPoll);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load voting data.";
      });
    }
  }

  // --- 2. LOAD DATA FOR THE SELECTED POLL ---
  Future<void> _loadPollData(Map<String, dynamic> poll) async {
    setState(() => _isLoading = true);

    try {
      _activePollId = poll['poll_id'];
      _activePollTitle = poll['title']; 
      
      // Reset states when switching polls
      _selectedCandidates.clear();
      _isJustSubmitted = false;
      _hasAlreadyVoted = false;
      _isExpired = false;
      _errorMessage = null;

      // Check if Poll is Expired
      if (poll['status'] == 'Ended') {
        setState(() { _isExpired = true; _isLoading = false; });
        return; 
      }

      // Check if User Already Voted
      bool voted = await ApiService.checkVoteStatus(_activePollId!);
      if (voted) {
        setState(() { _hasAlreadyVoted = true; _isLoading = false; });
        return; 
      }

      // Fetch and Group Candidates
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
        _errorMessage = "Failed to load poll data.";
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

  // --- UI WIDGETS ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Official Ballot", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                Text(_activePollTitle, style: const TextStyle(fontSize: 16, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          
          // --- THE NEW DROPDOWN MENU ---
          if (_polls.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _activePollId,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  items: _polls.map((poll) {
                    return DropdownMenuItem<int>(
                      value: poll["poll_id"],
                      child: Text(poll["title"] ?? "Election", style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (newPollId) {
                    if (newPollId != null && newPollId != _activePollId) {
                      final newPoll = _polls.firstWhere((p) => p['poll_id'] == newPollId);
                      _loadPollData(newPoll);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVotingList() {
    return ListView.builder(
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
                  final isSelected = _selectedCandidates[positionName] == candidate['candidate_id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? primaryColor.withOpacity(0.3) : Colors.transparent
                      )
                    ),
                    child: RadioListTile<int>(
                      activeColor: primaryColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      
                      // Left Side (Photo and Info)
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
                      
                      // Right Side Radio Button
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
                        SizedBox(width: 48), 
                      ],
                    ),
                    
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    // --- DECIDE WHICH SCREEN TO SHOW IN THE BODY ---
    if (_isLoading) {
      bodyContent = Center(child: CircularProgressIndicator(color: primaryColor));
    } else if (_errorMessage != null) {
      bodyContent = Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 18)));
    } else if (_isExpired) {
      bodyContent = Center(
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
    } else if (_hasAlreadyVoted && !_isJustSubmitted) {
      bodyContent = Center(
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
    } else if (_isJustSubmitted) {
      bodyContent = Center(
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
    } else if (_positionNames.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ballot_outlined, size: 90, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("No Candidates Available", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey)),
            const Text("Candidates have not been added to this election yet.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    } else {
      // Show the actual Google-Form style voting list
      bodyContent = _buildVotingList();
    }

    // --- MAIN SCAFFOLD WRAPPER ---
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      
      // Submit Button Rules: Must be Active, Not already voted, loaded, AND has selected all
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_hasSelectedAll && !_isExpired && !_hasAlreadyVoted && !_isJustSubmitted && !_isLoading && _positionNames.isNotEmpty) 
          ? FloatingActionButton.extended(
              onPressed: _showVoteConfirmationDialog,
              backgroundColor: Colors.green,
              elevation: 4,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text("SUBMIT BALLOT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            )
          : null,
          
      // Ensure the top header and dropdown is always visible NO MATTER the status of the poll!
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: bodyContent),
            ],
          ),
        ),
      ),
    );
  }
}