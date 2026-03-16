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

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();

  // Dropdown States
  List<dynamic> _polls = [];
  List<String> _parties = ['Independent'];

  int? _selectedPollId;
  String? _selectedPosition;
  String _selectedParty = 'Independent';
  String? _selectedCourse;
  String? _selectedYear;

  // Image State
  XFile? _selectedImage;
  Uint8List? _imageBytes; // Used for universal web/mobile image preview

  final List<String> _positions = [
    'President',
    'Vice President',
    'Secretary',
    'Treasurer',
    'Auditor',
    'PIO',
  ];
  final List<String> _courses = [
    'BS Information Technology',
    'BS Computer Engineering',
    'BS Elementary Education',
    'BS Secondary Education',
    'BA Communication',
    'BS Tourism Management',
  ];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPolls();
    _fetchParties();
  }

  Future<void> _fetchPolls() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/polls'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _polls = jsonDecode(response.body);
          if (_polls.isNotEmpty) _selectedPollId = _polls[0]['poll_id'];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchParties() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/parties/lineups'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> fetchedParties = jsonDecode(response.body);
        setState(() {
          _parties = ['Independent']; // Always include Independent
          for (var p in fetchedParties) {
            if (p['party_name'] != 'Independent') {
              _parties.add(p['party_name']);
            }
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourse == null ||
        _selectedYear == null ||
        _selectedPosition == null ||
        _selectedPollId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all dropdown fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}/api/candidates');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['poll_id'] = _selectedPollId.toString();
      request.fields['name'] = _nameController.text.trim();
      request.fields['position'] = _selectedPosition!;
      request.fields['party_name'] = _selectedParty;
      // CONCATENATE COURSE AND YEAR HERE
      request.fields['course_year'] = '$_selectedCourse - $_selectedYear';

      if (_platformController.text.trim().isNotEmpty) {
        request.fields['description_platform'] = _platformController.text
            .trim();
      }

      // Add Image File if selected
      if (_selectedImage != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _imageBytes!,
            filename: _selectedImage!.name,
          ),
        );
      }

      // Send Request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidate Registered Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _nameController.clear();
          _platformController.clear();
          _selectedImage = null;
          _imageBytes = null;
          _selectedCourse = null;
          _selectedYear = null;
          _selectedPosition = null;
          _selectedParty = 'Independent';
        });
      } else {
        // This catches the Duplicate Party/Position 400 Error!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['detail'] ?? 'Registration failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Register New Candidate",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter candidate details, assign them to a party, and upload a photo.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PHOTO UPLOAD ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : null,
                        child: _imageBytes == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Tap to upload photo",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- POLL & NAME ---
                  DropdownButtonFormField<int>(
                    isExpanded: true, // FIX: Prevents overflow
                    decoration: const InputDecoration(
                      labelText: "Select Election Poll",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedPollId,
                    items: _polls
                        .map<DropdownMenuItem<int>>(
                          (poll) => DropdownMenuItem(
                            value: poll['poll_id'],
                            child: Text(
                              poll['title'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPollId = val),
                    validator: (value) =>
                        value == null ? 'Please select a poll' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- POSITION & PARTY ---
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // FIX: Prevents overflow
                          decoration: const InputDecoration(
                            labelText: "Position",
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedPosition,
                          items: _positions
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPosition = val),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // FIX: Prevents overflow
                          decoration: const InputDecoration(
                            labelText: "Select Party",
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedParty,
                          items: _parties
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedParty = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- COURSE & YEAR (Side-by-Side) ---
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // FIX: Prevents overflow
                          decoration: const InputDecoration(
                            labelText: "Course",
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedCourse,
                          items: _courses
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCourse = val),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, // FIX: Prevents overflow
                          decoration: const InputDecoration(
                            labelText: "Year Level",
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedYear,
                          items: _years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedYear = val),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- DESCRIPTION/PLATFORM ---
                  TextFormField(
                    controller: _platformController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Platform / Description",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- SUBMIT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000B6B),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Register Candidate",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
