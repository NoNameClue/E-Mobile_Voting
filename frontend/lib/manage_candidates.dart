import 'package:flutter/foundation.dart'; // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  List<dynamic> _parties = []; // Added for fetching parties
  bool _isLoading = true;

  final List<String> _positions = [
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor',
    'PIO'
  ];
  
  // Standard course and year lists for the dropdowns
  final List<String> _courses = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Elementary Education',
    'Bachelor of Secondary Education',
    'Bachelor of Arts in Communication',
    'Bachelor of Science in Hospitality Management',
  ];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  String _selectedPosition = 'President';

  @override
  void initState() {
    super.initState();
    _fetchPolls();
    _fetchParties(); // Fetch parties on load
  }

  Future<void> _fetchParties() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/lineups'));
      if (response.statusCode == 200) {
        setState(() {
          _parties = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Silently fail or handle error
    }
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

  void _showEditCandidateDialog(Map<String, dynamic> candidate) {
    final nameCtrl = TextEditingController(text: candidate['name']);
    final platformCtrl = TextEditingController(text: candidate['description_platform'] ?? '');
    
    // Split Course and Year
    List<String> courseYearParts = candidate['course_year'].split(' - ');
    String? selectedCourse = courseYearParts.isNotEmpty && _courses.contains(courseYearParts[0]) ? courseYearParts[0] : null;
    String? selectedYear = courseYearParts.length > 1 && _years.contains(courseYearParts[1]) ? courseYearParts[1] : null;
    String? selectedParty = candidate['party_name'];
    
    // Ensure the selected party actually exists in our fetched list, otherwise default to Independent
    bool partyExists = _parties.any((p) => p['party_name'] == selectedParty);
    if (!partyExists && selectedParty != 'Independent') selectedParty = 'Independent';
    
    // REPLACE File with XFile & Uint8List for Web compatibility
    XFile? newImage;
    Uint8List? newImageBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Candidate Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        setStateDialog(() {
                          newImage = pickedFile;
                          newImageBytes = bytes;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: newImageBytes != null 
                          ? MemoryImage(newImageBytes!) as ImageProvider 
                          : (candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null),
                      child: (newImageBytes == null && candidate['photo_url'] == null) ? const Icon(Icons.camera_alt, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 10),
                  
                  // Dropdown for Party
                  DropdownButtonFormField<String>(
                    value: selectedParty,
                    decoration: const InputDecoration(labelText: 'Party'),
                    items: [
                      const DropdownMenuItem(value: 'Independent', child: Text('Independent')),
                      ..._parties.map<DropdownMenuItem<String>>((party) {
                        return DropdownMenuItem<String>(
                          value: party['party_name'],
                          child: Text(party['party_name']),
                        );
                      }),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedParty = val),
                  ),
                  const SizedBox(height: 10),

                  // Dropdowns for Course and Year (Side by Side)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: selectedCourse,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Course'),
                          items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedCourse = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'Year'),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedYear = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: 'Platform'), maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
                onPressed: () async {
                  var req = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/api/candidates/${candidate['candidate_id']}'));
                  req.fields['name'] = nameCtrl.text;
                  req.fields['party_name'] = selectedParty ?? 'Independent';
                  req.fields['course_year'] = "$selectedCourse - $selectedYear";
                  req.fields['description_platform'] = platformCtrl.text;
                  
                  if (newImage != null && newImageBytes != null) {
                    req.files.add(http.MultipartFile.fromBytes('photo', newImageBytes!, filename: newImage!.name));
                  }
                  
                  await req.send();
                  if (!mounted) return;
                  Navigator.pop(context);
                  _fetchCandidates();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate updated!')));
                },
                child: const Text('Update'),
              )
            ],
          );
        });
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
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.grey[300],
                                              backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                                              child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                            ),
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