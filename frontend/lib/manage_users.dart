import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:shimmer/shimmer.dart'; 
import 'dart:math' as math; 
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
  Timer? _debounce; 

  String _sortBy = 'Date Created'; 
  bool _isAscending = false;       
  
  bool _isLoading = true;

  int _rowsPerPage = 20; 
  int _currentPage = 0;

  // 🛠️ ADDED: Accessible tabs available for Student Officers
  final List<String> availablePanels = [
    "Dashboard", 
    "Users / Account Control", 
    "Manage Polls", 
    "Manage Candidates", 
    "Manage Parties", 
    "Live Scoreboard", 
    "Election Result"
  ];

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
    _debounce?.cancel(); 
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/admin/students?limit=100000'));
      if (response.statusCode == 200) {
        final parsedData = await compute(jsonDecode, response.body);
        
        if (!mounted) return; 
        
        setState(() {
          if (parsedData is Map && parsedData.containsKey('items')) {
            _allStudents = parsedData['items'];
          } else {
            _allStudents = parsedData; 
          }
          _applyFilters(); 
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
      final d = DateTime.parse(isoDate).toLocal();
      return "${d.month}/${d.day}/${d.year}";
    } catch (e) {
      return isoDate;
    }
  }

  void _sortData() {
    _filteredStudents.sort((a, b) {
      int cmp = 0;
      if (_sortBy == 'Name') {
        String nameA = (a['full_name'] ?? '').toString().toLowerCase();
        String nameB = (b['full_name'] ?? '').toString().toLowerCase();
        cmp = nameA.compareTo(nameB);
      } else if (_sortBy == 'Student ID') {
        String idA = (a['student_number'] ?? '').toString().toLowerCase();
        String idB = (b['student_number'] ?? '').toString().toLowerCase();
        cmp = idA.compareTo(idB);
      } else if (_sortBy == 'Date Created') {
        DateTime dateA = a['created_at'] != null ? DateTime.tryParse(a['created_at']) ?? DateTime(2000) : DateTime(2000);
        DateTime dateB = b['created_at'] != null ? DateTime.tryParse(b['created_at']) ?? DateTime(2000) : DateTime(2000);
        cmp = dateA.compareTo(dateB);
      }
      return _isAscending ? cmp : -cmp;
    });
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
      
      _sortData();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  Widget _buildSearchCriteriaDropdown() {
    return Container(
      height: 45,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: DropdownMenu<String>(
        initialSelection: _searchCriteria,
        requestFocusOnTap: false,
        onSelected: (String? newValue) {
          if (newValue != null) {
            setState(() => _searchCriteria = newValue);
            _applyFilters();
          }
        },
        dropdownMenuEntries: ['None', 'First Name', 'Last Name', 'Student ID'].map((String value) {
          return DropdownMenuEntry<String>(value: value, label: value == 'None' ? 'Global Search' : value);
        }).toList(),
        textStyle: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        inputDecorationTheme: const InputDecorationTheme(contentPadding: EdgeInsets.symmetric(horizontal: 15), border: InputBorder.none),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: DropdownMenu<String>(
            initialSelection: _sortBy,
            requestFocusOnTap: false,
            onSelected: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  if (_sortBy == newValue) {
                    _isAscending = !_isAscending; 
                  } else {
                    _sortBy = newValue;
                    _isAscending = newValue == 'Date Created' ? false : true; 
                  }
                });
                _applyFilters();
              }
            },
            dropdownMenuEntries: ['Date Created', 'Name', 'Student ID'].map((String value) {
              return DropdownMenuEntry<String>(value: value, label: value);
            }).toList(),
            textStyle: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            inputDecorationTheme: const InputDecorationTheme(contentPadding: EdgeInsets.symmetric(horizontal: 15), border: InputBorder.none),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 45, width: 45,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
          child: IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF000B6B), size: 20),
            onPressed: () {
              setState(() => _isAscending = !_isAscending);
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rowsPerPage > 8 ? 8 : _rowsPerPage,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              leading: const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              title: Container(height: 14, width: double.infinity, color: Colors.white),
              subtitle: Container(height: 10, width: 150, color: Colors.white),
              trailing: Container(height: 20, width: 40, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = _allStudents.length;
    int active = _allStudents.where((s) => s['is_active'] == true).length;
    int deactivated = total - active;
    bool isMobile = MediaQuery.of(context).size.width < 900;

    final paginatedStudents = _getPaginatedStudents();
    
    int totalFiltered = _filteredStudents.length;
    int currentStart = totalFiltered == 0 ? 0 : (_currentPage * _rowsPerPage) + 1;
    int currentEnd = currentStart + paginatedStudents.length - (totalFiltered == 0 ? 0 : 1);

    int totalPages = (totalFiltered / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    List<Widget> pageButtons = [];
    
    Widget buildPageButton(int pageIndex, bool isActive) {
      return InkWell(
        onTap: () => setState(() => _currentPage = pageIndex),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 35,
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? Colors.blue : Colors.grey.shade300),
          ),
          child: Text(
            "${pageIndex + 1}",
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    Widget buildEllipsis() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 35,
        height: 35,
        alignment: Alignment.center,
        child: const Text("...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      );
    }

    if (totalPages <= 5) {
      for (int i = 0; i < totalPages; i++) {
        pageButtons.add(buildPageButton(i, i == _currentPage));
      }
    } else {
      if (_currentPage < 3) {
        for (int i = 0; i < 4; i++) {
          pageButtons.add(buildPageButton(i, i == _currentPage));
        }
        pageButtons.add(buildEllipsis());
        pageButtons.add(buildPageButton(totalPages - 1, false));
      } else if (_currentPage > totalPages - 4) {
        pageButtons.add(buildPageButton(0, false));
        pageButtons.add(buildEllipsis());
        for (int i = totalPages - 4; i < totalPages; i++) {
          pageButtons.add(buildPageButton(i, i == _currentPage));
        }
      } else {
        pageButtons.add(buildPageButton(0, false));
        pageButtons.add(buildEllipsis());
        pageButtons.add(buildPageButton(_currentPage - 1, false));
        pageButtons.add(buildPageButton(_currentPage, true));
        pageButtons.add(buildPageButton(_currentPage + 1, false));
        pageButtons.add(buildEllipsis());
        pageButtons.add(buildPageButton(totalPages - 1, false));
      }
    }

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

          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSearchCriteriaDropdown(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 45, 
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged, 
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            hintText: _searchCriteria == 'None' ? "Search..." : "Search by $_searchCriteria...",
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ),
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Sort By: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    _buildSortDropdown(),
                  ],
                )
              ],
            )
          else
            Row(
              children: [
                _buildSearchCriteriaDropdown(),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 45, 
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged, 
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        hintText: _searchCriteria == 'None' ? "Search by Name or ID..." : "Search by $_searchCriteria...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ),
                  )
                ),
                const SizedBox(width: 30),
                const Text("Sort By: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                _buildSortDropdown(),
              ],
            ),
            
          const SizedBox(height: 20),

          _isLoading
              ? _buildSkeletonLoader()
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
                              child: student['profile_pic_url'] != null && student['profile_pic_url'].toString().isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: '${ApiConfig.baseUrl}/${student['profile_pic_url']}',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 150, 
                                        memCacheHeight: 150,
                                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              student['full_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15, 
                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (student['is_student_officer'] == 1 || student['is_student_officer'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "Student Officer", 
                                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)
                                    ),
                                  ),
                                Text(
                                  'ID: ${student['student_number']} • ${student['course'] ?? 'N/A'} • Since: ${_formatDate(student['created_at'])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Showing $currentStart-$currentEnd of $totalFiltered",
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 15),
                      
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.keyboard_double_arrow_left, color: _currentPage > 0 ? Colors.black87 : Colors.grey.shade300),
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
                      ),
                      
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.black87 : Colors.grey.shade300),
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      ),
                      
                      const SizedBox(width: 4),
                      ...pageButtons,
                      const SizedBox(width: 4),
                      
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.chevron_right, color: _currentPage < totalPages - 1 ? Colors.black87 : Colors.grey.shade300),
                        onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      ),
                      
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(Icons.keyboard_double_arrow_right, color: _currentPage < totalPages - 1 ? Colors.black87 : Colors.grey.shade300),
                        onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage = totalPages - 1) : null,
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

    int passwordStrength = 0;
    List<String> missingRequirements = [
      "12+ characters", "uppercase", "lowercase", "number", "special character (.,?!@#\$%)"
    ];

    // 🛠️ ADDED: Initialize Student Officer toggles and permissions list
    bool isStudentOfficer = student['is_student_officer'] == 1 || student['is_student_officer'] == true;
    List<String> selectedPermissions = [];
    if (student['permissions'] != null) {
      var perms = student['permissions'];
      if (perms is String) {
        selectedPermissions = List<String>.from(jsonDecode(perms));
      } else if (perms is List) {
        selectedPermissions = List<String>.from(perms);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            void evaluatePasswordStrength(String password) {
              List<String> missing = [];
              int metConditions = 0;

              if (password.length >= 12) metConditions++; else missing.add("12+ characters");
              if (RegExp(r'[A-Z]').hasMatch(password)) metConditions++; else missing.add("uppercase letter");
              if (RegExp(r'[a-z]').hasMatch(password)) metConditions++; else missing.add("lowercase letter");
              if (RegExp(r'[0-9]').hasMatch(password)) metConditions++; else missing.add("number");
              if (RegExp(r'[.,?!@#\$%]').hasMatch(password)) metConditions++; else missing.add("special character (.,?!@#\$%)");

              int strength = 0;
              if (password.isEmpty) strength = 0;
              else if (metConditions <= 2) strength = 1;
              else if (metConditions <= 4) strength = 2;
              else if (metConditions == 5) strength = 3;

              setModalState(() {
                passwordStrength = strength;
                missingRequirements = missing;
              });
            }

            Widget buildPasswordIndicator() {
              if (passwordController.text.isEmpty) return const SizedBox.shrink();

              Color strengthColor = Colors.grey;
              String strengthLabel = "";

              if (passwordStrength == 1) { strengthColor = Colors.redAccent; strengthLabel = "Weak"; }
              else if (passwordStrength == 2) { strengthColor = Colors.orangeAccent; strengthLabel = "Fair"; }
              else if (passwordStrength == 3) { strengthColor = Colors.greenAccent; strengthLabel = "Strong"; }

              return Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: passwordStrength >= 1 ? strengthColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(width: 5),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: passwordStrength >= 2 ? strengthColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(width: 5),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: passwordStrength >= 3 ? strengthColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(width: 10),
                        Text(strengthLabel, style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    if (missingRequirements.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text("Missing: ${missingRequirements.join(', ')}", style: TextStyle(color: Colors.orange.shade800, fontSize: 11, height: 1.3)),
                      ),
                  ],
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Student Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        onChanged: (val) => evaluatePasswordStrength(val), 
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
                      
                      buildPasswordIndicator(), 

                      const SizedBox(height: 5),

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

                      // 🛠️ ADDED: Student Officer Toggle Switch and Permissions List
                      const SizedBox(height: 20),
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Enable Student Officer Role", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000B6B))),
                        subtitle: const Text("Grants this student access to the Staff Panel."),
                        activeColor: Colors.amber,
                        value: isStudentOfficer,
                        onChanged: (bool value) {
                          setModalState(() {
                            isStudentOfficer = value;
                            if (!isStudentOfficer) selectedPermissions.clear(); 
                          });
                        },
                      ),
                      if (isStudentOfficer)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Select Accessible Tabs:", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ...availablePanels.map((panel) {
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(panel, style: const TextStyle(fontSize: 14)),
                                  value: selectedPermissions.contains(panel),
                                  activeColor: const Color(0xFF000B6B),
                                  onChanged: (bool? checked) {
                                    setModalState(() {
                                      if (checked == true) {
                                        selectedPermissions.add(panel);
                                      } else {
                                        selectedPermissions.remove(panel);
                                      }
                                    });
                                  },
                                );
                              }),
                            ],
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
                    if (passwordController.text.isNotEmpty) {
                      if (passwordStrength < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please meet all password requirements"), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (passwordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
                        );
                        return;
                      }
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
                          "is_student_officer": isStudentOfficer,
                          "permissions": selectedPermissions
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