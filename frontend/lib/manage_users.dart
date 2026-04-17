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

  // 🛠️ FIX: Now searches both Name and ID
  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStudents = _allStudents);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student['full_name']?.toString().toLowerCase() ?? '';
        final studentId = student['student_number']?.toString().toLowerCase() ?? '';
        
        // Return true if either the name OR the student ID contains the search query
        return name.contains(lowerQuery) || studentId.contains(lowerQuery);
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
              _buildStatCard("Total Students", total.toString(), Icons.people, Colors.blue),
              _buildStatCard("Active Accounts", active.toString(), Icons.check_circle, Colors.green),
              _buildStatCard("Deactivated", deactivated.toString(), Icons.cancel, Colors.red),
            ],
          ),
          const SizedBox(height: 25),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStudents,
              decoration: const InputDecoration(
                border: InputBorder.none,
                // 🛠️ FIX: Updated placeholder text
                hintText: 'Search by Name or ID...',
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // List of Students
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? const Center(child: Text("No students found.", style: TextStyle(color: Colors.white, fontSize: 18)))
                    : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final isActive = student['is_active'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.6, // Dim the card if deactivated
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              leading: CircleAvatar(
                                radius: 25,
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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${student['student_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.black87)),
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

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}