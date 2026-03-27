import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';

class ManageStaffs extends StatefulWidget {
  const ManageStaffs({super.key});

  @override
  State<ManageStaffs> createState() => _ManageStaffsState();
}

class _ManageStaffsState extends State<ManageStaffs> {
  List<dynamic> _staffList = [];
  bool _isLoading = true;

  final List<String> availablePanels = [
    "Dashboard",
    "Users / Account Control",
    "Manage Polls",
    "Manage Candidates",
    "Manage Parties",
    "Registration for Candidates",
    "Live Scoreboard",
    "Election Result"
  ];

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/officers'));
      if (response.statusCode == 200) {
        setState(() {
          _staffList = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStaff(int userId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Officer"),
        content: const Text("Are you sure you want to remove this staff member? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/officers/$userId'));
      if (response.statusCode == 200) {
        _fetchStaff();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error deleting staff'), backgroundColor: Colors.red));
    }
  }

  void _showStaffModal({Map<String, dynamic>? existingStaff}) {
    final bool isEditing = existingStaff != null;

    final TextEditingController nameCtrl = TextEditingController(text: isEditing ? existingStaff['full_name'] : '');
    final TextEditingController emailCtrl = TextEditingController(text: isEditing ? existingStaff['email'] : '');
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController confirmCtrl = TextEditingController();
    
    bool obscurePassword = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    XFile? selectedImage;
    Uint8List? imageBytes;

    Future<void> pickImage(StateSetter setModalState) async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setModalState(() {
          selectedImage = image;
          imageBytes = bytes;
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEditing ? "Edit Officer" : "Create Staff"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => pickImage(setModalState),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imageBytes != null 
                          ? MemoryImage(imageBytes!) 
                          : (isEditing && existingStaff['profile_pic_url'] != null 
                              ? NetworkImage('${ApiConfig.baseUrl}/${existingStaff['profile_pic_url']}') 
                              : null) as ImageProvider?,
                      child: imageBytes == null && (!isEditing || existingStaff['profile_pic_url'] == null)
                          ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text("Tap to upload photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 15),

                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  
                  if (isEditing) 
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, top: 10),
                      child: Text("Leave passwords blank to keep the current password.", style: TextStyle(fontSize: 12, color: Colors.orange)),
                    ),

                  TextFormField(
                    controller: passCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: isEditing ? "New Password (Optional)" : "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Email are required")));
                    return;
                  }
                  if (!isEditing && passCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password is required for new staff")));
                    return;
                  }
                  if (passCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match!"), backgroundColor: Colors.red));
                    return;
                  }

                  setModalState(() => isSaving = true);
                  
                  try {
                    Uri uri = isEditing 
                        ? Uri.parse('${ApiConfig.baseUrl}/api/officers/${existingStaff['user_id']}')
                        : Uri.parse('${ApiConfig.baseUrl}/api/officers');
                    
                    var request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);
                    
                    request.fields['full_name'] = nameCtrl.text;
                    request.fields['email'] = emailCtrl.text;
                    if (passCtrl.text.isNotEmpty) {
                      request.fields['password'] = passCtrl.text;
                    }

                    if (selectedImage != null && imageBytes != null) {
                      request.files.add(http.MultipartFile.fromBytes('photo', imageBytes!, filename: selectedImage!.name));
                    }

                    var response = await request.send();
                    var responseData = await response.stream.bytesToString();

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.pop(context);
                      _fetchStaff();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEditing ? 'Staff updated successfully' : 'Staff created successfully'), 
                        backgroundColor: Colors.green
                      ));
                    } else {
                      var jsonResponse = jsonDecode(responseData);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['detail']), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server error occurred."), backgroundColor: Colors.red));
                  } finally {
                     setModalState(() => isSaving = false);
                  }
                },
                child: isSaving 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEditing ? "Save Changes" : "Create"),
              )
            ],
          );
        }
      ),
    );
  }

  void _showPermissionsModal(Map<String, dynamic> staff) {
    List<String> currentPermissions = List<String>.from(staff['permissions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text("Permissions for ${staff['full_name']}"),
            content: SizedBox(
              width: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availablePanels.length,
                itemBuilder: (context, index) {
                  String panel = availablePanels[index];
                  return CheckboxListTile(
                    title: Text(panel),
                    value: currentPermissions.contains(panel),
                    activeColor: const Color(0xFF000B6B),
                    onChanged: (bool? checked) {
                      setModalState(() {
                        if (checked == true) {
                          currentPermissions.add(panel);
                        } else {
                          currentPermissions.remove(panel);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  await http.put(
                    Uri.parse('${ApiConfig.baseUrl}/api/officers/${staff['user_id']}/permissions'),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({"permissions": currentPermissions}),
                  );
                  Navigator.pop(context);
                  _fetchStaff(); 
                },
                child: const Text("Save Permissions"),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MOBILE OVERFLOW FIX: Changed Row to Wrap ---
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Election Officers", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: const Color(0xFF000B6B)),
                icon: const Icon(Icons.add),
                label: const Text("Create Staff"),
                onPressed: () => _showStaffModal(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: _staffList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var staff = _staffList[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300], 
                          backgroundImage: staff['profile_pic_url'] != null 
                              ? NetworkImage('${ApiConfig.baseUrl}/${staff['profile_pic_url']}')
                              : null,
                          child: staff['profile_pic_url'] == null 
                              ? const Icon(Icons.security, color: Colors.white, size: 30)
                              : null,
                        ),
                        title: Text(staff['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(staff['email']),
                        
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'permissions') _showPermissionsModal(staff);
                            if (value == 'edit') _showStaffModal(existingStaff: staff);
                            if (value == 'delete') _deleteStaff(staff['user_id']);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'permissions',
                              child: Row(children: [Icon(Icons.key, color: Colors.green, size: 20), SizedBox(width: 10), Text('Manage Access')]),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text('Edit Details')]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text('Delete Staff')]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}