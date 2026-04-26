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

      final partyRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/$_selectedPollId'));
      final candsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$_selectedPollId'));

      if (partyRes.statusCode == 200 && candsRes.statusCode == 200) {
        List<dynamic> baseParties = jsonDecode(partyRes.body);
        List<dynamic> candidates = jsonDecode(candsRes.body);

        List<dynamic> updatedParties = [];
        final standardPositions = ["President", "Vice President", "Secretary", "Treasurer", "Auditor", "PIO"];

        for (var p in baseParties) {
          Map<String, dynamic> lineup = { for (var pos in standardPositions) pos: null };
          
          for (var c in candidates) {
            if (c['party_name'] == p['name'] && lineup.containsKey(c['position'])) {
              String fName = c['first_name'] ?? '';
              String mName = c['middle_name'] ?? '';
              String lName = c['last_name'] ?? '';
              String fullName = "$fName $mName $lName".replaceAll('  ', ' ').trim();
              lineup[c['position']] = fullName;
            }
          }
          
          updatedParties.add({
            "party_id": p['party_id'],
            "name": p['name'], 
            "platform_bio": p['platform_bio'],
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

  Future<void> _createParty(String partyName, String platformBio) async {
    if (_selectedPollId == null) return;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/parties'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "poll_id": _selectedPollId,
          "name": partyName,
          "platform_bio": platformBio
        }),
      );

      if (response.statusCode == 200) {
        _fetchData(); 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party created successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to create party.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
    }
  }

  Future<void> _updateParty(int partyId, String partyName, String platformBio) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/parties/$partyId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": partyName,
          "platform_bio": platformBio
        }),
      );

      if (response.statusCode == 200) {
        _fetchData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to update party.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.')));
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

void _showPartyDialog({Map<String, dynamic>? party}) {
    final bool isEdit = party != null;
    final TextEditingController nameController = TextEditingController(text: isEdit ? party['name'] : '');
    final TextEditingController bioController = TextEditingController(text: isEdit ? (party['platform_bio'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? "Edit Party" : "Create New Party", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Party Name",
                    hintText: "e.g. Progressive Youth Party",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50
                  ),
                  autofocus: !isEdit,
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: bioController,
                  minLines: 4, 
                  maxLines: 4, 
                  maxLength: 300, 
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: "Platform / Bio (Optional)",
                    hintText: "Briefly describe the party's vision...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey.shade50
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000B6B), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Party name cannot be empty")));
                  return;
                }
                Navigator.pop(context);
                
                if (isEdit) {
                  _updateParty(party['party_id'], nameController.text.trim(), bioController.text.trim());
                } else {
                  _createParty(nameController.text.trim(), bioController.text.trim());
                }
              },
              child: Text(isEdit ? "Save Changes" : "Save / Create", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPollDropdown() {
    if (_polls.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 280), 
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true, 
          value: _selectedPollId,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF000B6B), size: 28),
          style: const TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.w800, fontSize: 16),
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

    bool isPollPublished = false;
    if (_selectedPollId != null && _polls.isNotEmpty) {
      final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
      isPollPublished = poll != null && (poll['is_published'] == true || poll['is_published'] == 1);
    }
    
    bool isLocked = isPollEnded || isPollPublished;
    String lockReason = isPollEnded ? "Poll has ended." : "Poll is already published.";

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Parties", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildPollDropdown(),
                  Tooltip(
                    message: isLocked ? "Creation locked: $lockReason" : "Create a new party",
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add_rounded, color: isLocked ? Colors.grey.shade500 : Colors.white, size: 22),
                      label: Text(
                        "Create Party", 
                        style: TextStyle(color: isLocked ? Colors.grey.shade500 : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? Colors.grey.shade300 : Colors.green, 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isLocked ? 0 : 4, 
                      ),
                      onPressed: isLocked ? null : () => _showPartyDialog(), 
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          Text(
            isLocked 
              ? "This election is locked ($lockReason). Party lineups are permanently locked." 
              : "Create political parties and view their assigned candidate lineups for the selected election.", 
            style: TextStyle(color: isLocked ? Colors.redAccent.shade100 : Colors.white70, fontSize: 16, fontWeight: isLocked ? FontWeight.bold : FontWeight.normal)
          ),
          
          const SizedBox(height: 30),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _parties.isEmpty
                    ? const Center(child: Text("No parties found. Create one to get started!", style: TextStyle(color: Colors.white, fontSize: 18)))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 3,
                          crossAxisSpacing: 25,
                          mainAxisSpacing: 25,
                          childAspectRatio: isMobile ? 0.9 : 0.70, // Allowed more height for the bigger bio boxes
                        ),
                        itemCount: _parties.length,
                        itemBuilder: (context, index) {
                          final party = _parties[index];
                          final Map<String, dynamic> lineup = party['lineup'];
                          
                          bool isIndependent = party['name'].toString().toLowerCase() == "independent";
                          String? platformBio = party['platform_bio']; 

                          return Card(
                            elevation: 6,
                            shadowColor: Colors.black26,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(25.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          party['name'].toUpperCase(),
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF000B6B), letterSpacing: 0.5),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isIndependent) 
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade200)
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Tooltip(
                                                message: isLocked ? "Locked: $lockReason" : "Edit Party",
                                                child: IconButton(
                                                  icon: Icon(Icons.edit_rounded, color: isLocked ? Colors.grey.shade400 : Colors.blue.shade600, size: 20),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: isLocked ? null : () => _showPartyDialog(party: party),
                                                ),
                                              ),
                                              Tooltip(
                                                message: isLocked ? "Locked: $lockReason" : "Delete Party",
                                                child: IconButton(
                                                  icon: Icon(Icons.delete_rounded, color: isLocked ? Colors.grey.shade400 : Colors.red.shade600, size: 20),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: isLocked ? null : () => _showDeleteConfirmation1(party['party_id'], party['name']),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                  
                                  // MODERN BIGGER BIO BOX
                                  if (platformBio != null && platformBio.isNotEmpty) ...[
                                    const SizedBox(height: 15),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade100)
                                      ),
                                      child: Text(
                                        platformBio,
                                        style: const TextStyle(
                                          fontSize: 14, 
                                          color: Colors.black87, 
                                          fontWeight: FontWeight.w500,
                                          height: 1.4 // Increased line height for readability
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 15),
                                  const Divider(thickness: 1.5),
                                  const SizedBox(height: 10),
                                  
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
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 3, 
                                                child: Text(
                                                  candidateName ?? "No Candidate",
                                                  style: TextStyle(
                                                    fontSize: 15, 
                                                    color: candidateName == null ? Colors.grey : Colors.black87,
                                                    fontStyle: candidateName == null ? FontStyle.italic : FontStyle.normal,
                                                    fontWeight: candidateName != null ? FontWeight.w800 : FontWeight.normal,
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