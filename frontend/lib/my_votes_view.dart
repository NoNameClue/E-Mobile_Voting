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
  bool _isLoading = true;

  Map<int, Map<String, dynamic>> _pollStats = {};
  Map<int, List<dynamic>> _pollVotes = {};
  Set<int> _votedPollIds = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final pollResponse =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));

      if (pollResponse.statusCode == 200) {
        final List<dynamic> allPolls = jsonDecode(pollResponse.body);

        _polls = allPolls
            .where((p) =>
                (p['is_published'] == 1 || p['is_published'] == true))
            .toList();

        // ✅ DESCENDING ORDER (NEWEST FIRST)
        _polls.sort((a, b) => (b['poll_id']).compareTo(a['poll_id']));
      }

      await _loadUserVotes();
      await _loadAllStats();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/users/me/votes"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      for (var vote in data) {
        _votedPollIds.add(vote['poll_id']);
        _pollVotes[vote['poll_id']] = vote['candidates'];
      }
    }
  }

  Future<void> _loadAllStats() async {
    for (var poll in _polls) {
      int pollId = poll['poll_id'];

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls/$pollId/results'),
      );

      if (res.statusCode == 200) {
        final List results = jsonDecode(res.body);

        Map<String, dynamic> stats = {};

        for (var c in results) {
          stats[c['name']] = {
            'votes': c['votes'],
            'percentage': c['percentage'],
          };
        }

        _pollStats[pollId] = stats;
      }
    }
  }

  bool _isPollEnded(Map poll) {
    if (poll['status'] == 'Ended') return true;

    if (poll['end_time'] != null) {
      DateTime end = DateTime.parse(poll['end_time']);
      return end.isBefore(DateTime.now());
    }

    return false;
  }

  Widget _buildElectionCard(Map poll) {
    int pollId = poll['poll_id'];
    bool isEnded = _isPollEnded(poll);
    bool hasVoted = _votedPollIds.contains(pollId);

    final List<dynamic> votes =
      List<dynamic>.from(_pollVotes[pollId] ?? []);
    final stats = _pollStats[pollId] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),

        // =========================
        // HEADER (COLLAPSED VIEW)
        // =========================
        title: Text(
          poll['title'] ?? 'Election',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        subtitle: Text(
          isEnded
              ? "Ended • ${hasVoted ? "You voted" : "You did not vote"}"
              : "Ongoing Election",
          style: const TextStyle(fontSize: 12),
        ),

        // =========================
        // EXPANDED CONTENT (TOP = SUMMARY)
        // =========================
        children: [
          const SizedBox(height: 8),

          // ✅ SUMMARY AT TOP (as requested)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              hasVoted
                  ? "Your vote details for this election:"
                  : "No vote recorded for this election.",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),

          const SizedBox(height: 12),

          // =========================
          // DETAILS LIST
          // =========================
          if (!hasVoted)
            const Text(
              "You did not participate in this election.",
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: votes.map<Widget>((dynamic candidate) {
                final Map<String, dynamic> c =
                    Map<String, dynamic>.from(candidate);

                final String name = c['name'] ?? '';
                final stats = _pollStats[pollId] ?? {};
                final s = stats[name] ?? {'votes': 0, 'percentage': 0};

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: c['photo'] != null
                            ? NetworkImage(
                                '${ApiConfig.baseUrl}/${c["photo"]}')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${s['votes']} votes"),
                          Text("${s['percentage']}%"),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: _polls.map<Widget>((poll) => _buildElectionCard(poll)).toList(),
      ),
    );
  }
}