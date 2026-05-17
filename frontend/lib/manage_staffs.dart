import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🛠️ Added for input limits
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Officer"),
        content: const Text("Are you sure you want to remove this staff member? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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

    final TextEditingController firstNameCtrl = TextEditingController(text: isEditing ? existingStaff['first_name'] ?? '' : '');
    final TextEditingController middleNameCtrl = TextEditingController(text: isEditing ? existingStaff['middle_name'] ?? '' : '');
    final TextEditingController lastNameCtrl = TextEditingController(text: isEditing ? existingStaff['last_name'] ?? '' : '');
    
    final TextEditingController emailCtrl = TextEditingController(text: isEditing ? existingStaff['email'] : '');
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController confirmCtrl = TextEditingController();
    
    bool obscurePassword = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    // 🛠️ State variables for password strength inside the dialog
    int passwordStrength = 0;
    List<String> missingRequirements = [
      "12+ characters", "uppercase", "lowercase", "number", "special character (.,?!@#\$%)"
    ];

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

          // 🛠️ Function to evaluate strength real-time
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

          // 🛠️ Widget to display the strength bars and missing requirements
          Widget buildPasswordIndicator() {
            if (passCtrl.text.isEmpty) return const SizedBox.shrink();

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
            title: Text(isEditing ? "Edit Officer" : "Create Staff"),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
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
                    const SizedBox(height: 20),

                    // 🛠️ Applied input limiters to Name fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameCtrl, 
                            inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            decoration: InputDecoration(labelText: "First Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: middleNameCtrl, 
                            inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            decoration: InputDecoration(labelText: "M.I. (Opt)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: lastNameCtrl, 
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      decoration: InputDecoration(labelText: "Last Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))
                    ),
                    const SizedBox(height: 10),
                    
                    // 🛠️ Applied input limiter to Email field
                    TextFormField(
                      controller: emailCtrl, 
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))
                    ),
                    const SizedBox(height: 10),
                    
                    if (isEditing) 
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0, top: 10),
                        child: Text("Leave passwords blank to keep the current password.", style: TextStyle(fontSize: 12, color: Colors.orange)),
                      ),

                    TextFormField(
                      controller: passCtrl,
                      obscureText: obscurePassword,
                      onChanged: (val) => evaluatePasswordStrength(val), // 🛠️ Trigger strength evaluation
                      decoration: InputDecoration(
                        labelText: isEditing ? "New Password (Optional)" : "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    
                    buildPasswordIndicator(), // 🛠️ Show indicator below password

                    const SizedBox(height: 5),

                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000B6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSaving ? null : () async {
                  if (firstNameCtrl.text.isEmpty || lastNameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("First Name, Last Name, and Email are required!")));
                    return;
                  }
                  
                  // 🛠️ Validating password rules
                  if (!isEditing && passCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password is required for new staff!")));
                    return;
                  }
                  
                  if (passCtrl.text.isNotEmpty) {
                    if (passwordStrength < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please meet all password requirements"), backgroundColor: Colors.red));
                      return;
                    }
                    if (passCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match!"), backgroundColor: Colors.red));
                      return;
                    }
                  }

                  setModalState(() => isSaving = true);
                  
                  try {
                    Uri uri = isEditing 
                        ? Uri.parse('${ApiConfig.baseUrl}/api/officers/${existingStaff['user_id']}')
                        : Uri.parse('${ApiConfig.baseUrl}/api/officers');
                    
                    var request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);
                    
                    request.fields['first_name'] = firstNameCtrl.text.trim();
                    request.fields['last_name'] = lastNameCtrl.text.trim();
                    request.fields['middle_name'] = middleNameCtrl.text.trim();
                    request.fields['email'] = emailCtrl.text.trim();
                    
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['detail'] ?? "Validation Error"), backgroundColor: Colors.red));
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
    String staffName = staff['full_name'] ?? "${staff['first_name']} ${staff['last_name']}";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Permissions for $staffName"),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 15,
            runSpacing: 15,
            children: [
              const Text("Manage Election Officers", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: const Color(0xFF000B6B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    itemCount: _staffList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var staff = _staffList[index];
                      String displayName = staff['full_name'] ?? "${staff['first_name'] ?? ''} ${staff['last_name'] ?? ''}".trim();
                      if (displayName.isEmpty) displayName = "Unknown Staff";

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
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(staff['email'] ?? 'No email'),
                        
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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