import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AdminLiveScoreboard extends StatefulWidget {
  const AdminLiveScoreboard({super.key});

  @override
  State<AdminLiveScoreboard> createState() => _AdminLiveScoreboardState();
}

class _AdminLiveScoreboardState extends State<AdminLiveScoreboard> {
  List<dynamic> _polls = [];
  int? _selectedPollId;
  List<dynamic> _resultsData = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchPolls();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_selectedPollId != null) {
        _fetchResultsData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final polls = jsonDecode(response.body);
        setState(() {
          // Only Active polls make sense for LIVE scoreboard
          _polls = polls.where((p) => p['status'] == 'Active').toList();
          if (_polls.isNotEmpty) {
            _selectedPollId = _polls[0]['poll_id'];
            _fetchResultsData();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResultsData({bool showLoading = true}) async {
    if (_selectedPollId == null) return;
    if (showLoading && mounted) setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$_selectedPollId/results'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _resultsData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCandidateRow(Map<String, dynamic> candidate, int maxVotes) {
    int votes = candidate['votes'];
    double flexValue = maxVotes > 0 ? (votes / maxVotes) : 0;
    String photoUrl = candidate['photo_url'] ?? '';
    String fullImageUrl = photoUrl.isNotEmpty ? "${ApiConfig.baseUrl}/$photoUrl" : "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              image: fullImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(fullImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fullImageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 15),

          // Name & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "$votes",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF000B6B)),
                    ),
                  ],
                ),
                Text(
                  candidate['party_name'] ?? 'Independent',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Animated Progress Bar
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 12,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * flexValue,
                            decoration: BoxDecoration(
                              color: const Color(0xFF000B6B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ NEW: A helper widget that builds the position card independently
  Widget _buildPositionCard(String position, List<dynamic> candidates, int maxVotes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 25),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Live: ${position.toUpperCase()}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000B6B),
              ),
            ),
            const Divider(height: 30, thickness: 1),
            ...candidates.map((candidate) => _buildCandidateRow(candidate, maxVotes)).toList(),
          ],
        ),
      ),
    );
  }

  // 🛠️ NEW: Splitting logic into two columns for maximum screen real estate
  Widget _buildScoreboardGrid(Map<String, List<dynamic>> groupedResults, int maxVotes) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    List<String> positions = groupedResults.keys.toList();
    
    List<Widget> leftColumn = [];
    List<Widget> rightColumn = [];

    for (int i = 0; i < positions.length; i++) {
      String pos = positions[i];
      Widget card = _buildPositionCard(pos, groupedResults[pos]!, maxVotes);
      
      if (isMobile) {
        // If mobile, stack everything into one single left column
        leftColumn.add(card);
      } else {
        // If desktop/tablet, stagger them into two columns
        if (i % 2 == 0) {
          leftColumn.add(card);
        } else {
          rightColumn.add(card);
        }
      }
    }

    return SingleChildScrollView(
      child: isMobile 
        ? Column(children: leftColumn)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: leftColumn)),
              const SizedBox(width: 25),
              Expanded(child: Column(children: rightColumn)),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Process Data
    int maxVotes = 0;
    Map<String, List<dynamic>> groupedResults = {};

    for (var cand in _resultsData) {
      if (cand['votes'] > maxVotes) {
        maxVotes = cand['votes'];
      }
      String pos = cand['position'];
      if (!groupedResults.containsKey(pos)) {
        groupedResults[pos] = [];
      }
      groupedResults[pos]!.add(cand);
    }

    // Sort Candidates by Votes
    for (var pos in groupedResults.keys) {
      groupedResults[pos]!.sort((a, b) => b['votes'].compareTo(a['votes']));
    }

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Live Election Scoreboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Real-time results. Updates automatically every 10 seconds.", style: TextStyle(color: Colors.white70)),
                ],
              ),
              if (_polls.isNotEmpty)
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedPollId,
                      items: _polls.map((poll) {
                        return DropdownMenuItem<int>(
                          value: poll['poll_id'],
                          child: Text(poll['title'], overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPollId = val;
                            _fetchResultsData();
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resultsData.isEmpty
                    ? const Center(child: Text("No live data found for this poll.", style: TextStyle(color: Colors.white)))
                    // 🛠️ REPLACED: Uses the new two-column layout grid instead of a single ListView
                    : _buildScoreboardGrid(groupedResults, maxVotes),
          ),
        ],
      ),
    );
  }
}