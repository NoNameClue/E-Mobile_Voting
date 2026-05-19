import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
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
  List<dynamic> _parties = []; 
  
  List<Map<String, dynamic>> _questionBank = [];
  
  bool _isLoading = true;

  final List<String> _positions = [
    'President', 'Vice President', 'Secretary', 'Treasurer', 'Auditor', 'PIO',
  ];

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

  String _selectedPosition = 'President';

  @override
  void initState() {
    super.initState();
    _fetchPolls();
    _fetchQuestions(); 
  }

  // 🛠️ SPLIT LOCK LOGIC: Differentiates between "Published" and "Ended"
  bool _isPollEnded() {
    if (_selectedPollId == null || _polls.isEmpty) return false;
    final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
    if (poll == null) return false;
    return poll['status'] == 'Ended' || poll['status'] == 'Expired';
  }

  bool _isPollPublished() {
    if (_selectedPollId == null || _polls.isEmpty) return false;
    final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
    if (poll == null) return false;
    return poll['is_published'] == true || poll['is_published'] == 1;
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/questions'));
      if (response.statusCode == 200) {
        setState(() {
          _questionBank = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
    }
  }

  Future<void> _fetchPartiesForPoll(int pollId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/parties/$pollId'));
      if (response.statusCode == 200) {
        setState(() {
          _parties = jsonDecode(response.body);
        });
      }
    } catch (e) {
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
            _fetchPartiesForPoll(_selectedPollId!);
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate removed', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error deleting candidate')));
    }
  }

  void _showManageQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final TextEditingController newQuestionCtrl = TextEditingController();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Manage Question Bank", style: TextStyle(color: Color(0xFF000B6B), fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newQuestionCtrl,
                            decoration: InputDecoration(labelText: "Add a new reusable question", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () async {
                            if (newQuestionCtrl.text.trim().isEmpty) return;
                            try {
                              final res = await http.post(
                                Uri.parse('${ApiConfig.baseUrl}/api/questions'),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({"question_text": newQuestionCtrl.text.trim()})
                              );
                              if (res.statusCode == 200) {
                                newQuestionCtrl.clear();
                                await _fetchQuestions();
                                setModalState(() {}); 
                              } else {
                                final err = jsonDecode(res.body);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? "Error"), backgroundColor: Colors.red));
                              }
                            } catch (e) {}
                          },
                          child: const Text("Save"),
                        )
                      ],
                    ),
                    const Divider(height: 30),
                    Expanded(
                      child: _questionBank.isEmpty 
                        ? const Center(child: Text("Your question bank is empty.", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _questionBank.length,
                            itemBuilder: (context, index) {
                              final q = _questionBank[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(q['question_text']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showEditSingleQuestionDialog(q['question_id'], q['question_text'], () async {
                                            await _fetchQuestions();
                                            setModalState(() {});
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/questions/${q['question_id']}'));
                                          await _fetchQuestions();
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                        ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
              ],
            );
          },
        );
      }
    ).then((_) => setState(() {})); 
  }

  void _showEditSingleQuestionDialog(int qId, String currentText, VoidCallback onSuccess) {
    final TextEditingController editCtrl = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Question"),
          content: TextField(
            controller: editCtrl,
            maxLines: 2,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                if (editCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Question cannot be blank!"), backgroundColor: Colors.red));
                  return;
                }
                try {
                  final res = await http.put(
                    Uri.parse('${ApiConfig.baseUrl}/api/questions/$qId'),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({"question_text": editCtrl.text.trim()})
                  );
                  if (res.statusCode == 200) {
                    Navigator.pop(context);
                    onSuccess();
                  } else {
                    final err = jsonDecode(res.body);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? "Error"), backgroundColor: Colors.red));
                  }
                } catch (e) {}
              },
              child: const Text("Save"),
            )
          ],
        );
      }
    );
  }

  void _showCandidateDialog({Map<String, dynamic>? candidate}) {
    final bool isEdit = candidate != null;
    final bool isPublished = _isPollPublished(); // 🛠️ Check if published to lock down inputs

    final firstNameCtrl = TextEditingController(text: candidate?['first_name'] ?? '');
    final middleNameCtrl = TextEditingController(text: candidate?['middle_name'] ?? '');
    final lastNameCtrl = TextEditingController(text: candidate?['last_name'] ?? '');
    final platformCtrl = TextEditingController(text: candidate?['description_platform'] ?? '');

    String? selectedCourse;
    String? selectedYear;
    if (isEdit && candidate['course_year'] != null) {
      List<String> parts = candidate['course_year'].split(' - ');
      if (parts.isNotEmpty && _courses.contains(parts[0])) selectedCourse = parts[0];
      if (parts.length > 1 && _years.contains(parts[1])) selectedYear = parts[1];
    }

    String? selectedPosition = isEdit ? candidate['position'] : _selectedPosition;
    String? selectedParty = isEdit ? candidate['party_name'] : 'Independent';
    
    // Track withdrawal status
    bool isWithdrawn = isEdit && (candidate['is_withdrawn'] == 1 || candidate['is_withdrawn'] == true);

    List<String> uniqueParties = ['Independent'];
    for (var p in _parties) {
      if (p['name'] != null && p['name'] != 'Independent') {
        uniqueParties.add(p['name']);
      }
    }
    if (!uniqueParties.contains(selectedParty)) selectedParty = 'Independent';

    String? q1, q2, q3;
    final a1Ctrl = TextEditingController();
    final a2Ctrl = TextEditingController();
    final a3Ctrl = TextEditingController();
    
    final customQ1Ctrl = TextEditingController();
    final customQ2Ctrl = TextEditingController();
    final customQ3Ctrl = TextEditingController();

    if (isEdit && candidate['qas'] != null) {
      List<dynamic> existingQAs = candidate['qas'];
      
      bool existsInBank(String qText) => _questionBank.any((dbQ) => dbQ['question_text'] == qText);

      if (existingQAs.isNotEmpty) { 
        String eq = existingQAs[0]['question'];
        if (existsInBank(eq)) { q1 = eq; } else { q1 = "Write a one-time custom question..."; customQ1Ctrl.text = eq; }
        a1Ctrl.text = existingQAs[0]['answer'] ?? ''; 
      }
      
      if (existingQAs.length > 1) { 
        String eq = existingQAs[1]['question'];
        if (existsInBank(eq)) { q2 = eq; } else { q2 = "Write a one-time custom question..."; customQ2Ctrl.text = eq; }
        a2Ctrl.text = existingQAs[1]['answer'] ?? ''; 
      }
      
      if (existingQAs.length > 2) { 
        String eq = existingQAs[2]['question'];
        if (existsInBank(eq)) { q3 = eq; } else { q3 = "Write a one-time custom question..."; customQ3Ctrl.text = eq; }
        a3Ctrl.text = existingQAs[2]['answer'] ?? ''; 
      }
    }

    XFile? newImage;
    Uint8List? newImageBytes;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 700, 
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFF000B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit 
                              ? (isPublished ? 'Withdraw Candidate' : 'Edit Candidate Details') 
                              : 'Register New Candidate', 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPublished) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20.0),
                                decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.orange),
                                    SizedBox(width: 10),
                                    Expanded(child: Text("This poll is published. Personal details and Q&A are locked. You may only modify their withdrawal status.", style: TextStyle(color: Colors.orange))),
                                  ],
                                ),
                              ),
                            ],

                            // 🛠️ ONLY SHOW WITHDRAWAL SLIDER IF POLL IS PUBLISHED AND WE ARE EDITING
                            if (isEdit && isPublished) ...[
                              SwitchListTile(
                                title: const Text("Withdraw Candidate", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
                                subtitle: const Text("Flags candidate as withdrawn. Removes them from the ballot but preserves existing vote data."),
                                activeColor: Colors.red,
                                contentPadding: EdgeInsets.zero,
                                value: isWithdrawn,
                                onChanged: (bool value) {
                                  setStateDialog(() {
                                    isWithdrawn = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 20),
                            ],

                            const Text("1. Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Divider(),
                            const SizedBox(height: 10),

                            Center(
                              child: GestureDetector(
                                onTap: isPublished ? null : () async {
                                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    final bytes = await pickedFile.readAsBytes();
                                    setStateDialog(() { newImage = pickedFile; newImageBytes = bytes; });
                                  }
                                },
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: newImageBytes != null
                                          ? MemoryImage(newImageBytes!) as ImageProvider
                                          : (isEdit && candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null),
                                      child: (newImageBytes == null && (!isEdit || candidate['photo_url'] == null))
                                          ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 30)
                                          : null,
                                    ),
                                    if (!isPublished)
                                      Positioned(
                                        bottom: 0, right: 0,
                                        child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 15)),
                                      )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(flex: 3, child: TextField(controller: firstNameCtrl, enabled: !isPublished, decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                                const SizedBox(width: 10),
                                Expanded(flex: 2, child: TextField(controller: middleNameCtrl, enabled: !isPublished, decoration: InputDecoration(labelText: 'M.I.', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                                const SizedBox(width: 10),
                                Expanded(flex: 3, child: TextField(controller: lastNameCtrl, enabled: !isPublished, decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                              ],
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  flex: 2, 
                                  child: DropdownMenu<String>(
                                    enabled: !isPublished,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedCourse,
                                    requestFocusOnTap: false, 
                                    label: const Text('Course'),
                                    onSelected: (val) => setStateDialog(() => selectedCourse = val),
                                    dropdownMenuEntries: _courses.map((c) => DropdownMenuEntry(value: c, label: c)).toList(),
                                    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  )
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1, 
                                  child: DropdownMenu<String>(
                                    enabled: !isPublished,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedYear,
                                    requestFocusOnTap: false, 
                                    label: const Text('Year'),
                                    onSelected: (val) => setStateDialog(() => selectedYear = val),
                                    dropdownMenuEntries: _years.map((y) => DropdownMenuEntry(value: y, label: y)).toList(),
                                    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  )
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            const Text("2. Election & Platform", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Divider(),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: DropdownMenu<String>(
                                    enabled: !isPublished,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedPosition,
                                    requestFocusOnTap: false, 
                                    label: const Text('Running For'),
                                    onSelected: (val) => setStateDialog(() => selectedPosition = val),
                                    dropdownMenuEntries: _positions.map((p) => DropdownMenuEntry(value: p, label: p)).toList(),
                                    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  )
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownMenu<String>(
                                    enabled: !isPublished,
                                    expandedInsets: EdgeInsets.zero,
                                    initialSelection: selectedParty,
                                    requestFocusOnTap: false, 
                                    label: const Text('Party Affiliation'),
                                    onSelected: (val) => setStateDialog(() => selectedParty = val),
                                    dropdownMenuEntries: uniqueParties.map((p) => DropdownMenuEntry(value: p, label: p)).toList(),
                                    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  )
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            TextField(controller: platformCtrl, enabled: !isPublished, decoration: InputDecoration(labelText: 'General Platform / Bio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), alignLabelWithHint: true), maxLines: 3),

                            const SizedBox(height: 30),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("3. Candidate Q&A (Optional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text("Select questions from the bank.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: isPublished ? null : () {
                                    _showManageQuestionsDialog();
                                    Future.delayed(const Duration(milliseconds: 500), () {
                                      if (mounted) setStateDialog(() {});
                                    });
                                  }, 
                                  icon: const Icon(Icons.settings), 
                                  label: const Text("Manage Question Bank")
                                )
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 10),

                            _buildQASection(1, q1, a1Ctrl, customQ1Ctrl, (val) => setStateDialog(() => q1 = val), !isPublished),
                            const SizedBox(height: 15),
                            _buildQASection(2, q2, a2Ctrl, customQ2Ctrl, (val) => setStateDialog(() => q2 = val), !isPublished),
                            const SizedBox(height: 15),
                            _buildQASection(3, q3, a3Ctrl, customQ3Ctrl, (val) => setStateDialog(() => q3 = val), !isPublished),

                          ],
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: () async {
                              if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First Name and Last Name are required.'), backgroundColor: Colors.red));
                                return;
                              }
                              if (selectedCourse == null || selectedYear == null || selectedPosition == null || selectedParty == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all dropdowns.'), backgroundColor: Colors.red));
                                return;
                              }

                              List<Map<String, String>> qaData = [];
                              
                              String finalQ1 = q1 == "Write a one-time custom question..." ? customQ1Ctrl.text.trim() : (q1 ?? "");
                              if (finalQ1.isNotEmpty && a1Ctrl.text.isNotEmpty) qaData.add({"question": finalQ1, "answer": a1Ctrl.text.trim()});
                              
                              String finalQ2 = q2 == "Write a one-time custom question..." ? customQ2Ctrl.text.trim() : (q2 ?? "");
                              if (finalQ2.isNotEmpty && a2Ctrl.text.isNotEmpty) qaData.add({"question": finalQ2, "answer": a2Ctrl.text.trim()});
                              
                              String finalQ3 = q3 == "Write a one-time custom question..." ? customQ3Ctrl.text.trim() : (q3 ?? "");
                              if (finalQ3.isNotEmpty && a3Ctrl.text.isNotEmpty) qaData.add({"question": finalQ3, "answer": a3Ctrl.text.trim()});

                              Uri url = isEdit 
                                  ? Uri.parse('${ApiConfig.baseUrl}/api/candidates/${candidate['candidate_id']}')
                                  : Uri.parse('${ApiConfig.baseUrl}/api/candidates');
                                  
                              var req = http.MultipartRequest(isEdit ? 'PUT' : 'POST', url);
                              
                              req.fields['poll_id'] = _selectedPollId.toString();
                              req.fields['first_name'] = firstNameCtrl.text.trim();
                              req.fields['middle_name'] = middleNameCtrl.text.trim();
                              req.fields['last_name'] = lastNameCtrl.text.trim();
                              req.fields['position'] = selectedPosition!;
                              req.fields['party_name'] = selectedParty!;
                              req.fields['course_year'] = "$selectedCourse - $selectedYear";
                              req.fields['description_platform'] = platformCtrl.text;
                              req.fields['qa_data'] = jsonEncode(qaData); 
                              req.fields['is_withdrawn'] = isWithdrawn.toString(); // Include withdrawal status

                              if (newImage != null && newImageBytes != null) {
                                req.files.add(http.MultipartFile.fromBytes('photo', newImageBytes!, filename: newImage!.name));
                              }

                              var streamedRes = await req.send();
                              var res = await http.Response.fromStream(streamedRes);
                              
                              if (!mounted) return;
                              if (res.statusCode == 200) {
                                Navigator.pop(context);
                                _fetchCandidates();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Candidate updated!' : 'Candidate Registered!'), backgroundColor: Colors.green));
                              } else {
                                final error = jsonDecode(res.body);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail'] ?? 'Operation failed'), backgroundColor: Colors.red));
                              }
                            },
                            child: Text(isEdit ? (isPublished ? 'Save Withdrawal Status' : 'Update Candidate') : 'Register Candidate', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQASection(int index, String? selectedQ, TextEditingController answerCtrl, TextEditingController customCtrl, Function(String?) onChanged, bool isEnabled) {
    bool isCustom = selectedQ == "Write a one-time custom question...";

    List<String> dynamicItems = _questionBank.map((q) => q['question_text'] as String).toList();
    
    if (selectedQ != null && !isCustom && !dynamicItems.contains(selectedQ)) {
      dynamicItems.insert(0, selectedQ);
    }
    
    dynamicItems.add("Write a one-time custom question...");

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownMenu<String>(
            enabled: isEnabled,
            expandedInsets: EdgeInsets.zero,
            initialSelection: selectedQ,
            requestFocusOnTap: false, 
            label: Text('Question $index'),
            onSelected: onChanged,
            dropdownMenuEntries: dynamicItems.map((q) {
              return DropdownMenuEntry<String>(
                value: q,
                label: q,
                style: MenuItemButton.styleFrom(
                  foregroundColor: q == "Write a one-time custom question..." ? const Color(0xFF000B6B) : Colors.black87,
                  textStyle: TextStyle(
                    fontSize: 13, 
                    fontWeight: q == "Write a one-time custom question..." ? FontWeight.bold : FontWeight.normal,
                  )
                )
              );
            }).toList(),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
            ),
          ),
          
          if (isCustom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: customCtrl,
              enabled: isEnabled,
              decoration: InputDecoration(labelText: 'Type your custom question here', filled: true, fillColor: isEnabled ? Colors.white : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ],
          
          const SizedBox(height: 10),
          TextField(
            controller: answerCtrl,
            enabled: isEnabled,
            decoration: InputDecoration(labelText: 'Candidate Answer', filled: true, fillColor: isEnabled ? Colors.white : Colors.grey.shade200, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            maxLines: 2,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCandidates = _candidates.where((c) => c['position'] == _selectedPosition).toList();
    bool isMobile = MediaQuery.of(context).size.width < 700;
    
    // 🛠️ APPLY STATUS CHECKS
    bool isEnded = _isPollEnded(); 
    bool isPublished = _isPollPublished();
    
    bool canRegister = !isPublished && !isEnded;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Candidates", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              Wrap(
                spacing: 10,
                children: [
                  if (_polls.isNotEmpty)
                    DropdownMenu<int>(
                      initialSelection: _selectedPollId,
                      requestFocusOnTap: false, 
                      onSelected: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPollId = newValue;
                            _fetchPartiesForPoll(newValue);
                            _fetchCandidates();
                          });
                        }
                      },
                      dropdownMenuEntries: _polls.map<DropdownMenuEntry<int>>((poll) {
                        return DropdownMenuEntry<int>(
                          value: poll['poll_id'], 
                          label: poll['title'],
                        );
                      }).toList(),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16), 
                          borderSide: BorderSide(color: Colors.grey.shade300)
                        ),
                      ),
                    ),
                  
                  Tooltip(
                    message: isEnded ? "Poll has ended." : isPublished ? "Poll is published. Cannot add new candidates." : "Register a new candidate",
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRegister ? Colors.amber : Colors.grey, 
                        foregroundColor: const Color(0xFF000B6B), 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text("Register New Candidate", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: canRegister ? () => _showCandidateDialog() : null,
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Text(
            isEnded 
              ? "This election has ended. All candidate records are permanently locked." 
              : isPublished 
                ? "This election is active. You may only modify withdrawal status."
                : "Register, edit, or remove candidates for the selected poll.", 
            style: TextStyle(
              color: isEnded ? Colors.redAccent : isPublished ? Colors.orangeAccent : Colors.grey, 
              fontSize: 16, 
              fontWeight: (isEnded || isPublished) ? FontWeight.bold : FontWeight.normal
            )
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position Sidebar
                Container(
                  width: isMobile ? double.infinity : 250,
                  height: isMobile ? 80 : null, 
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
                          decoration: BoxDecoration(color: isSelected ? const Color(0xFFD6D6D6) : Colors.grey[200], border: isSelected ? Border.all(color: Colors.grey, width: 2) : null, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Candidates for $position', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                        ),
                      );
                    },
                  ),
                ),

                // Candidates List Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                              ? const Center(child: Text("No candidates registered for this position yet.", textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: filteredCandidates.length,
                                  itemBuilder: (context, index) {
                                    final candidate = filteredCandidates[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          backgroundImage: candidate['photo_url'] != null ? NetworkImage('${ApiConfig.baseUrl}/${candidate['photo_url']}') : null,
                                          child: candidate['photo_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                        ),
                                        title: Text(candidate['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${candidate['party_name']} • ${candidate['course_year']}'),
                                            if (candidate['is_withdrawn'] == 1 || candidate['is_withdrawn'] == true)
                                              Container(
                                                margin: const EdgeInsets.only(top: 5),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                                child: Text("WITHDRAWN", style: TextStyle(color: Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                              )
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message: isEnded ? "Poll has ended. Cannot modify." : isPublished ? "Withdraw Candidate" : "Edit Candidate", 
                                              child: IconButton(
                                                icon: Icon(isPublished ? Icons.block : Icons.edit, color: isEnded ? Colors.grey : isPublished ? Colors.orange : Colors.blue), 
                                                onPressed: isEnded ? null : () => _showCandidateDialog(candidate: candidate)
                                              )
                                            ),
                                            Tooltip(
                                              message: isEnded ? "Poll has ended." : isPublished ? "Use Edit to withdraw candidate." : "Delete Candidate", 
                                              child: IconButton(
                                                icon: Icon(Icons.delete, color: (isPublished || isEnded) ? Colors.grey : Colors.red), 
                                                onPressed: (isPublished || isEnded) ? null : () => _deleteCandidate(candidate['candidate_id'])
                                              )
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}