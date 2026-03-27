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
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = []; 
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load students')));
      }
    }
  }

  // --- SEARCH LOGIC ---
  void _runSearch(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allStudents;
    } else {
      results = _allStudents.where((student) {
        final studentId = student['student_number'].toString().toLowerCase();
        return studentId.contains(enteredKeyword.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredStudents = results;
    });
  }

  Future<void> _toggleStudentStatus(int userId, bool currentStatus) async {
    setState(() {
      final mainIndex = _allStudents.indexWhere((s) => s['user_id'] == userId);
      if (mainIndex != -1) _allStudents[mainIndex]['is_active'] = !currentStatus;

      final filteredIndex = _filteredStudents.indexWhere((s) => s['user_id'] == userId);
      if (filteredIndex != -1) _filteredStudents[filteredIndex]['is_active'] = !currentStatus;
    });

    try {
      final response = await http.put(Uri.parse('${ApiConfig.baseUrl}/api/admin/students/$userId/toggle'));
      
      if (response.statusCode != 200) {
        _fetchStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
        }
      }
    } catch (e) {
      _fetchStudents(); 
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown";
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Users / Account Control", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Manage student access. Deactivate accounts for graduated students.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          
          TextField(
            controller: _searchController,
            onChanged: (value) => _runSearch(value),
            decoration: InputDecoration(
              labelText: 'Search by Student ID Number',
              hintText: 'e.g. 1234567',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF000B6B)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredStudents.isEmpty 
                  ? const Center(child: Text('No students found matching that ID.', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      itemCount: _filteredStudents.length, 
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final bool isActive = student['is_active'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              // --- PROFILE PICTURE WITH STATUS BADGE ---
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: student['profile_pic_url'] != null 
                                        ? NetworkImage('${ApiConfig.baseUrl}/${student['profile_pic_url']}')
                                        : null,
                                    child: student['profile_pic_url'] == null 
                                        ? Icon(Icons.person, color: isActive ? Colors.green : Colors.red, size: 30)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.white, // Border for the dot
                                      child: CircleAvatar(
                                        radius: 6,
                                        backgroundColor: isActive ? Colors.green : Colors.red, // The actual status color
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              title: Text(
                                '${student['full_name']} (${student['student_number']})', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${student['email'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text('Course: ${student['course'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text('Joined: ${_formatDate(student['created_at'])}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text(
                                      isActive ? 'Status: Active' : 'Status: Deactivated (Cannot log in)',
                                      style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Switch(
                                value: isActive,
                                activeThumbColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                onChanged: (bool newValue) {
                                  _toggleStudentStatus(student['user_id'], isActive);
                                },
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
}