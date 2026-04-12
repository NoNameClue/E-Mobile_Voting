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
  List<dynamic> _polls = []; 
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

  static const int ABSTAIN_ID = -1;

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

  Future<void> _initializeVotingSession() async {
    try {
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollResponse.statusCode != 200) throw Exception("Failed to fetch polls");
      
      final List<dynamic> allPolls = jsonDecode(pollResponse.body);
      _polls = allPolls.where((p) => p['is_published'] == true || p['is_published'] == 1).toList();
      
      if (_polls.isEmpty) {
        setState(() { _isLoading = false; _errorMessage = "No active elections right now."; });
        return;
      }

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

  Future<void> _loadPollData(Map<String, dynamic> poll) async {
    setState(() => _isLoading = true);
    try {
      _activePollId = poll['poll_id'];
      _activePollTitle = poll['title']; 
      _selectedCandidates.clear();
      _isJustSubmitted = false;
      _hasAlreadyVoted = false;
      _isExpired = false;
      _errorMessage = null;

      if (poll['status'] == 'Ended') {
        setState(() { _isExpired = true; _isLoading = false; });
        return; 
      }

      bool voted = await ApiService.checkVoteStatus(_activePollId!);
      if (voted) {
        setState(() { _hasAlreadyVoted = true; _isLoading = false; });
        return; 
      }

      List rawCandidates = await ApiService.fetchCandidates(_activePollId!);
      Map<String, List<dynamic>> grouped = {};
      for (var candidate in rawCandidates) {
        String position = candidate["position"];
        if (!grouped.containsKey(position)) grouped[position] = [];
        grouped[position]!.add(candidate);
      }

      setState(() {
        _candidatesByPosition = grouped;
        _positionNames = grouped.keys.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = "Failed to load poll data."; });
    }
  }

  Future<void> _confirmAndSubmitVote() async {
    setState(() => _isLoading = true);
    try {
      Map<String, int> finalValidVotes = {};
      _selectedCandidates.forEach((position, candidateId) {
        if (candidateId != null && candidateId != ABSTAIN_ID) {
          finalValidVotes[position] = candidateId;
        }
      });
      await ApiService.submitVote(_activePollId!, finalValidVotes);
      if (!mounted) return;
      setState(() { _isJustSubmitted = true; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Could not submit vote.')));
    }
  }

  void _showVoteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Confirm Your Ballot', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to submit your final ballot? You cannot change these votes after submitting.'),
        actions: [
          TextButton(child: const Text('Review Again'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Submit Ballot', style: TextStyle(color: Colors.white)),
            onPressed: () { Navigator.pop(context); _confirmAndSubmitVote(); },
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
                Text(positionName.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                const Divider(height: 30),
                ...candidates.map((candidate) {
                  return RadioListTile<int>(
                    activeColor: primaryColor,
                    title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${candidate['party_name'] ?? 'Independent'}'),
                    secondary: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                        child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    value: candidate['candidate_id'],
                    groupValue: _selectedCandidates[positionName],
                    onChanged: (val) => setState(() => _selectedCandidates[positionName] = val),
                  );
                }),
                RadioListTile<int>(
                  activeColor: Colors.grey,
                  title: const Text("Abstain", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  value: ABSTAIN_ID,
                  groupValue: _selectedCandidates[positionName],
                  onChanged: (val) => setState(() => _selectedCandidates[positionName] = val),
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

    if (_isLoading) {
      bodyContent = Center(child: CircularProgressIndicator(color: primaryColor));
    } else if (_errorMessage != null) {
      bodyContent = Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 18, color: Colors.white)));
    } else if (_isExpired) {
      bodyContent = _buildStatusView(Icons.timer_off, "Ballot Expired", "Voting is no longer allowed.", Colors.redAccent);
    } else if (_hasAlreadyVoted && !_isJustSubmitted) {
      bodyContent = _buildStatusView(Icons.how_to_vote, "Already Voted", "Your ballot has been recorded.", Colors.amber);
    } else if (_isJustSubmitted) {
      bodyContent = _buildStatusView(Icons.check_circle, "Submitted!", "Thank you for voting.", Colors.greenAccent);
    } else if (_positionNames.isEmpty) {
      bodyContent = _buildStatusView(Icons.ballot_outlined, "No Candidates", "Poll not yet configured.", Colors.white54);
    } else {
      bodyContent = _buildVotingList();
    }

    return Scaffold(
      // 1. THIS IS THE MAGIC LINE! Transparent so the Dashboard's background shows!
      backgroundColor: Colors.transparent, 
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (_hasSelectedAll && !_isExpired && !_hasAlreadyVoted && !_isJustSubmitted && !_isLoading && _positionNames.isNotEmpty) 
          ? FloatingActionButton.extended(
              onPressed: _showVoteConfirmationDialog,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text("SUBMIT BALLOT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
          
      // 2. NO SYSTEM BACKGROUND HERE! Just the content.
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

  Widget _buildStatusView(IconData icon, String title, String sub, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: widget.onReturnToDashboard,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Go back to dashboard"),
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Official Ballot", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_activePollTitle, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
          if (_polls.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
}