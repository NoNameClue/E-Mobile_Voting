import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';
import 'auth_layout.dart';

class PartyApplicationForm extends StatefulWidget {
  const PartyApplicationForm({super.key});

  @override
  State<PartyApplicationForm> createState() => _PartyApplicationFormState();
}

class _PartyApplicationFormState extends State<PartyApplicationForm> {
  final Color primaryColor = const Color(0xFF000B6B);
  
  bool _isLoading = true;
  int? _availablePollId;
  String _errorMessage = "";

  final TextEditingController _partyNameCtrl = TextEditingController();
  final TextEditingController _partyBioCtrl = TextEditingController();

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
  List<Map<String, dynamic>> _questionBank = [];

  // Holds data for each position. Key is position name.
  Map<String, Map<String, dynamic>> _candidatesData = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
    for (var pos in _positions) {
      _candidatesData[pos] = {
        'included': false,
        'first_name': TextEditingController(),
        'middle_name': TextEditingController(),
        'last_name': TextEditingController(),
        'course': null,
        'year': null,
        'bio': TextEditingController(),
        'q1': null, 'a1': TextEditingController(), 'customQ1': TextEditingController(),
        'q2': null, 'a2': TextEditingController(), 'customQ2': TextEditingController(),
        'q3': null, 'a3': TextEditingController(), 'customQ3': TextEditingController(),
        'photo': null, 'photoBytes': null,
      };
    }
  }

  Future<void> _initializeForm() async {
    try {
      final pollRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/polls'));
      if (pollRes.statusCode == 200) {
        List polls = jsonDecode(pollRes.body);
        final unpublished = polls.where((p) => p['is_published'] == false || p['is_published'] == 0).toList();
        
        if (unpublished.isEmpty) {
          setState(() { _errorMessage = "There are no upcoming elections currently accepting applications."; _isLoading = false; });
          return;
        }
        _availablePollId = unpublished.first['poll_id'];
      }

      final qRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/questions'));
      if (qRes.statusCode == 200) {
        _questionBank = List<Map<String, dynamic>>.from(jsonDecode(qRes.body));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _errorMessage = "Network error connecting to server."; _isLoading = false; });
    }
  }

  Future<void> _submitApplication() async {
    if (_partyNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Party Name is required."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> payload = [];
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/parties/apply'));

      request.fields['poll_id'] = _availablePollId.toString();
      request.fields['party_name'] = _partyNameCtrl.text;
      request.fields['platform_bio'] = _partyBioCtrl.text;

      for (var pos in _positions) {
        var data = _candidatesData[pos]!;
        if (data['included']) {
          List<Map<String, String>> qas = [];
          
          String finalQ1 = data['q1'] == "Write a one-time custom question..." ? data['customQ1'].text.trim() : (data['q1'] ?? "");
          if (finalQ1.isNotEmpty && data['a1'].text.isNotEmpty) qas.add({"question": finalQ1, "answer": data['a1'].text.trim()});
          
          String finalQ2 = data['q2'] == "Write a one-time custom question..." ? data['customQ2'].text.trim() : (data['q2'] ?? "");
          if (finalQ2.isNotEmpty && data['a2'].text.isNotEmpty) qas.add({"question": finalQ2, "answer": data['a2'].text.trim()});
          
          String finalQ3 = data['q3'] == "Write a one-time custom question..." ? data['customQ3'].text.trim() : (data['q3'] ?? "");
          if (finalQ3.isNotEmpty && data['a3'].text.isNotEmpty) qas.add({"question": finalQ3, "answer": data['a3'].text.trim()});

          payload.add({
            'position': pos,
            'first_name': data['first_name'].text,
            'middle_name': data['middle_name'].text,
            'last_name': data['last_name'].text,
            'course_year': "${data['course']} - ${data['year']}",
            'description_platform': data['bio'].text,
            'qas': qas
          });

          if (data['photoBytes'] != null) {
            String safePos = pos.replaceAll(" ", "");
            request.files.add(http.MultipartFile.fromBytes('photos', data['photoBytes'], filename: '${safePos}_image.jpg'));
          }
        }
      }

      request.fields['candidates_json'] = jsonEncode(payload);

      var response = await request.send();
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Submitted Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submission failed. Ensure all included candidates have required fields filled."), backgroundColor: Colors.red));
    }
  }

  // Used for TextFields
  InputDecoration _customInputDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }

  // 🛠️ FIX: Proper Theme specifically for DropdownMenus
  InputDecorationTheme _customDropdownTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }

  Widget _buildQASection(int index, Map<String, dynamic> data) {
    String qKey = 'q$index';
    String aKey = 'a$index';
    String customKey = 'customQ$index';
    
    String? selectedQ = data[qKey];
    bool isCustom = selectedQ == "Write a one-time custom question...";

    List<String> dynamicItems = _questionBank.map((q) => q['question_text'] as String).toList();
    if (selectedQ != null && !isCustom && !dynamicItems.contains(selectedQ)) {
      dynamicItems.insert(0, selectedQ);
    }
    dynamicItems.add("Write a one-time custom question...");

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: selectedQ,
            requestFocusOnTap: false, 
            label: Text('Question $index', style: TextStyle(color: primaryColor)),
            onSelected: (val) => setState(() => data[qKey] = val),
            dropdownMenuEntries: dynamicItems.map((q) {
              return DropdownMenuEntry<String>(
                value: q,
                label: q,
                style: MenuItemButton.styleFrom(
                  foregroundColor: q == "Write a one-time custom question..." ? primaryColor : Colors.black87,
                  textStyle: TextStyle(fontSize: 13, fontWeight: q == "Write a one-time custom question..." ? FontWeight.bold : FontWeight.normal)
                )
              );
            }).toList(),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
          
          if (isCustom) ...[
            const SizedBox(height: 15),
            TextField(
              controller: data[customKey],
              decoration: _customInputDeco('Type your custom question here').copyWith(fillColor: Colors.white),
            ),
          ],
          
          const SizedBox(height: 15),
          TextField(
            controller: data[aKey],
            decoration: _customInputDeco('Candidate Answer').copyWith(fillColor: Colors.white),
            maxLines: 2,
          )
        ],
      ),
    );
  }

  Widget _buildCandidateCard(String position) {
    var data = _candidatesData[position]!;
    bool isIncluded = data['included'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isIncluded ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isIncluded ? primaryColor : Colors.grey.shade300, width: isIncluded ? 2 : 1),
        boxShadow: isIncluded ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))] : [],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          initiallyExpanded: isIncluded,
          iconColor: primaryColor,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Row(
            children: [
              Checkbox(
                value: isIncluded,
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => data['included'] = val!),
              ),
              const SizedBox(width: 10),
              Text(
                position, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isIncluded ? primaryColor : Colors.grey.shade600)
              ),
              const Spacer(),
              if (!isIncluded) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: const Text("ABSTAINED", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                )
            ],
          ),
          children: !isIncluded ? [] : [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 15),
                  const Text("1. Personal Details", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setState(() { data['photo'] = picked; data['photoBytes'] = bytes; });
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: data['photoBytes'] != null ? MemoryImage(data['photoBytes']) : null,
                            child: data['photoBytes'] == null ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 35) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Color(0xFF000B6B), size: 16)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(flex: 3, child: TextField(controller: data['first_name'], decoration: _customInputDeco('First Name'))),
                      const SizedBox(width: 15),
                      Expanded(flex: 2, child: TextField(controller: data['middle_name'], decoration: _customInputDeco('M.I.'))),
                      const SizedBox(width: 15),
                      Expanded(flex: 3, child: TextField(controller: data['last_name'], decoration: _customInputDeco('Last Name'))),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        flex: 2, 
                        child: DropdownMenu<String>(
                          expandedInsets: EdgeInsets.zero,
                          initialSelection: data['course'],
                          requestFocusOnTap: false, 
                          label: const Text('Course'),
                          onSelected: (val) => setState(() => data['course'] = val),
                          dropdownMenuEntries: _courses.map((c) => DropdownMenuEntry(value: c, label: c)).toList(),
                          // 🛠️ FIX: Properly applying the correct Input Decoration Theme
                          inputDecorationTheme: _customDropdownTheme(),
                        )
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1, 
                        child: DropdownMenu<String>(
                          expandedInsets: EdgeInsets.zero,
                          initialSelection: data['year'],
                          requestFocusOnTap: false, 
                          label: const Text('Year'),
                          onSelected: (val) => setState(() => data['year'] = val),
                          dropdownMenuEntries: _years.map((y) => DropdownMenuEntry(value: y, label: y)).toList(),
                          // 🛠️ FIX: Properly applying the correct Input Decoration Theme
                          inputDecorationTheme: _customDropdownTheme(),
                        )
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  const Text("2. Platform & Bio", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),
                  
                  TextField(controller: data['bio'], decoration: _customInputDeco('General Platform / Bio', hint: 'Write about the candidate\'s specific vision...'), maxLines: 3),

                  const SizedBox(height: 35),
                  const Text("3. Candidate Q&A (Optional)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),

                  _buildQASection(1, data),
                  _buildQASection(2, data),
                  _buildQASection(3, data),

                ],
              ),
            )
          ]
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: primaryColor,
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: const Color(0xFFE5E5E5), body: Center(child: CircularProgressIndicator(color: primaryColor)));
    
    if (_errorMessage.isNotEmpty) {
      return AuthLayout(
        formContent: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, color: Colors.amber, size: 80),
            const SizedBox(height: 20),
            Text(_errorMessage, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text("Please check back when an election is announced.", style: TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryColor, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => Navigator.pop(context), 
              child: const Text("Return to Login", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        )
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        title: const Text("File Party Candidacy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: primaryColor, 
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.how_to_reg, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Official Candidacy Form", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Fill out your party details below. Submissions will be reviewed by the electoral committee.", style: TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(30),
                  children: [
                    _buildStepHeader("1", "Party Information"),
                    
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(controller: _partyNameCtrl, decoration: _customInputDeco("Party Name", hint: "e.g. Progressive Youth Party")),
                          const SizedBox(height: 20),
                          TextField(controller: _partyBioCtrl, maxLines: 4, decoration: _customInputDeco("Overall Party Platform (Optional)", hint: "Briefly describe the party's vision and core values...")),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    _buildStepHeader("2", "Candidate Lineup"),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20, left: 10),
                      child: Text("Check the box to include a candidate for that position. Leave unchecked to abstain from running a candidate for that role.", style: TextStyle(color: Colors.grey, height: 1.5)),
                    ),
                    
                    ..._positions.map((pos) => _buildCandidateCard(pos)),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          elevation: 5,
                          shadowColor: Colors.green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _submitApplication,
                        label: const Text("Submit Application for Review", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}