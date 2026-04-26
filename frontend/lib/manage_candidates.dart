import 'package:flutter/material.dart';
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
  
  // 🛠️ Dynamic Question Bank from Database
  List<Map<String, dynamic>> _questionBank = [];
  
  bool _isLoading = true;

  final List<String> _positions = [
    'President', 'Vice President', 'Secretary', 'Treasurer', 'Auditor', 'PIO',
  ];

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
    _fetchQuestions(); // 🛠️ Fetch dynamic questions on load
  }

  // 🛠️ REPLACED: Now checks for both Ended AND Published states
  bool _isPollLocked() {
    if (_selectedPollId == null || _polls.isEmpty) return false;
    final poll = _polls.firstWhere((p) => p['poll_id'] == _selectedPollId, orElse: () => null);
    if (poll == null) return false;

    bool isEnded = poll['status'] == 'Ended' || poll['status'] == 'Expired';
    bool isPublished = poll['is_published'] == true || poll['is_published'] == 1;

    return isEnded || isPublished;
  }

  // 🛠️ Fetch Question Bank
  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/questions'));
      if (response.statusCode == 200) {
        setState(() {
          _questionBank = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      // Handle silently
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
      // Handle silently
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

  // 🛠️ Manage Question Bank Dialog (Add, Edit, Delete)
  void _showManageQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final TextEditingController newQuestionCtrl = TextEditingController();

            return AlertDialog(
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
                            decoration: const InputDecoration(labelText: "Add a new reusable question", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18)),
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
                                setModalState(() {}); // Refresh modal
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
    ).then((_) => setState(() {})); // Refresh main UI dropdowns when closed
  }

  // 🛠️ Edit Single Question Logic (Prevents Blanks)
  void _showEditSingleQuestionDialog(int qId, String currentText, VoidCallback onSuccess) {
    final TextEditingController editCtrl = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Question"),
          content: TextField(
            controller: editCtrl,
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
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

    List<String> uniqueParties = ['Independent'];
    for (var p in _parties) {
      if (p['name'] != null && p['name'] != 'Independent') {
        uniqueParties.add(p['name']);
      }
    }
    if (!uniqueParties.contains(selectedParty)) selectedParty = 'Independent';

    // Q&A State Variables
    String? q1, q2, q3;
    final a1Ctrl = TextEditingController();
    final a2Ctrl = TextEditingController();
    final a3Ctrl = TextEditingController();
    
    final customQ1Ctrl = TextEditingController();
    final customQ2Ctrl = TextEditingController();
    final customQ3Ctrl = TextEditingController();

    // Map existing QAs.
    if (isEdit && candidate['qas'] != null) {
      List<dynamic> existingQAs = candidate['qas'];
      
      // We check if the existing question matches our DB bank. If not, it falls back to custom.
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                width: 700, 
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFF000B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isEdit ? 'Edit Candidate Details' : 'Register New Candidate', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                    ),
                    
                    // SCROLLABLE BODY
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("1. Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Divider(),
                            const SizedBox(height: 10),

                            Center(
                              child: GestureDetector(
                                onTap: () async {
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
                                Expanded(flex: 3, child: TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()))),
                                const SizedBox(width: 10),
                                Expanded(flex: 2, child: TextField(controller: middleNameCtrl, decoration: const InputDecoration(labelText: 'M.I.', border: OutlineInputBorder()))),
                                const SizedBox(width: 10),
                                Expanded(flex: 3, child: TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()))),
                              ],
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(flex: 2, child: DropdownButtonFormField<String>(value: selectedCourse, isExpanded: true, decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()), items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setStateDialog(() => selectedCourse = val))),
                                const SizedBox(width: 10),
                                Expanded(flex: 1, child: DropdownButtonFormField<String>(value: selectedYear, isExpanded: true, decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()), items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setStateDialog(() => selectedYear = val))),
                              ],
                            ),
                            
                            const SizedBox(height: 30),
                            const Text("2. Election & Platform", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Divider(),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(child: DropdownButtonFormField<String>(value: selectedPosition, decoration: const InputDecoration(labelText: 'Running For', border: OutlineInputBorder()), items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (val) => setStateDialog(() => selectedPosition = val))),
                                const SizedBox(width: 10),
                                Expanded(child: DropdownButtonFormField<String>(value: selectedParty, decoration: const InputDecoration(labelText: 'Party Affiliation', border: OutlineInputBorder()), items: uniqueParties.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setStateDialog(() => selectedParty = val))),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: 'General Platform / Bio', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3),

                            const SizedBox(height: 30),
                            
                            // 🛠️ Q&A HEADER WITH MANAGE BUTTON
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
                                  onPressed: () {
                                    // Open manager, then trigger a re-render of this dialog when it closes
                                    _showManageQuestionsDialog();
                                    // Hack to refresh the dropdowns inside this modal after manager closes
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

                            _buildQASection(1, q1, a1Ctrl, customQ1Ctrl, (val) => setStateDialog(() => q1 = val)),
                            const SizedBox(height: 15),
                            _buildQASection(2, q2, a2Ctrl, customQ2Ctrl, (val) => setStateDialog(() => q2 = val)),
                            const SizedBox(height: 15),
                            _buildQASection(3, q3, a3Ctrl, customQ3Ctrl, (val) => setStateDialog(() => q3 = val)),

                          ],
                        ),
                      ),
                    ),
                    
                    // FOOTER / ACTIONS
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                            onPressed: () async {
                              // Validation
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
                            child: Text(isEdit ? 'Update Candidate' : 'Register Candidate', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // 🛠️ Dropdown dynamically builds from the DB list
  Widget _buildQASection(int index, String? selectedQ, TextEditingController answerCtrl, TextEditingController customCtrl, Function(String?) onChanged) {
    bool isCustom = selectedQ == "Write a one-time custom question...";

    // Generate string list from DB maps
    List<String> dynamicItems = _questionBank.map((q) => q['question_text'] as String).toList();
    
    // Failsafe: If editing a candidate with a legacy/deleted question, inject it so it doesn't crash
    if (selectedQ != null && !isCustom && !dynamicItems.contains(selectedQ)) {
      dynamicItems.insert(0, selectedQ);
    }
    
    // Always append the one-off option
    dynamicItems.add("Write a one-time custom question...");

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: selectedQ,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Question $index', filled: true, fillColor: Colors.white, border: const OutlineInputBorder()),
            items: dynamicItems.map((q) {
              return DropdownMenuItem(
                value: q, 
                child: Text(
                  q, 
                  overflow: TextOverflow.ellipsis, 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: q == "Write a one-time custom question..." ? FontWeight.bold : FontWeight.normal,
                    color: q == "Write a one-time custom question..." ? const Color(0xFF000B6B) : Colors.black87
                  )
                )
              );
            }).toList(),
            onChanged: onChanged,
          ),
          
          if (isCustom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: customCtrl,
              decoration: const InputDecoration(labelText: 'Type your custom question here', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
            ),
          ],
          
          const SizedBox(height: 10),
          TextField(
            controller: answerCtrl,
            decoration: const InputDecoration(labelText: 'Candidate Answer', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
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
    
    // 🛠️ REPLACED: Use the new lock variable
    bool isLocked = _isPollLocked(); 

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedPollId,
                          items: _polls.map<DropdownMenuItem<int>>((poll) => DropdownMenuItem<int>(value: poll['poll_id'], child: Text(poll['title'], style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedPollId = newValue;
                              _fetchPartiesForPoll(newValue!);
                              _fetchCandidates();
                            });
                          },
                        ),
                      ),
                    ),
                  
                  Tooltip(
                    message: isLocked ? "Poll is published or ended. Cannot modify." : "Register a new candidate",
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? Colors.grey : Colors.amber, 
                        foregroundColor: const Color(0xFF000B6B), 
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text("Register New Candidate", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: isLocked ? null : () => _showCandidateDialog(),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Text(
            isLocked 
              ? "This election is published or ended. Registration and editing are permanently locked." 
              : "Register, edit, or remove candidates for the selected poll.", 
            style: TextStyle(
              color: isLocked ? Colors.redAccent : Colors.grey, 
              fontSize: 16, 
              fontWeight: isLocked ? FontWeight.bold : FontWeight.normal
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
                          decoration: BoxDecoration(color: isSelected ? const Color(0xFFD6D6D6) : Colors.grey[200], border: isSelected ? Border.all(color: Colors.grey, width: 2) : null, borderRadius: BorderRadius.circular(4)),
                          child: Center(child: Text('Candidates for $position', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                        ),
                      );
                    },
                  ),
                ),

                // Candidates List Area
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
                              ? const Center(child: Text("No candidates registered for this position yet.", textAlign: TextAlign.center))
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
                                        title: Text(candidate['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        subtitle: Text('${candidate['party_name']} • ${candidate['course_year']}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message: isLocked ? "Poll is published or ended. Cannot modify." : "Edit Candidate", 
                                              child: IconButton(
                                                icon: Icon(Icons.edit, color: isLocked ? Colors.grey : Colors.blue), 
                                                onPressed: isLocked ? null : () => _showCandidateDialog(candidate: candidate)
                                              )
                                            ),
                                            Tooltip(
                                              message: isLocked ? "Poll is published or ended. Cannot modify." : "Delete Candidate", 
                                              child: IconButton(
                                                icon: Icon(Icons.delete, color: isLocked ? Colors.grey : Colors.red), 
                                                onPressed: isLocked ? null : () => _deleteCandidate(candidate['candidate_id'])
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