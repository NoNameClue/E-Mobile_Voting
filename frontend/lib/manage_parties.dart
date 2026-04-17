import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ManageParties extends StatefulWidget {
  const ManageParties({super.key});

  @override
  State<ManageParties> createState() => _ManagePartiesState();
}

class _ManagePartiesState extends State<ManageParties> {
  List<dynamic> _polls = [];
  int? _selectedPollId;
  List<dynamic> _parties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  bool _isCurrentPollEnded() {
    if (_selectedPollId == null || _polls.isEmpty) return false;
    final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
    return poll != null && poll['status'] == 'Ended';
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (_polls.isEmpty) {
        final pollRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
        if (pollRes.statusCode == 200) {
          _polls = jsonDecode(pollRes.body);
          if (_polls.isNotEmpty && _selectedPollId == null) {
            _selectedPollId = _polls[0]['poll_id'];
          }
        }
      }

      if (_selectedPollId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 🛠️ FIX 1: Changed from /api/parties/lineups to /api/parties
      final partyRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties'));
      final candsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$_selectedPollId'));

      if (partyRes.statusCode == 200 && candsRes.statusCode == 200) {
        List<dynamic> baseParties = jsonDecode(partyRes.body);
        List<dynamic> candidates = jsonDecode(candsRes.body);

        List<dynamic> updatedParties = [];
        final standardPositions = ["President", "Vice President", "Secretary", "Treasurer", "Auditor", "PIO"];

        for (var p in baseParties) {
          Map<String, dynamic> lineup = { for (var pos in standardPositions) pos: null };
          
          for (var c in candidates) {
            if (c['party_name'] == p['party_name'] && lineup.containsKey(c['position'])) {
              lineup[c['position']] = c['name'];
            }
          }
          
          updatedParties.add({
            "party_id": p['party_id'],
            "party_name": p['party_name'],
            "lineup": lineup
          });
        }

        setState(() {
          _parties = updatedParties;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server.')));
      }
    }
  }

  Future<void> _createParty(String partyName) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/parties'),
        headers: {"Content-Type": "application/json"},
        // 🛠️ FIX 2: Changed "name" to "party_name" so Python accepts it
        body: jsonEncode({"party_name": partyName}),
      );

      if (response.statusCode == 200) {
        if (mounted) Navigator.of(context).pop(); 
        _fetchData(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party created successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to create party.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  Future<void> _deleteParty(int partyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/parties/$partyId'),
      );

      if (response.statusCode == 200) {
        _fetchData(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party deleted successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to delete party.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  void _showDeleteConfirmation1(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete $partyName?"),
        content: const Text("Are you sure you want to delete this party list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); 
              _showDeleteConfirmation2(partyId, partyName); 
            },
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation2(int partyId, String partyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Confirmation", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you REALLY sure? This action cannot be undone. Any candidates registered under this party will automatically be changed to 'Independent'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); 
              _deleteParty(partyId);  
            },
            child: const Text("Yes, I am absolutely sure"),
          ),
        ],
      ),
    );
  }

  void _showCreatePartyDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Party"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Party Name",
              hintText: "e.g. Progressive Youth Party",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Party name cannot be empty")));
                  return;
                }
                _createParty(nameController.text.trim());
              },
              child: const Text("Save / Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPollDropdown() {
    if (_polls.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 250), 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true, 
          value: _selectedPollId,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF000B6B)),
          style: const TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.bold, fontSize: 16),
          items: _polls.map<DropdownMenuItem<int>>((poll) {
            return DropdownMenuItem<int>(
              value: poll['poll_id'],
              child: Text(poll['title'] ?? "Election", style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (newPollId) {
            if (newPollId != null && newPollId != _selectedPollId) {
              setState(() {
                _selectedPollId = newPollId;
              });
              _fetchData(); 
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;
    bool isPollEnded = _isCurrentPollEnded(); 

    return Padding(
      padding: const EdgeInsets.all(20.0),
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
              const Text("Manage Parties", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildPollDropdown(),
                  Tooltip(
                    message: isPollEnded ? "You cannot create parties because the poll has ended." : "Create a new party",
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add, color: isPollEnded ? Colors.grey.shade500 : Colors.white),
                      label: Text(
                        "Create Party", 
                        style: TextStyle(color: isPollEnded ? Colors.grey.shade500 : Colors.white, fontWeight: FontWeight.bold)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPollEnded ? Colors.grey.shade300 : Colors.green, 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        elevation: isPollEnded ? 0 : 2, 
                      ),
                      onPressed: isPollEnded ? null : _showCreatePartyDialog, 
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Text(
            isPollEnded 
              ? "This election has ended. Party lineups are permanently locked." 
              : "Create political parties and view their assigned candidate lineups for the selected election.", 
            style: TextStyle(color: isPollEnded ? Colors.redAccent : Colors.grey, fontSize: 16, fontWeight: isPollEnded ? FontWeight.bold : FontWeight.normal)
          ),
          
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _parties.isEmpty
                    ? const Center(child: Text("No parties found. Create one to get started!"))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: isMobile ? 1.0 : 0.80, 
                        ),
                        itemCount: _parties.length,
                        itemBuilder: (context, index) {
                          final party = _parties[index];
                          final Map<String, dynamic> lineup = party['lineup'];
                          
                          bool isIndependent = party['party_name'].toString().toLowerCase() == "independent";
                          bool canDelete = !isIndependent && !isPollEnded;

                          return Card(
                            elevation: 3,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          party['party_name'].toUpperCase(),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF000B6B)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isIndependent) 
                                        Tooltip(
                                          message: isPollEnded ? "You cannot delete/edit it because the poll has ended." : "Delete Party",
                                          child: IconButton(
                                            icon: Icon(Icons.delete, color: isPollEnded ? Colors.grey.shade400 : Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: isPollEnded ? null : () => _showDeleteConfirmation1(party['party_id'], party['party_name']),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 30, thickness: 1),
                                  
                                  Expanded(
                                    child: ListView(
                                      children: lineup.entries.map((entry) {
                                        String position = entry.key;
                                        String? candidateName = entry.value;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 15.0), 
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 2, 
                                                child: Text(
                                                  position,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                flex: 3, 
                                                child: Text(
                                                  candidateName ?? "No Candidate",
                                                  style: TextStyle(
                                                    fontSize: 14, 
                                                    color: candidateName == null ? Colors.grey : Colors.black87,
                                                    fontStyle: candidateName == null ? FontStyle.italic : FontStyle.normal,
                                                    fontWeight: candidateName != null ? FontWeight.w500 : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
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
  }
}