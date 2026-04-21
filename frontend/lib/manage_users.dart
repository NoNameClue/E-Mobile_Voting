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

  // 🛠️ FIX: Now searches both Name and ID
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

          // Search Bar
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  controller: _firstNameController,
                  hint: "First Name",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSearchField(
                  controller: _lastNameController,
                  hint: "Last Name",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSearchField(
                  controller: _idController,
                  hint: "ID Number",
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

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
                              // subtitle: Padding(
                              //   padding: const EdgeInsets.only(top: 8.0),
                              //   child: Column(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: [
                              //       Text('ID: ${student['student_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                              //       const SizedBox(height: 4),
                              //       Text('Course: ${student['course'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                              //       const SizedBox(height: 4),
                              //       Text('Joined: ${_formatDate(student['created_at'])}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                              //       const SizedBox(height: 4),
                              //       Text(
                              //         isActive ? 'Status: Active' : 'Status: Deactivated (Cannot log in)',
                              //         style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                              //       ),
                              //     ],
                              //   ),
                              // ),
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
    final courseController = TextEditingController(text: student['course'] ?? '');
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
              title: const Text("Edit User"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: courseController,
                      decoration: const InputDecoration(labelText: "Course / Program"),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: obscure1,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        suffixIcon: IconButton(
                          icon: Icon(obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setModalState(() => obscure1 = !obscure1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscure2,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setModalState(() => obscure2 = !obscure2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    if (passwordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return;
                    }

                    try {
                      await http.put(
                        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${student['user_id']}'),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "course": courseController.text,
                          "password": passwordController.text.isNotEmpty
                              ? passwordController.text
                              : null,
                        }),
                      );

                      Navigator.pop(context);
                      _fetchStudents();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Update failed")),
                      );
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 40, // compact
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white, // 👈 ALWAYS white (no fill change)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10)
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => _filterStudents(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
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
          color: isSelected ? Colors.grey.shade200 : Colors.white, // 👈 gray when selected
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent, // 👈 keep colored outline
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
                    overflow: TextOverflow.ellipsis, // 👈 prevents overflow
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