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
  String _statusFilter = "all"; 
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = []; 
  
  final TextEditingController _searchController = TextEditingController();
  String _searchCriteria = 'None'; 
  
  bool _isLoading = true;

  int _rowsPerPage = 20; 
  int _currentPage = 0;

  List<dynamic> _getPaginatedStudents() {
    int start = _currentPage * _rowsPerPage;
    int end = start + _rowsPerPage;

    if (end > _filteredStudents.length) {
      end = _filteredStudents.length;
    }

    return _filteredStudents.sublist(start, end);
  }

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
    _searchController.dispose();
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
          final indexAll = _allStudents.indexWhere((s) => s['user_id'] == userId);
          if (indexAll != -1) {
            _allStudents[indexAll]['is_active'] = newStatus;
          }
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
    final query = _searchController.text.toLowerCase();

    setState(() {
      _currentPage = 0; 
      _filteredStudents = _allStudents.where((student) {
        final fullName = (student['full_name'] ?? '').toString().toLowerCase();
        final studentId = (student['student_number'] ?? '').toString().toLowerCase();
        final isActive = student['is_active'] == true || student['is_active'] == 1;

        final parts = fullName.split(" ");
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.last : '';

        bool matchesSearch = false;

        if (query.isEmpty) {
          matchesSearch = true;
        } else {
          switch (_searchCriteria) {
            case 'First Name':
              matchesSearch = firstName.contains(query);
              break;
            case 'Last Name':
              matchesSearch = lastName.contains(query);
              break;
            case 'Student ID':
              matchesSearch = studentId.contains(query);
              break;
            case 'None':
            default:
              matchesSearch = fullName.contains(query) || studentId.contains(query);
              break;
          }
        }

        final matchesStatus =
            _statusFilter == "all" ||
            (_statusFilter == "active" && isActive) ||
            (_statusFilter == "deactivated" && !isActive);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = _allStudents.length;
    int active = _allStudents.where((s) => s['is_active'] == true).length;
    int deactivated = total - active;
    bool isMobile = MediaQuery.of(context).size.width < 700;

    final paginatedStudents = _getPaginatedStudents();
    
    int totalFiltered = _filteredStudents.length;
    int currentStart = totalFiltered == 0 ? 0 : (_currentPage * _rowsPerPage) + 1;
    int currentEnd = currentStart + paginatedStudents.length - (totalFiltered == 0 ? 0 : 1);

    return SingleChildScrollView(
      child: Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Users & Account Control", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          const Text("Manage student access and deactivate accounts if necessary.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildStatCard("Total", total.toString(), Icons.people, Colors.blue, "all", isMobile)),
              SizedBox(width: isMobile ? 8 : 20),
              Expanded(child: _buildStatCard("Active", active.toString(), Icons.check_circle, Colors.green, "active", isMobile)),
              SizedBox(width: isMobile ? 8 : 20),
              Expanded(child: _buildStatCard("Deactivated", deactivated.toString(), Icons.cancel, Colors.red, "deactivated", isMobile)),
            ],
          ),
          const SizedBox(height: 25),

          Row(
            children: [
              // 🛠️ CHANGED: Material 3 DropdownMenu replacing the old DropdownButton
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: DropdownMenu<String>(
                  initialSelection: _searchCriteria,
                  requestFocusOnTap: false, // Prevents keyboard/typing
                  onSelected: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _searchCriteria = newValue;
                      });
                      _applyFilters();
                    }
                  },
                  dropdownMenuEntries: ['None', 'First Name', 'Last Name', 'Student ID'].map((String value) {
                    return DropdownMenuEntry<String>(
                      value: value,
                      label: value == 'None' ? 'Global Search' : value,
                    );
                  }).toList(),
                  textStyle: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                  inputDecorationTheme: const InputDecorationTheme(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    border: InputBorder.none, // Removes borders to match the container
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSearchField(
                  controller: _searchController,
                  hint: _searchCriteria == 'None' 
                      ? "Search by Name or ID..." 
                      : "Search by $_searchCriteria...",
                  icon: Icons.search,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredStudents.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No students found.", style: TextStyle(color: Colors.white, fontSize: 15)),
                      ))
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedStudents.length,
                      itemBuilder: (context, index) {
                        final student = paginatedStudents[index];
                        final isActive = student['is_active'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.6, 
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
           
          const SizedBox(height: 15),

          if (!_isLoading && _filteredStudents.isNotEmpty)
            Container(
              width: double.infinity, 
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), 
                    blurRadius: 10,
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween, 
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 15,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Rows per page:", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 10),
                      // 🛠️ CHANGED: RequestFocusOnTap added to Rows Per Page
                      DropdownMenu<int>(
                        initialSelection: _rowsPerPage,
                        requestFocusOnTap: false, 
                        onSelected: (value) {
                          if (value != null) {
                            setState(() { _rowsPerPage = value; _currentPage = 0; });
                          }
                        },
                        dropdownMenuEntries: [10, 20, 50, 100].map((e) => DropdownMenuEntry<int>(value: e, label: "$e")).toList(),
                        textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Showing $currentStart-$currentEnd of $totalFiltered",
                        style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 15),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.black87 : Colors.grey.shade300),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100, 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.chevron_right, color: currentEnd < totalFiltered ? Colors.black87 : Colors.grey.shade300),
                          onPressed: currentEnd < totalFiltered
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ], 
      ),
    ),
    );
  }

  void _showEditUserDialog(dynamic student) {
    String? selectedCourse = student['course'];
    if (selectedCourse != null && !_courses.contains(selectedCourse)) {
      selectedCourse = null; 
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Student Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🛠️ CHANGED: RequestFocusOnTap added to Course
                      DropdownMenu<String>(
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: selectedCourse,
                        requestFocusOnTap: false,
                        label: const Text("Course / Program"),
                        onSelected: (String? newValue) {
                          setModalState(() { selectedCourse = newValue; });
                        },
                        dropdownMenuEntries: _courses.map((String course) {
                          return DropdownMenuEntry<String>(
                            value: course,
                            label: course,
                            style: MenuItemButton.styleFrom(textStyle: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: obscure1,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 45, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), 
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
        onChanged: (_) => _applyFilters(),
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
    bool isMobile
  ) {
    final bool isSelected = _statusFilter == filterType;

    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = filterType;
        });
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent, 
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: isMobile 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis, 
                ),
              ],
            )
          : Row(
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