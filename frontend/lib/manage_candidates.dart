import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ManageCandidates extends StatefulWidget {
  const ManageCandidates({super.key});

  @override
  State<ManageCandidates> createState() => _ManageCandidatesState();
}

class _ManageCandidatesState extends State<ManageCandidates> {
  List<dynamic> _polls = [];
  int? _selectedPollId;
  
  List<dynamic> _candidates = [];
  bool _isLoading = true;

  final List<String> _positions = [
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor',
    'PIO'
  ];
  String _selectedPosition = 'President';

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (response.statusCode == 200) {
        final polls = jsonDecode(response.body);
        setState(() {
          _polls = polls;
          if (_polls.isNotEmpty) {
            _selectedPollId = _polls[0]['poll_id'];
            _fetchCandidates(); 
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCandidates() async {
    if (_selectedPollId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$_selectedPollId'));
      if (response.statusCode == 200) {
        setState(() {
          _candidates = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCandidate(int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/candidates/$id'));
      if (response.statusCode == 200) {
        _fetchCandidates();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate removed')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error deleting candidate')));
    }
  }

  // --- CHANGED TO EDIT DIALOG ONLY ---
  void _showEditCandidateDialog(Map<String, dynamic> candidate) {
    // Pre-fill controllers with the candidate's existing data
    final nameCtrl = TextEditingController(text: candidate['name']);
    final partyCtrl = TextEditingController(text: candidate['party_name']);
    final courseCtrl = TextEditingController(text: candidate['course_year']);
    final platformCtrl = TextEditingController(text: candidate['description_platform'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Candidate Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party Name')),
                TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course & Year')),
                TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: 'Platform / Description'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || courseCtrl.text.isEmpty) return;
                
                final response = await http.put(
                  Uri.parse('${ApiConfig.baseUrl}/api/candidates/${candidate['candidate_id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'name': nameCtrl.text,
                    'party_name': partyCtrl.text.isEmpty ? 'Independent' : partyCtrl.text,
                    'course_year': courseCtrl.text,
                    'description_platform': platformCtrl.text,
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  _fetchCandidates(); // Refresh the list with new data
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate updated!')));
                } else {
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
                }
              },
              child: const Text('Update Candidate'),
            )
          ],
        );
      }
    );
  }

@override
  Widget build(BuildContext context) {
    final filteredCandidates = _candidates.where((c) => c['position'] == _selectedPosition).toList();
    // Check if the screen is narrow (like a mobile phone)
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX 1: Changed Row to Wrap so the dropdown moves to the next line on mobile
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Candidates", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              if (_polls.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedPollId,
                      items: _polls.map<DropdownMenuItem<int>>((poll) {
                        return DropdownMenuItem<int>(
                          value: poll['poll_id'],
                          child: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedPollId = newValue;
                          _fetchCandidates();
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Edit or remove existing candidates from the selected poll.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          
          Expanded(
            // FIX 2: Switch between Row (Desktop) and Column (Mobile) dynamically
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isMobile ? double.infinity : 250,
                  height: isMobile ? 80 : null, // Give it a fixed height on mobile so it can scroll horizontally
                  margin: EdgeInsets.only(right: isMobile ? 0 : 20, bottom: isMobile ? 20 : 0),
                  child: ListView.builder(
                    scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                    itemCount: _positions.length,
                    itemBuilder: (context, index) {
                      final position = _positions[index];
                      final isSelected = _selectedPosition == position;
                      return InkWell(
                        onTap: () => setState(() => _selectedPosition = position),
                        child: Container(
                          margin: EdgeInsets.only(bottom: isMobile ? 0 : 10, right: isMobile ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFD6D6D6) : Colors.grey[200],
                            border: isSelected ? Border.all(color: Colors.grey, width: 2) : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text('Candidates for $position', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_selectedPosition Candidates', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : _polls.isEmpty 
                                ? const Center(child: Text("Please create a Poll first.", style: TextStyle(fontSize: 16)))
                                : filteredCandidates.isEmpty
                                  ? const Center(child: Text("No candidates added yet.", textAlign: TextAlign.center))
                                  : ListView.builder(
                                      itemCount: filteredCandidates.length,
                                      itemBuilder: (context, index) {
                                        final candidate = filteredCandidates[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          child: ListTile(
                                            title: Text(candidate['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            subtitle: Text('${candidate['party_name']} • ${candidate['course_year']}'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditCandidateDialog(candidate)),
                                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCandidate(candidate['candidate_id'])),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}