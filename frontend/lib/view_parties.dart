import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ViewParties extends StatefulWidget {
  const ViewParties({super.key});

  @override
  State<ViewParties> createState() => _ViewPartiesState();
}

class _ViewPartiesState extends State<ViewParties> {
  final Color primaryColor = const Color(0xFF000B6B);
  
  List<dynamic> _polls = [];
  Map<String, dynamic>? _selectedPoll;
  
  bool _isLoading = true;
  Map<String, List<dynamic>> _groupedParties = {};

  @override
  void initState() {
    super.initState();
    _fetchPollsAndParties();
  }

  Future<void> _fetchPollsAndParties() async {
    try {
      if (_polls.isEmpty) {
        final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
        if (pollResponse.statusCode == 200) {
          final List<dynamic> allPolls = jsonDecode(pollResponse.body);
          
          _polls = allPolls.where((p) => 
            (p['is_published'] == 1 || p['is_published'] == true) && 
            (p['is_archived'] == 0 || p['is_archived'] == false)
          ).toList();

          if (_polls.isNotEmpty && _selectedPoll == null) {
            _selectedPoll = _polls.firstWhere(
              (p) => p['status'] != 'Ended', 
              orElse: () => _polls.first
            );
          }
        }
      }

      if (_selectedPoll == null) {
        setState(() => _isLoading = false);
        return;
      }

      await _fetchPartiesForPoll(_selectedPoll!);

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPartiesForPoll(Map<String, dynamic> poll) async {
    setState(() => _isLoading = true);
    try {
      int activePollId = poll['poll_id'];

      final candResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$activePollId'));
      final List<dynamic> candidates = jsonDecode(candResponse.body);

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

  void _onPollChanged(Map<String, dynamic>? newPoll) {
    if (newPoll != null && newPoll['poll_id'] != _selectedPoll?['poll_id']) {
      setState(() {
        _selectedPoll = newPoll;
      });
      _fetchPartiesForPoll(newPoll);
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
            textAlign: TextAlign.center,
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(context).size.height * 0.7, 
            ),
            child: SizedBox(
              width: double.maxFinite, 
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  var candidate = candidates[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                      child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(candidate['position']),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close", style: TextStyle(color: Color(0xFF000B6B))),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center, 
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MOBILE OVERFLOW FIX: Changed Row to Wrap ---
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("View Parties", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_polls.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxWidth: isMobile ? MediaQuery.of(context).size.width - 30 : 250), 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true, 
                      value: _selectedPoll,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF000B6B)),
                      style: const TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.bold),
                      items: _polls.map((poll) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: poll,
                          child: Text(poll["title"] ?? "Election", style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _onPollChanged,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF000B6B)))
                : _groupedParties.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 90, color: Colors.grey),
                            SizedBox(height: 20),
                            Text("No Political Parties Yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey), textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text("No parties are available for the selected election.", style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3, 
                          childAspectRatio: isMobile ? 2.5 : 3, 
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
                                  partyName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
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