import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'api_service.dart';

class MyVotesView extends StatefulWidget {
  const MyVotesView({super.key});

  @override
  State<MyVotesView> createState() => _MyVotesViewState();
}

class _MyVotesViewState extends State<MyVotesView> {
  final Color primaryColor = const Color(0xFF000B6B);

  List polls = [];
  Map<String, dynamic>? selectedPoll;
  bool loading = true;

  // New states for the side panel
  dynamic _displayingCandidate;
  Map<String, dynamic> _candidateStats = {}; // Stores live votes/percentages keyed by candidate name

  @override
  void initState() {
    super.initState();
    loadVotes();
  }

  Future<void> loadVotes() async {
    try {
      List data = await ApiService.getMyVotes();

      setState(() {
        polls = data;
        if (polls.isNotEmpty) {
          selectedPoll = polls.first as Map<String, dynamic>;
        }
      });

      // If we have a poll, fetch the live stats for its candidates and auto-select the first candidate
      if (selectedPoll != null) {
        await _fetchLiveStatsForPoll(selectedPoll!);
        
        if (selectedPoll!['candidates'] != null && selectedPoll!['candidates'].isNotEmpty) {
          _displayingCandidate = selectedPoll!['candidates'][0];
        }
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // Fetches live results from the server to get percentages and vote counts
  Future<void> _fetchLiveStatsForPoll(Map<String, dynamic> poll) async {
    try {
      // Safely grab the poll ID whether the backend calls it 'poll_id' or 'id'
      int pollId = poll['poll_id'] ?? poll['id'];
      
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/results'));
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        Map<String, dynamic> stats = {};
        
        // Map the results by candidate name so we can easily look them up
        for (var c in results) {
          stats[c['name']] = {
            'votes': c['votes'],
            'percentage': c['percentage']
          };
        }
        
        setState(() {
          _candidateStats = stats;
        });
      }
    } catch (e) {
      // If fetching live stats fails, we just show N/A
    }
  }

  void _onPollChanged(Map<String, dynamic>? newPoll) async {
    if (newPoll == null) return;
    
    setState(() {
      selectedPoll = newPoll;
      _displayingCandidate = newPoll['candidates'] != null && newPoll['candidates'].isNotEmpty 
          ? newPoll['candidates'][0] 
          : null;
    });
    
    await _fetchLiveStatsForPoll(newPoll);
  }

  void _setDisplayingCandidate(dynamic candidate) {
    setState(() {
      _displayingCandidate = candidate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (polls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote_outlined, size: 90, color: Colors.grey),
            SizedBox(height: 20),
            Text("No Votes Yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey)),
            SizedBox(height: 10),
            Text("You haven't participated in any elections yet.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    List candidates = selectedPoll!["candidates"] ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;

        Widget mainContent = Padding(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ROW (Replaces the blue AppBar) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Votes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
                  
                  // Clean Dropdown Menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedPoll,
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        items: polls.map((poll) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: poll as Map<String, dynamic>,
                            child: Text(poll["poll_title"] ?? "Election"),
                          );
                        }).toList(),
                        onChanged: _onPollChanged,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // --- LIST OF VOTED CANDIDATES ---
              Expanded(
                child: ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    var candidate = candidates[index];
                    final isDisplaying = _displayingCandidate?['name'] == candidate['name'];

                    return InkWell(
                      onTap: () => _setDisplayingCandidate(candidate),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isDisplaying ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            if (isDisplaying)
                              BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
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
                                  Text(
                                    candidate["position"] ?? "Position",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    candidate["name"] ?? "Unknown",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    candidate["party"] ?? "Independent",
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
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

        // --- RENDER LAYOUT (Mobile vs Desktop) ---
        if (isMobile) {
          return Column(
            children: [
              Expanded(flex: 3, child: mainContent),
              if (_displayingCandidate != null)
                Expanded(flex: 2, child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                  child: _buildDetailPanel(),
                )),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: mainContent),
              Container(
                width: 350,
                margin: const EdgeInsets.only(top: 30, bottom: 30, right: 30),
                child: _buildDetailPanel(),
              ),
            ],
          );
        }
      },
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
    
    // Fetch live stats from our dictionary (Defaults to 0 if not found)
    final stats = _candidateStats[candidateName] ?? {'votes': 0, 'percentage': 0.0};
    final int totalVotes = stats['votes'];
    final double percentage = (stats['percentage'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
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
          Text(
            (candidate['position'] ?? 'POSITION').toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            candidate['party'] ?? 'Independent',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Live Election Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 15),

          // --- STATS BOXES ---
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
    );
  }
}