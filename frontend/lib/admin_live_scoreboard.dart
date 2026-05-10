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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidate['party_name'] ?? 'Independent',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$votes",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF000B6B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 12,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * flexValue,
                            decoration: BoxDecoration(
                              color: const Color(0xFF000B6B),
                              borderRadius: BorderRadius.circular(16),
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

  Widget _buildPositionCard(String position, List<dynamic> candidates, int maxVotes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 25),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildScoreboardGrid(Map<String, List<dynamic>> groupedResults, int maxVotes) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    List<String> positions = groupedResults.keys.toList();
    
    List<Widget> leftColumn = [];
    List<Widget> rightColumn = [];

    for (int i = 0; i < positions.length; i++) {
      String pos = positions[i];
      Widget card = _buildPositionCard(pos, groupedResults[pos]!, maxVotes);
      
      if (isMobile) {
        leftColumn.add(card);
      } else {
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
    bool isMobile = MediaQuery.of(context).size.width < 800;

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

    for (var pos in groupedResults.keys) {
      groupedResults[pos]!.sort((a, b) => b['votes'].compareTo(a['votes']));
    }

    // Determine the current poll title
    String currentPollTitle = "";
    if (_selectedPollId != null && _polls.isNotEmpty) {
      final currentPoll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
      if (currentPoll != null) {
        currentPollTitle = currentPoll['title'] ?? "";
      }
    }

    Widget headerTexts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Live Election Scoreboard", 
          style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: Colors.white),
          softWrap: true,
        ),
        Text(
          "Real-time results. Updates automatically every 10 seconds.", 
          style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14),
          softWrap: true,
        ),
      ],
    );

    // Replaced Dropdown with a static Title Label
    Widget pollTitleWidget = currentPollTitle.isNotEmpty 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.how_to_vote, color: Color(0xFF000B6B), size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    currentPollTitle,
                    style: const TextStyle(
                      color: Color(0xFF000B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            headerTexts,
            const SizedBox(height: 15),
            pollTitleWidget,
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: headerTexts),
                const SizedBox(width: 15),
                pollTitleWidget,
              ],
            ),
          ],
          
          const SizedBox(height: 30),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _resultsData.isEmpty
                    ? const Center(child: Text("No live data found for this poll.", style: TextStyle(color: Colors.white)))
                    : _buildScoreboardGrid(groupedResults, maxVotes),
          ),
        ],
      ),
    );
  }
}