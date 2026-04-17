import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- ADDED: Required for inputFormatters
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'auth_layout.dart'; 
import 'widgets/modern_text_field.dart';
import 'api_config.dart'; 
import 'widgets/realtime_clock.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedCourse;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); 
      setState(() {
        _profileImage = pickedFile;
        _profileImageBytes = bytes;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match!");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; _successMessage = ''; });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/register'));
      
      request.fields['student_number'] = _studentIdController.text.trim();
      request.fields['full_name'] = _nameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['course'] = _selectedCourse!;
      request.fields['password'] = _passwordController.text.trim();

      if (_profileImage != null && _profileImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo', 
          _profileImageBytes!,
          filename: _profileImage!.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = "Registration successful! You can now log in.";
          _nameController.clear(); 
          _emailController.clear(); 
          _studentIdController.clear(); 
          _selectedCourse = null; 
          _passwordController.clear(); 
          _confirmPasswordController.clear();
          
          _profileImage = null; 
          _profileImageBytes = null; 
        });
      } else {
        setState(() => _errorMessage = data['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Cannot connect to server. Is Python running?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Transform.translate(
              offset: const Offset(-10, 0),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
                label: const Text('Back to login', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 5),
            
            const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Register as a student to participate in the upcoming elections.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            
            if (_errorMessage.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            if (_successMessage.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_successMessage, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),

            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                  child: _profileImageBytes == null
                      ? const Icon(Icons.camera_alt, color: Colors.white70, size: 30)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            ModernTextField(
              controller: _nameController,
              hintText: 'Full Name (e.g. John Doe)',
              validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
            ),
            
            ModernTextField(
              controller: _emailController,
              hintText: 'LNU Email',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                // 🛠️ MODIFIED: Strictly require @lnu.edu.ph
                if (!value.trim().toLowerCase().endsWith('@lnu.edu.ph')) {
                  return 'Must end in @lnu.edu.ph';
                }
                return null;
              },
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2, 
                  // 🛠️ MODIFIED: Swapped to TextFormField to use inputFormatters natively
                  child: TextFormField(
                    controller: _studentIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7), // Stops typing at 7 characters
                    ],
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Student ID',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.trim().length != 7) return 'Must be exactly 7 digits';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                
                Expanded(
                  flex: 3, 
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, 
                      menuMaxHeight: 300, 
                      initialValue: _selectedCourse,
                      hint: const Text('Course', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      items: _courses.map((String course) {
                        return DropdownMenuItem<String>(
                          value: course,
                          child: Text(
                            course,
                            style: const TextStyle(color: Colors.black87, fontSize: 11), 
                            overflow: TextOverflow.ellipsis, 
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedCourse = newValue);
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    ),
                  ),
              ],
            ),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (value.length < 12) return 'Min. 12 characters required';
                return null;
              },
            ),
            const SizedBox(height: 15), 
            
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  foregroundColor: const Color(0xFF000B6B),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF000B6B), strokeWidth: 2))
                    : const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            )
          ],
        ),
      ),
    );
  }
}