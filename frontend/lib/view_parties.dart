import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart'; // Adjust based on your actual config file

class ViewParties extends StatefulWidget {
  const ViewParties({super.key});

  @override
  State<ViewParties> createState() => _ViewPartiesState();
}

class _ViewPartiesState extends State<ViewParties> {
  bool _isLoading = true;
  Map<String, List<dynamic>> _groupedParties = {};

  @override
  void initState() {
    super.initState();
    _fetchAndGroupParties();
  }

  Future<void> _fetchAndGroupParties() async {
    try {
      // 1. Fetch active poll (adjust endpoint if needed to get current poll id)
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      final List<dynamic> polls = jsonDecode(pollResponse.body);
      final publishedPoll = polls.firstWhere((p) => p['is_published'] == true || p['is_published'] == 1, orElse: () => null);

      if (publishedPoll == null) {
        setState(() => _isLoading = false);
        return;
      }

      int activePollId = publishedPoll['poll_id'];

      // 2. Fetch candidates for this poll
      final candResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$activePollId'));
      final List<dynamic> candidates = jsonDecode(candResponse.body);

      // 3. Group by Party (Option A Logic)
      Map<String, List<dynamic>> grouped = {};
      for (var c in candidates) {
        String party = c['party_name'] ?? 'Independent';
        if (!grouped.containsKey(party)) {
          grouped[party] = [];
        }
        grouped[party]!.add(c);
      }

      setState(() {
        _groupedParties = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showPartyModal(String partyName, List<dynamic> candidates) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            partyName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                var candidate = candidates[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: candidate['photo_url'] != null ? NetworkImage(candidate['photo_url']) : null,
                    child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(candidate['position']),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close", style: TextStyle(color: Color(0xFF000B6B))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF000B6B)));
    }

    if (_groupedParties.isEmpty) {
      return const Center(child: Text("No parties available for the active election.", style: TextStyle(fontSize: 18)));
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("View Parties", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1, // Responsive Grid
                childAspectRatio: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _groupedParties.length,
              itemBuilder: (context, index) {
                String partyName = _groupedParties.keys.elementAt(index);
                List<dynamic> partyCandidates = _groupedParties[partyName]!;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    onTap: () => _showPartyModal(partyName, partyCandidates),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Text(
                        partyName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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