import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  String _statusFilter = "all"; // All | Active | Deactivated
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = []; 
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = true;

  // 🛠️ ADDED: Exact list of courses copied from signup_page.dart
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

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/students'));
      if (response.statusCode == 200) {
        setState(() {
          _allStudents = jsonDecode(response.body);
          _filteredStudents = _allStudents; 
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load users')));
      }
    }
  }

  Future<void> _toggleStudentStatus(int userId, bool currentStatus) async {
    final bool newStatus = !currentStatus;
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/students/$userId/toggle'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"is_active": newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update in main list
          final indexAll = _allStudents.indexWhere((s) => s['user_id'] == userId);
          if (indexAll != -1) {
            _allStudents[indexAll]['is_active'] = newStatus;
          }
          // Update in filtered list so UI refreshes immediately
          final indexFiltered = _filteredStudents.indexWhere((s) => s['user_id'] == userId);
          if (indexFiltered != -1) {
            _filteredStudents[indexFiltered]['is_active'] = newStatus;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User account ${newStatus ? 'activated' : 'deactivated'}.')),
          );
        }
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "N/A";
    try {
      final d = DateTime.parse(isoDate);
      return "${d.month}/${d.day}/${d.year}";
    } catch (e) {
      return isoDate;
    }
  }

  void _applyFilters() {
    final first = _firstNameController.text.toLowerCase();
    final last = _lastNameController.text.toLowerCase();
    final id = _idController.text.toLowerCase();

    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final fullName = (student['full_name'] ?? '').toString().toLowerCase();
        final studentId = (student['student_number'] ?? '').toString().toLowerCase();
        final isActive = student['is_active'] == true || student['is_active'] == 1;

        final parts = fullName.split(" ");
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.last : '';

        final matchesSearch =
            (first.isEmpty || firstName.contains(first)) &&
            (last.isEmpty || lastName.contains(last)) &&
            (id.isEmpty || studentId.contains(id));

        final matchesStatus =
            _statusFilter == "all" ||
            (_statusFilter == "active" && isActive) ||
            (_statusFilter == "deactivated" && !isActive);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _filterStudents() {
    final first = _firstNameController.text.toLowerCase();
    final last = _lastNameController.text.toLowerCase();
    final id = _idController.text.toLowerCase();

    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final fullName = (student['full_name'] ?? '').toString().toLowerCase();
        final studentId = (student['student_number'] ?? '').toString().toLowerCase();

        final nameParts = fullName.split(" ");

        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.last : '';

        return
          (first.isEmpty || firstName.contains(first)) &&
          (last.isEmpty || lastName.contains(last)) &&
          (id.isEmpty || studentId.contains(id));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = _allStudents.length;
    int active = _allStudents.where((s) => s['is_active'] == true).length;
    int deactivated = total - active;
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text("Users & Account Control", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          const Text("Manage student access and deactivate accounts if necessary.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),

          // Stats Cards
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard("Total Students", total.toString(), Icons.people, Colors.blue, "all"),
              _buildStatCard("Active Accounts", active.toString(), Icons.check_circle, Colors.green, "active"),
              _buildStatCard("Deactivated", deactivated.toString(), Icons.cancel, Colors.red, "deactivated"),
            ],
          ),
          const SizedBox(height: 25),

          // 🛠️ CHANGED: Search Bar with Modern Styling
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  controller: _firstNameController,
                  hint: "Search First Name",
                  icon: Icons.person_search_outlined,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSearchField(
                  controller: _lastNameController,
                  hint: "Search Last Name",
                  icon: Icons.person_search_outlined,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSearchField(
                  controller: _idController,
                  hint: "Search ID Number",
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // List of Students
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? const Center(child: Text("No students found.", style: TextStyle(color: Colors.white, fontSize: 15)))
                    : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final isActive = student['is_active'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.6, // Dim the card if deactivated
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              dense: true,  
                              visualDensity: const VisualDensity(vertical: -3),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isActive ? const Color(0xFF000B6B) : Colors.grey,
                                backgroundImage: student['profile_pic_url'] != null && student['profile_pic_url'].toString().isNotEmpty
                                    ? NetworkImage('${ApiConfig.baseUrl}/${student['profile_pic_url']}')
                                    : null,
                                child: student['profile_pic_url'] == null || student['profile_pic_url'].toString().isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              title: Text(
                                student['full_name'] ?? 'Unknown',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough),
                              ),
                              subtitle: Text(
                                'ID: ${student['student_number']} • ${student['course'] ?? 'N/A'} • ${_formatDate(student['created_at'])}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditUserDialog(student),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: Colors.green,
                                    inactiveThumbColor: Colors.red,
                                    onChanged: (bool newValue) {
                                      _toggleStudentStatus(student['user_id'], isActive);
                                    },
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

  void _showEditUserDialog(dynamic student) {
    // Determine initial dropdown value safely
    String? selectedCourse = student['course'];
    if (selectedCourse != null && !_courses.contains(selectedCourse)) {
      selectedCourse = null; // Prevent crash if DB has an old/custom value not in the array
    }

    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscure1 = true;
    bool obscure2 = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Edit Student Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400, // Make dialog slightly wider for better dropdown fit
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🛠️ CHANGED: Course Dropdown matches signup_page.dart
                      DropdownButtonFormField<String>(
                        value: selectedCourse,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Course / Program",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                        items: _courses.map((String course) {
                          return DropdownMenuItem<String>(
                            value: course,
                            child: Text(
                              course,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setModalState(() {
                            selectedCourse = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: obscure1,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          suffixIcon: IconButton(
                            icon: Icon(obscure1 ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setModalState(() => obscure1 = !obscure1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscure2,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          suffixIcon: IconButton(
                            icon: Icon(obscure2 ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setModalState(() => obscure2 = !obscure2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              actions: [
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (passwordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    try {
                      await http.put(
                        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${student['user_id']}'),
                        headers: {"Content-Type": "application/json"},
                        // Send the properly selected dropdown value
                        body: jsonEncode({
                          "course": selectedCourse ?? student['course'],
                          "password": passwordController.text.isNotEmpty
                              ? passwordController.text
                              : null,
                        }),
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _fetchStudents();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User updated successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Update failed"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🛠️ CHANGED: Modernized Search Field (Pill Shape + Drop Shadow + Icons)
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 45, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => _filterStudents(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
    String filterType,
  ) {
    final bool isSelected = _statusFilter == filterType;

    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = filterType;
        });
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent, 
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, 
                  ),
                  Text(
                    count,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}