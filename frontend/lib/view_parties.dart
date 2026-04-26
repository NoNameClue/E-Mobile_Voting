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
  Map<String, String> _partyBios = {}; 

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
      final partyResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/$activePollId'));

      final List<dynamic> candidates = jsonDecode(candResponse.body);
      final List<dynamic> parties = jsonDecode(partyResponse.body);

      Map<String, List<dynamic>> grouped = {};
      Map<String, String> bios = {};

      for (var p in parties) {
        bios[p['name']] = p['platform_bio'] ?? '';
      }

      for (var c in candidates) {
        String party = c['party_name'] ?? 'Independent';
        if (!grouped.containsKey(party)) {
          grouped[party] = [];
        }
        grouped[party]!.add(c);
      }

      setState(() {
        _groupedParties = grouped;
        _partyBios = bios; 
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
    String platformBio = _partyBios[partyName] ?? ''; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
          contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                partyName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF000B6B), fontSize: 24, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
              if (platformBio.isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  height: 100, 
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 1.5)
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Text(
                        platformBio,
                        style: const TextStyle(
                          fontSize: 15, 
                          color: Colors.black, 
                          fontWeight: FontWeight.w500,
                          height: 1.4 // Better line spacing
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.6, 
            ),
            child: SizedBox(
              width: double.maxFinite, 
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  var candidate = candidates[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                        child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                      ),
                      title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Text(candidate['position'], style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close Window", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("View Parties", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              if (_polls.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxWidth: isMobile ? MediaQuery.of(context).size.width - 30 : 280), 
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true, 
                      value: _selectedPoll,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF000B6B), size: 28),
                      style: const TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.w800, fontSize: 16),
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
          const SizedBox(height: 30),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _groupedParties.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 90, color: Colors.white54),
                            SizedBox(height: 20),
                            Text("No Political Parties Yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            Text("No parties are available for the selected election.", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3, 
                          childAspectRatio: isMobile ? 1.4 : 1.6, // Taller cards for modern look
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: _groupedParties.length,
                        itemBuilder: (context, index) {
                          String partyName = _groupedParties.keys.elementAt(index);
                          List<dynamic> partyCandidates = _groupedParties[partyName]!;
                          String bioSnippet = _partyBios[partyName] ?? ''; 

                          return Card(
                            elevation: 8,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: InkWell(
                              onTap: () => _showPartyModal(partyName, partyCandidates),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.flag_rounded, color: primaryColor, size: 28),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            partyName.toUpperCase(),
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 0.5),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: bioSnippet.isNotEmpty 
                                        ? Text(
                                            bioSnippet,
                                            style: const TextStyle(
                                              fontSize: 14, 
                                              color: Colors.black87, 
                                              fontWeight: FontWeight.w500,
                                              height: 1.5
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : const Text(
                                            "No platform bio provided.",
                                            style: TextStyle(fontSize: 14, color: Colors.black45, fontStyle: FontStyle.italic),
                                          ),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${partyCandidates.length} Candidates", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                                        Row(
                                          children: [
                                            Text("View Lineup", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(width: 5),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.blue.shade700, size: 16)
                                          ],
                                        )
                                      ],
                                    )
                                  ],
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