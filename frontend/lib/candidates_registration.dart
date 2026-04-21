import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';

class CandidatesRegistration extends StatefulWidget {
  const CandidatesRegistration({super.key});

  @override
  State<CandidatesRegistration> createState() => _CandidatesRegistrationState();
}

class _CandidatesRegistrationState extends State<CandidatesRegistration> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  final TextEditingController _platformController = TextEditingController();

  List<dynamic> _polls = [];
  List<String> _parties = ['Independent'];

  int? _selectedPollId;
  String? _selectedPosition;
  String _selectedParty = 'Independent';
  String? _selectedCourse;
  String? _selectedYear;

  XFile? _selectedImage;
  Uint8List? _imageBytes; 

  final List<String> _positions = ['President', 'Vice President', 'Secretary', 'Treasurer', 'Auditor', 'PIO'];
  
  final List<String> _courses = [
    'Bachelor of Science in Tourism Management',
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Entrepreneurship',
    'Bachelor of Arts in Communication',
    'Bachelor of Arts in Political Science',
    'Bachelor of Arts in English Language',
    'Bachelor of Science in Social Work',
    'Bachelor of Science in Biology',
    'Bachelor of Science in Information Technology',
    'Bachelor of Library and Information Science',
    'Bachelor of Music in Music Education',
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Special Needs Education',
    'Bachelor of Physical Education',
    'Bachelor of Technology and Livelihood Education',
    'Bachelor of Secondary Education'
  ];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPollsAndParties();
  }

  // 🛠️ UPDATED: Now it only fetches Polls on startup. Parties are loaded later.
  Future<void> _fetchPollsAndParties() async {
    try {
      final pollResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));

      if (pollResponse.statusCode == 200) {
        final List<dynamic> pollData = jsonDecode(pollResponse.body);

        setState(() {
          _polls = pollData;
          _parties = ['Independent']; // Default before poll is selected
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load data from server')));
      }
    }
  }

  // 🛠️ ADDED: New method to fetch parties for a specific poll
  Future<void> _fetchPartiesForPoll(int pollId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/$pollId'));
      if (response.statusCode == 200) {
        final List<dynamic> partyData = jsonDecode(response.body);
        setState(() {
          _parties = {'Independent', ...partyData.map((p) => p['name'].toString())}.toList();
          _selectedParty = 'Independent'; // Reset to default
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes; 
      });
    }
  }

  bool _isCurrentPollEnded() {
    if (_selectedPollId == null || _polls.isEmpty) return false;
    final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
    return poll != null && poll['status'] == 'Ended';
  }

  Future<void> _submitForm() async {
    if (_selectedPollId == null || _selectedPosition == null || _selectedCourse == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all required dropdowns')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_isCurrentPollEnded()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot register candidates for an ended poll.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/candidates'));
      
      request.fields['poll_id'] = _selectedPollId.toString();
      request.fields['first_name'] = _firstNameController.text;
      request.fields['middle_name'] = _middleNameController.text;
      request.fields['last_name'] = _lastNameController.text;
      request.fields['position'] = _selectedPosition!;
      request.fields['party_name'] = _selectedParty;
      request.fields['course_year'] = '$_selectedCourse - $_selectedYear';
      request.fields['description_platform'] = _platformController.text;

      if (_imageBytes != null && _selectedImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo', 
            _imageBytes!, 
            filename: _selectedImage!.name, 
          )
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate Registered Successfully!')));
          _formKey.currentState!.reset();
          _firstNameController.clear();
          _middleNameController.clear();
          _lastNameController.clear();
          _platformController.clear();
          setState(() {
            _selectedImage = null;
            _imageBytes = null;
            _selectedPosition = null;
            _selectedCourse = null;
            _selectedYear = null;
            _selectedParty = 'Independent';
          });
        }
      } else {
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail'] ?? 'Registration Failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _polls.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    bool isPollEnded = _isCurrentPollEnded();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Register Candidate", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            const Text("Add a new candidate to an election poll", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 30),

            if (isPollEnded)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text("This poll has already ended. You cannot register new candidates.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Election Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Poll', border: OutlineInputBorder()),
                    value: _selectedPollId,
                    items: _polls.map((poll) {
                      String statusText = poll['status'] == 'Ended' ? ' (Ended)' : '';
                      return DropdownMenuItem<int>(
                        value: poll['poll_id'],
                        child: Text('${poll['title']}$statusText'),
                      );
                    }).toList(),
                    // 🛠️ UPDATED: Fetch parties dynamically when a poll is selected
                    onChanged: (val) {
                      setState(() => _selectedPollId = val);
                      if (val != null) _fetchPartiesForPoll(val); 
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Running for Position', border: OutlineInputBorder()),
                          value: _selectedPosition,
                          items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: isPollEnded ? null : (val) => setState(() => _selectedPosition = val), 
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Political Party', border: OutlineInputBorder()),
                          value: _selectedParty,
                          items: _parties.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: isPollEnded ? null : (val) => setState(() => _selectedParty = val!), 
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Text("Candidate Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          enabled: !isPollEnded,
                          decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _middleNameController,
                          enabled: !isPollEnded,
                          decoration: const InputDecoration(labelText: "Middle Name (Optional)", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          enabled: !isPollEnded,
                          decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                          value: _selectedCourse,
                          isExpanded: true, 
                          items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: isPollEnded ? null : (val) => setState(() => _selectedCourse = val), 
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Year Level', border: OutlineInputBorder()),
                          value: _selectedYear,
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: isPollEnded ? null : (val) => setState(() => _selectedYear = val), 
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400)
                        ),
                        child: _imageBytes != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: isPollEnded ? null : _pickImage, 
                        icon: const Icon(Icons.image),
                        label: const Text("Upload Candidate Photo"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _platformController,
                    enabled: !isPollEnded, 
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Platform / Description", 
                      border: OutlineInputBorder(), 
                      alignLabelWithHint: true
                    ),
                  ),
                  const SizedBox(height: 30),

                  Tooltip(
                    message: isPollEnded ? "Cannot register candidates for an ended poll." : "Submit Registration",
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPollEnded ? Colors.grey.shade400 : const Color(0xFF000B6B), 
                          foregroundColor: Colors.white
                        ),
                        onPressed: isPollEnded ? null : (_isLoading ? null : _submitForm), 
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Register Candidate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}