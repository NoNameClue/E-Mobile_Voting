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
        if (mounted) {
          setState(() {
            _polls = polls;
            if (_polls.isNotEmpty) {
              _selectedPollId = _polls[0]['poll_id'];
              _fetchResultsData();
            } else {
              _isLoading = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResultsData({bool showLoading = true}) async {
    if (_selectedPollId == null) return;
    if (showLoading && mounted) setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls/$_selectedPollId/results'),
      );

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

  // Groups the flat list of candidates into a map by their position
  Map<String, List<dynamic>> _groupResultsByPosition() {
    Map<String, List<dynamic>> grouped = {};
    for (var candidate in _resultsData) {
      String pos = candidate['position'];
      if (!grouped.containsKey(pos)) {
        grouped[pos] = [];
      }
      grouped[pos]!.add(candidate);
    }
    
    // Sort candidates within each position by votes (highest first)
    grouped.forEach((key, list) {
      list.sort((a, b) => (b['votes'] as int).compareTo(a['votes'] as int));
    });

    return grouped;
  }

  Widget _buildDropdown() {
    if (_polls.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPollId,
          items: _polls.map<DropdownMenuItem<int>>((poll) {
            return DropdownMenuItem<int>(
              value: poll['poll_id'],
              child: Text(
                poll['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
              ),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null && newValue != _selectedPollId) {
              setState(() {
                _selectedPollId = newValue;
                _fetchResultsData();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCandidateRow(dynamic candidate, int maxVotesInPosition) {
    double fraction = maxVotesInPosition > 0 ? (candidate['votes'] / maxVotesInPosition) : 0.0;
    String photoUrl = candidate['photo_url'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        // 🛠️ FIX: Pin to the top so the bar alignment ignores the text length below the image
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          // 1. Profile Picture and Name Column
          SizedBox(
            width: 110, // Increased width to fit larger text
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40, // 🛠️ FIX: Made avatar slightly bigger (was 30)
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage('${ApiConfig.baseUrl}/$photoUrl')
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                  onBackgroundImageError: photoUrl.isNotEmpty
                      ? (exception, stackTrace) => const Icon(Icons.broken_image)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  candidate['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // 🛠️ FIX: Made name slightly bigger (was 13)
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate['party_name'] ?? 'Independent',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12, // 🛠️ FIX: Made party slightly bigger (was 10)
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // 2. Horizontal Bar Graph
          Expanded(
            child: SizedBox(
              // 🛠️ ALIGNMENT FIX: The height matches the Avatar's exact diameter (40 * 2 = 80). 
              // This guarantees the bar centers perfectly with the picture.
              height: 80, 
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centers bar relative to the 80px height
                    children: [
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background track for the bar
                          Container(
                            height: 40, // Increased thickness to look better with the larger avatar
                            width: constraints.maxWidth * 0.75, // 75% max width
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // The actual colored animated vote bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            height: 40,
                            width: (constraints.maxWidth * 0.75) * fraction,
                            decoration: BoxDecoration(
                              color: Colors.green, // Active voting color
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      // 3. The Vote Count & Percentage Text
                      Expanded(
                        child: Text(
                          '${candidate['votes']} votes (${candidate['percentage']}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;
    var groupedData = _groupResultsByPosition();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 15,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Live Scoreboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Charts automatically update every 10 seconds.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              _buildDropdown(),
            ],
          ),
          const SizedBox(height: 30),

          // Content Section
          Expanded(
            child: _isLoading && _resultsData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _resultsData.isEmpty
                    ? const Center(
                        child: Text(
                          "No candidates or votes found for this election yet.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: groupedData.keys.length,
                        itemBuilder: (context, index) {
                          String position = groupedData.keys.elementAt(index);
                          List<dynamic> candidates = groupedData[position]!;

                          // Find the highest vote count in this position to scale the bars properly
                          int maxVotes = 0;
                          for (var c in candidates) {
                            if (c['votes'] > maxVotes) maxVotes = c['votes'];
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 25),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Position Title
                                  Text(
                                    "Live: ${position.toUpperCase()}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000B6B),
                                    ),
                                  ),
                                  const Divider(height: 30, thickness: 1),

                                  // Candidate Rows
                                  ...candidates.map((candidate) => _buildCandidateRow(candidate, maxVotes)).toList(),
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
  }
}